import 'package:validicityserver/model/sample.dart';
import 'package:validicityserver/model/log.dart';

import '../validicityserver.dart';

class ProjectSampleController extends ResourceController {
  ProjectSampleController(ManagedContext context) {
    query = Query<Sample>(context);
  }
  Query<Sample> query;

  /// Assign Sample to a given Project
  @Operation.post('projectid', 'id')
  Future<Response> addSample(
      @Bind.path('projectid') int projectid, @Bind.path('id') int id) async {
    query
      ..where((u) => u.id).equalTo(id)
      ..values.project.id = projectid;
    var sample = await query.updateOne();
    // We could do this async (without await) but then testing fails...
    await LogEntry.create(sample, query.context,
        message: "Added Sample $id to Project $projectid");
    return Response.ok(sample);
  }

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

  /// Remove assigned sample from Project
  @Operation.delete('projectid', 'id')
  Future<Response> removeSample(
      @Bind.path('projectid') int projectid, @Bind.path('id') int id) async {
    query
      ..where((u) => u.id).equalTo(id)
      ..values.project.id = null;
    var sample = await query.updateOne();
    // We could do this async (without await) but then testing fails...
    await LogEntry.create(sample, query.context,
        message: "Removed sample $id from Project $projectid");
    return Response.ok(sample);
  }
}
