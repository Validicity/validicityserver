import 'package:validicityserver/model/user.dart';

import '../validicityserver.dart';

class UserSelfController extends ResourceController {
  UserSelfController(ManagedContext context, this.authServer) {
    query = Query<User>(context);
  }

  final AuthServer authServer;
  Query<User> query;

  /// Get my own User and all Projects I have access to
  @Operation.get()
  Future<Response> getUser() async {
    // Verify that this user is himself
    var user = await User.currentUser(request);
    query.where((u) => u.id).equalTo(user.id);
    // Join with all Projects user has access to and manages as super user
    var upQuery = query.join(set: (user) => user.userProjects);
    upQuery.join(object: (up) => up.project);
    var found = await query.fetchOne();
    if (found == null) {
      return Response.notFound(body: 'No User found');
    }
    return Response.ok(found);
  }

  /// Update my own User. Can change name, email and/or password.
  @Operation.put()
  Future<Response> updateUser(
      @Bind.query('name') String newName,
      @Bind.query('email') String newEmail,
      @Bind.query('password') String newPassword) async {
    var user = await User.currentUser(request);
    if (newPassword != null) {
      user
        ..salt = AuthUtility.generateRandomSalt()
        ..hashedPassword = authServer.hashPassword(user.password, user.salt);
    }
    if (newEmail != null) {
      user.email = newEmail; // TODO: This should be verified...
    }
    if (newName != null) {
      user.name = newName;
    }
    query
      ..where((u) => u.id).equalTo(user.id)
      ..values = user;
    var result = await query.updateOne();
    return new Response.ok(result);
  }
}
