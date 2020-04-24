import 'package:validicityserver/model/sample.dart';

import '../validicityserver.dart';

class SampleFindController extends ResourceController {
  SampleFindController(ManagedContext context) {
    query = Query<Sample>(context);
  }
  Query<Sample> query;

  /// Find a Sample by serial
  @Operation.get('serial', 'projectid')
  Future<Response> findSample(@Bind.path('serial') String serial,
      @Bind.path('projectid') int id) async {
    var instQuery = query.join(object: (u) => u.project);
    instQuery.where((project) => project.id).equalTo(id);
    query.where((u) => u.serial).equalTo(serial);
    var sample = await query.fetchOne();
    if (sample == null) {
      return Response.notFound();
    }
    return Response.ok(sample);
  }
}
