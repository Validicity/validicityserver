import 'package:validicityserver/model/project.dart';
import 'package:validicityserver/model/log.dart';
import 'package:validicityserver/model/user.dart';

import '../validicityserver.dart';

/// Controller to manage access to Projects for Users.
/// UserProject is the join class/table for the many-to-many relationship
/// between Projects and Users.
class UserProjectController extends ResourceController {
  UserProjectController(ManagedContext context) {
    query = Query<UserProject>(context);
  }

  Query<UserProject> query;

  /// Add access to a Project for a given User
  @Operation.post('userid', 'id')
  Future<Response> addAccess(
      @Bind.path('userid') int userid, @Bind.path('id') int id) async {
    var userQuery = Query<User>(query.context)
      ..where((user) => user.id).equalTo(userid);
    var user = await userQuery.fetchOne();
    var instQuery = Query<Project>(query.context)
      ..where((project) => project.id).equalTo(id);
    var proj = await instQuery.fetchOne();
    query
      ..values.user = user
      ..values.project = proj;
    var result = await query.insert();
    if (result != null) {
      // We could do this async (without await) but then testing fails...
      await LogEntry.create(user,
          message: "Added access to Project ${proj.id}");
    }
    return Response.ok(result);
  }

  /// Get all Projects for a given user, including the Organisation since they are so few
  @Operation.get('userid')
  Future<Response> getAllProjects(@Bind.path('userid') int userid) async {
    // Find User by id
    var userQuery = Query<User>(query.context);
    userQuery.where((user) => user.id).equalTo(userid);
    // Join with all Projects user has access to
    var upQuery = userQuery.join(set: (user) => user.userProjects);
    var projQuery = upQuery.join(object: (ui) => ui.project);
    // For all Projects, also join in Organisations
    projQuery.join(object: (im) => im.organisation);
    // Fetch only one User
    var user = await userQuery.fetchOne();
    if (user == null) {
      return Response.notFound();
    }
    // Flatten out Projects and only return those
    var projects = user.userProjects.map((ui) => ui.project).toList();
    return Response.ok(projects);
  }

  /// Get all Users for a given Project
  @Operation.get('projectid')
  Future<Response> getAllUsers(@Bind.path('projectid') int projectid) async {
    // Find Project by id
    var projQuery = Query<Project>(query.context);
    projQuery.where((inst) => inst.id).equalTo(projectid);
    // Join with all Users with access
    var upQuery = projQuery.join(set: (im) => im.userProjects);
    upQuery.join(object: (ui) => ui.user);
    // Fetch all
    var project = await projQuery.fetchOne();
    if (project == null) {
      return Response.notFound();
    }
    // Flatten out Projects and only return those
    var users = project.userProjects.map((ui) => ui.user).toList();
    return Response.ok(users);
  }

  /// Remove access to Project for User
  @Operation.delete('userid', 'id')
  Future<Response> removeAccess(
      @Bind.path('userid') int userid, @Bind.path('id') int id) async {
    var userQuery = Query<User>(query.context)
      ..where((user) => user.id).equalTo(userid);
    var user = await userQuery.fetchOne();
    var projQuery = Query<Project>(query.context)
      ..where((proj) => proj.id).equalTo(id);
    var project = await projQuery.fetchOne();
    query
      ..where((up) => up.user.id).equalTo(userid)
      ..where((up) => up.project.id).equalTo(id);
    int deleted = await query.delete();
    if (deleted == 0) {
      // TODO: Log errors?
      return Response.notFound();
    } else {
      LogEntry.create(user, message: "Removed access to Project $project");
      return Response.ok(null);
    }
  }
}
