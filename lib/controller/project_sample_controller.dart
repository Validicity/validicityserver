import 'package:validicityserver/model/sample.dart';

import '../validicityserver.dart';

class ProjectSampleController extends ResourceController {
  ProjectSampleController(ManagedContext context) {
    query = Query<Sample>(context);
  }
  Query<Sample> query;

  /// Get all Samples for a Project
  @Operation.get('projectid')
  Future<Response> getAllSamples(@Bind.path('projectid') int projectid) async {
    query.where((u) => u.project.id).equalTo(projectid);
    var samples = await query.fetch();
    if (samples == null) {
      return Response.notFound();
    }
    return Response.ok(samples);
  }
}
