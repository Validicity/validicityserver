import 'package:validicitylib/util.dart';
import 'package:validicityserver/model/user.dart';

import '../validicityserver.dart';
import '../model/sample.dart';

class SampleController extends ResourceController {
  SampleController(this.context) {
    query = Query<Sample>(context);
  }

  ManagedContext context;
  Query<Sample> query;

  /// Get all Samples in order of creation
  @Operation.get()
  Future<Response> getAllSamples() async {
    query.sortBy((s) => s.created, QuerySortOrder.ascending);
    var found = await query.fetch();
    if (found == null) {
      return Response.notFound();
    }
    return Response.ok(found);
  }

  /// Get Sample chain by serial, in order of creation
  @Operation.get('serial')
  Future<Response> getSample(@Bind.path('serial') String serial) async {
    query
      ..where((sample) => sample.serial).equalTo(serial)
      ..sortBy((s) => s.created, QuerySortOrder.ascending);
    var found = await query.fetchOne();
    if (found == null) {
      return Response.notFound();
    }
    return Response.ok(found);
  }
}
