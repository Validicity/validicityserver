import 'package:validicityserver/model/sample.dart';
import 'package:validicityserver/model/log.dart';
import 'package:validicityserver/model/user.dart';
import 'package:validicitylib/validicitylib.dart';
import '../validicityserver.dart';

class SampleStateController extends ResourceController {
  SampleStateController(ManagedContext context) {
    query = Query<Sample>(context);
  }
  Query<Sample> query;

  /// Change SampleState of a given Sample
  @Operation.put('id', 'state')
  Future<Response> changeState(
      @Bind.path('id') int id, @Bind.path('state') String stateString) async {
    var newState = sampleStateFromString(stateString);
    if (newState == null) {
      return Response.badRequest(body: 'Bad sample state string $stateString');
    }

    // Verify that this is a new state
    query.where((u) => u.id).equalTo(id);
    var sample = await query.fetchOne();
    if (sample.state == newState) {
      return Response.badRequest(
          body: 'Sample $id already in state $stateString');
    }

    // Verify that this user is allowed to set given state
    var user = await User.currentUser(query.context, request);
    if (!sample.verifyState(newState, user)) {
      return Response.badRequest(
          body: 'User $user not allowed to set state $stateString');
    }
    // Finally set the state and log it
    query
      ..where((u) => u.id).equalTo(id)
      ..values.state = newState;
    sample = await query.updateOne();
    // We could do this async (without await) but then testing fails...
    await LogEntry.create(sample, query.context,
        message: "Changed Sample $id to state $newState");
    return Response.ok(sample);
  }

  /// Get available states, which one is current, and which ones are available for this user
  @Operation.get('id')
  Future<Response> getStates(@Bind.path('id') int id) async {
    query.where((u) => u.id).equalTo(id);
    var sample = await query.fetchOne();
    if (sample == null) {
      return Response.notFound();
    }
    var user = await User.currentUser(query.context, request);
    var json = {
      "current": enumString(sample.state),
      "all": sample.allStateStrings(),
      "available": sample.availableStateStrings(user)
    };
    return Response.ok(json);
  }
}
