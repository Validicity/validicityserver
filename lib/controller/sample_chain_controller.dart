import '../validicityserver.dart';
import '../model/sample.dart';

/// Return full chain of Samples, including Proofs
class SampleChainController extends ResourceController {
  SampleChainController(this.context) {
    query = Query<Sample>(context);
  }

  ManagedContext context;
  Query<Sample> query;

  /// Get full Sample chain by serial, including proofs
  @Operation.get('serial')
  Future<Response> getSampleChain(@Bind.path('serial') String serial) async {
    query
      ..where((sample) => sample.serial).equalTo(serial)
      ..sortBy((s) => s.created, QuerySortOrder.ascending)
      ..join(object: (s) => s.proof)
      ..join(object: (s) => s.user)
          .returningProperties((x) => [x.id, x.name, x.avatar]);
    var found = await query.fetch();
    if (found == null) {
      return Response.notFound();
    }
    return Response.ok(found);
  }
}
