import '../validicityserver.dart';
import '../model/project.dart';

/// A fully managed Controller for Projects, offers full CRUD.
class ProjectController extends ManagedObjectController<Project> {
  ProjectController(this.context) : super(context);

  ManagedContext context;

  /// NOT NEEDED Get all Users for a given Project
  /*@Operation.get('id', 'action')
  Future<Response> getAllUsers(@Bind.path('id') int impid, @Bind.path('action') String action) async {
    if (action == 'users') {
      // Find Project by id
      var instQuery = Query<Project>(context);
      instQuery.where((imp) => imp.id).equalTo(impid);
      // Join with all Users with access
      var uiQuery = instQuery.join(set: (user) => user.userProjects);
      var userQuery = uiQuery.join(object: (ui) => ui.user);
      // Fetch all
      var users = await userQuery.fetch();
      if (users == null) {
        return Response.notFound();
      }
      // Flatten out Projects and only return those
      // var projects = user.userProjects.map((ui) => ui.project).toList();
      return Response.ok(users);
    } else {
      return Response.notFound();
    }
  }*/
}
