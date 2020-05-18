import 'package:validicityserver/model/sample.dart';

import '../validicityserver.dart';

class SampleFindController extends ResourceController {
  SampleFindController(ManagedContext context) {
    query = Query<Sample>(context);
  }
  Query<Sample> query;

  /// Find a Sample by serial and get last record
  @Operation.get('serial')
  Future<Response> findSample(@Bind.path('serial') String serial) async {
    //var instQuery = query.join(object: (u) => u.project);
    //instQuery.where((project) => project.id).equalTo(id);
    query
      ..where((u) => u.serial).equalTo(serial)
      ..where((u) => u.next).isNull();
    var sample = await query.fetchOne();
    if (sample == null) {
      return Response.notFound();
    }
    return Response.ok(sample);
  }
}
