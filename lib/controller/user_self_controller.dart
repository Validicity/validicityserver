import 'package:validicityserver/model/user.dart';

import '../validicityserver.dart';

class UserSelfController extends ResourceController {
  UserSelfController(ManagedContext context, this.authServer) {
    query = Query<User>(context);
  }

  final AuthServer authServer;
  Query<User> query;

  /// Get my own User by username
  @Operation.get('username')
  Future<Response> getUser(@Bind.path('username') String username) async {
    // Verify that this user is himself
    var user = await User.currentUser(query.context, request);
    if (user.username != username) {
      return Response.badRequest(
          body:
              'User ${user.username} not allowed to get User information for username $username');
    }
    query.where((u) => u.id).equalTo(user.id);
    // Join with all Projects user has access to and manages as super user
    var upQuery = query.join(set: (user) => user.userProjects);
    upQuery.join(object: (up) => up.project);
    var found = await query.fetchOne();
    if (found == null) {
      return Response.notFound(body: 'No User found with username $username');
    }
    return Response.ok(found);
  }

  /// Update my own User by username. Can change name, email and/or password.
  @Operation.put('username')
  Future<Response> updateUser(
      @Bind.path('username') String username,
      @Bind.query('name') String newName,
      @Bind.query('email') String newEmail,
      @Bind.query('password') String newPassword) async {
    var user = await User.currentUser(query.context, request);
    if (user.username != username) {
      return Response.badRequest(
          body:
              'User ${user.username} not allowed to get User information for username $username');
    }
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
      ..where((u) => u.username).equalTo(username)
      ..values = user;
    var result = await query.updateOne();
    return new Response.ok(result);
  }
}
