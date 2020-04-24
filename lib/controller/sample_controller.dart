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

  /// Create a new Sample
  @Operation.post()
  Future<Response> createSample(@Bind.body() Sample sample) async {
    // Verify state
    var user = await User.currentUser(query.context, request);
    if (sample.state != null && sample.state != SampleState.registered) {
      return Response.badRequest(body: {
        "error": "bad_sample_state",
        "detail":
            "Creating sample with state ${sample.state} not allowed for user $user"
      });
    }

    // Insert into database
    query.values = sample;
    return Response.ok(await query.insert());
  }

  /// Get all Samples
  @Operation.get()
  Future<Response> getAllSamples() async {
    var found = await query.fetch();
    if (found == null) {
      return Response.notFound();
    }
    return Response.ok(found);
  }

  /// Get Sample by id
  @Operation.get('id')
  Future<Response> getSample(@Bind.path('id') int id) async {
    query.where((sample) => sample.id).equalTo(id);
    var found = await query.fetchOne();
    if (found == null) {
      return Response.notFound();
    }
    return Response.ok(found);
  }

  /// Update Sample by id
  @Operation.put('id')
  Future<Response> updateSample(
      @Bind.path('id') int id, @Bind.body() Sample sample) async {
    query.where((sample) => sample.id).equalTo(id);
    var found = await query.fetchOne();
    // Verify state
    var user = await User.currentUser(query.context, request);
    if (!found.verifyState(sample.state, user)) {
      return Response.badRequest(body: {
        "error": "sample_state_not_allowed",
        "detail": "New state not allowed for user $user"
      });
    }
    query
      ..where((sample) => sample.id).equalTo(id)
      ..values = sample;
    var result = await query.updateOne();
    return new Response.ok(result);
  }

  /// Delete Sample by id
  @Operation.delete('id')
  Future<Response> deleteSample(@Bind.path('id') int id) async {
    query.where((sample) => sample.id).equalTo(id);
    int deleted = await query.delete();
    if (deleted == 0) {
      return Response.notFound();
    }
    return Response.ok(null);
  }
}
