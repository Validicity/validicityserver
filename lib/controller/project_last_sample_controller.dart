import 'package:validicityserver/model/sample.dart';

import '../validicityserver.dart';

class ProjectLastSampleController extends ResourceController {
  ProjectLastSampleController(ManagedContext context) {
    query = Query<Sample>(context);
  }

  Query<Sample> query;

  /// Get all last Samples for a Project
  @Operation.get('projectid')
  Future<Response> getAllLastSamples(
      @Bind.path('projectid') int projectid) async {
    query
      ..where((u) => u.project.id).equalTo(projectid)
      ..where((u) => u.next).isNull();
    var samples = await query.fetch();
    if (samples == null) {
      return Response.notFound();
    }
    return Response.ok(samples);
  }
}
