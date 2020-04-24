import 'package:validicityserver/model/user.dart';

import '../validicityserver.dart';

class RecoveryController extends ResourceController {
  RecoveryController(ManagedContext context, this.authServer) {
    query = Query<User>(context);
  }

  final AuthServer authServer;
  Query<User> query;

  /// Get a recovery code for password reset
  @Operation.get('username')
  Future<Response> getRecoveryCode(
      @Bind.path('username') String username) async {
    var user = await User.findByUsername(query.context, username);
    var sentCode = await user.sendRecoveryCode(query.context);
    if (!sentCode) {
      return Response.serverError(
          body: 'Failed sending recovery code for username $username');
    }
    return Response.ok(true);
  }

  /// Use a recovery code to reset password
  @Operation.put('username', 'code', 'password')
  Future<Response> resetPassword(
      @Bind.path('username') String username,
      @Bind.path('code') int code,
      @Bind.path('password') String newPassword) async {
    print("User: $username, code: $code, password: $newPassword");
    // Verify that this user had this code sent out
    query
      ..where((user) => user.username).equalTo(username)
      ..returningProperties((u) => [u.lastCode, u.username]);
    var user = await query.fetchOne();
    if (user == null) {
      return Response.notFound();
    }
    if (user.lastCode == null) {
      return Response.badRequest(
          body:
              'Recovery code for User ${user.username} has not been requested');
    }
    if (user.lastCode != code) {
      return Response.badRequest(
          body: 'Recovery code for User ${user.username} was wrong');
    }
    if (!user.passwordGoodEnough(newPassword)) {
      return Response.badRequest(
          body:
              'New password requested by User ${user.username} does not meet rules for passwords');
    }
    query = Query<User>(query.context);
    query.where((u) => u.username).equalTo(username);
    var salt = AuthUtility.generateRandomSalt();
    query.values
      ..lastCode = null
      ..salt = salt
      ..hashedPassword = authServer.hashPassword(newPassword, salt);
    var result = await query.updateOne();
    if (result != null) {
      return Response.ok(true);
    } else {
      return Response.serverError(body: {
        "error": "failure",
        "detail": "Failed to reset password for unknown reason"
      });
    }
  }
}
