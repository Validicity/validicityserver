import 'package:validicitylib/util.dart';
import 'package:validicityserver/model/user.dart';

import '../validicityserver.dart';

/// This controller is accessible for doing a one shot bootstrap creating an admin account etc.
class BootstrapController extends ResourceController {
  BootstrapController(this.context, this.authServer);
  final ManagedContext context;
  final AuthServer authServer;

  @Operation.post()
  Future<Response> bootstrap(@Bind.body() User user) async {
    // Check for required parameters before we spend time hashing
    if (user.password == null || user.email == null) {
      return Response.badRequest(
          body: {"error": "password and email required."});
    }
    // Ensure we do not already have an admin account, this can only be done once
    var q = Query<User>(context);
    q.where((u) => u.username).equalTo("admin");
    var found = await q.fetchOne();
    if (found != null) {
      return Response.badRequest(body: {
        "error": "admin user already exists, bootstrap can only be done once."
      });
    }
    // Make an admin user
    final salt = AuthUtility.generateRandomSalt();
    final hashedPassword = authServer.hashPassword(user.password, salt);
    user
      ..username = 'admin'
      ..type = UserType.admin
      ..hashedPassword = hashedPassword
      ..salt = salt;
    return Response.ok(await Query.insertObject(context, user));

    // More bootstrapping?
  }
}
