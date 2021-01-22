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

  /// Update my own User by username. Can change name, email and/or password.
  @Operation.put()
  Future<Response> updateUser(@Bind.body() User user) async {
    var requester = await User.currentUser(request);
    if (user.username != requester.username) {
      return Response.badRequest(
          body:
              'User ${user.username} not allowed to get User information for username ${requester.username}');
    }

    // requester
    //   ..avatar = user.avatar
    //   ..name = user.name;

    query
      ..where((u) => u.username).equalTo(user.username)
      ..values.name = user.name
      ..values.avatar = user.avatar;
    var result = await query.updateOne();
    return Response.ok(result);
  }
}
