import 'package:validicityserver/model/project.dart';

import '../validicityserver.dart';

class OrganisationProjectController extends ResourceController {
  OrganisationProjectController(ManagedContext context) {
    query = Query<Project>(context);
  }
  Query<Project> query;

  /// Get all Projects for a Organisation
  @Operation.get('organisationid')
  Future<Response> getAllProjects(
      @Bind.path('organisationid') int organisationid) async {
    // Find Projects for Organisation
    query.where((project) => project.owner.id).equalTo(organisationid);
    var projects = await query.fetch();
    if (projects == null) {
      return Response.notFound();
    }
    return Response.ok(projects);
  }
}
