import 'package:validicitylib/util.dart';
import 'package:validicityserver/model/user.dart';

import '../validicityserver.dart';

class UserController extends ResourceController {
  UserController(ManagedContext context, this.authServer) {
    query = Query<User>(context);
  }

  final AuthServer authServer;
  Query<User> query;

  @Operation.post()
  Future<Response> createUser(@Bind.body() User user) async {
    // Check for required parameters before we spend time hashing
    if (user.username == null ||
        user.type == null ||
        user.password == null ||
        user.email == null) {
      return Response.badRequest(
          body: {"error": "username, type, password and email required."});
    }
    if (user.type == UserType.admin) {
      return Response.badRequest(
          body: {"error": "Can not create more than one admin user."});
    }
    user
      ..salt = AuthUtility.generateRandomSalt()
      ..hashedPassword = authServer.hashPassword(user.password, user.salt);
    query.values = user;
    return Response.ok(await query.insert());
  }

  /// Get all Users
  @Operation.get()
  Future<Response> getAllUsers() async {
    var found = await query.fetch();
    if (found == null) {
      return Response.notFound(body: 'No Users found');
    }
    return Response.ok(found);
  }

  /// Get User by username
  @Operation.get('username')
  Future<Response> getUser(@Bind.path('username') String username) async {
    query.where((u) => u.username).equalTo(username);
    var found = await query.fetchOne();
    if (found == null) {
      return Response.notFound(body: 'No User found with username $username');
    }
    return Response.ok(found);
  }

  /// Update User by username
  @Operation.put('username')
  Future<Response> updateUser(
      @Bind.path('username') String username, @Bind.body() User user) async {
    // Check for required parameters before we spend time hashing
    if (user.username == null || user.password == null || user.email == null) {
      return Response.badRequest(
          body: {"error": "username, password and email required."});
    }
    user
      ..salt = AuthUtility.generateRandomSalt()
      ..hashedPassword = authServer.hashPassword(user.password, user.salt);
    query
      ..where((u) => u.username).equalTo(username)
      ..values = user;
    var result = await query.updateOne();
    return new Response.ok(result);
  }

  /// Delete User by username
  @Operation.delete('username')
  Future<Response> deleteUser(@Bind.path('username') String username) async {
    query.where((u) => u.username).equalTo(username);
    int deleted = await query.delete();
    if (deleted == 0) {
      return Response.notFound();
    }
    return Response.ok(null);
  }
}
