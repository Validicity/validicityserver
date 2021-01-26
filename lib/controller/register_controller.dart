import 'dart:async';

import 'package:aqueduct/aqueduct.dart';
import 'package:validicityserver/model/organisation.dart';
import 'package:validicityserver/model/project.dart';
import 'package:validicityserver/model/user.dart';

class RegisterController extends ResourceController {
  RegisterController(this.context, this.authServer);

  final ManagedContext context;
  final AuthServer authServer;

  @Operation.post()
  Future<Response> createUser(@Bind.body() User user) async {
    // Check for required parameters before we spend time hashing
    if (user.username == null || user.password == null) {
      return Response.badRequest(
          body: {"error": "username and password required."});
    }

    user
      ..salt = AuthUtility.generateRandomSalt()
      ..hashedPassword = authServer.hashPassword(user.password, user.salt)
      ..organisation = Organisation()
      ..id = 5;
    var result = await Query<User>(context, values: user).insert();

    // if project with id "5" exist, we add the user to it
    var query = Query<Project>(context)..where((x) => x.id).equalTo(5);
    var project = await query.fetchOne();
    if (project != null) {
      var userProjectQuery = Query<UserProject>(context)
        ..values.user = result
        ..values.project = project;

      await userProjectQuery.insert();
    }

    return Response.ok(result);
  }
}
