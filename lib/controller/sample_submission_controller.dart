import 'package:validicityserver/model/sample.dart';
import 'package:validicityserver/model/user.dart';
import 'package:validicitylib/model/key.dart';
import 'package:validicityserver/validicityserver.dart';

class SampleSubmissionController extends ResourceController {
  SampleSubmissionController(ManagedContext context) {
    query = Query<Sample>(context);
  }
  Query<Sample> query;

  /// Create a new Sample
  @Operation.post('serial')
  Future<Response> submitSample(
      @Bind.path('serial') String serial, @Bind.body() Sample sample) async {
    var user = await User.currentUser(query.context, request);
    var publicKey = user.publicKey;
    var verified = verify(sample.signature, sample.hash, publicKey);
    if (!verified) {
      return Response.badRequest(
          body: 'Sample record not properly signed by APU user $user');
    }
    query
      ..where((u) => u.serial).equalTo(serial)
      ..where((u) => u.next).isNull();
    var previousSample = await query.fetchOne();
    if (previousSample == null) {
      // First block!
      if (sample.previous != "00") {
        return Response.badRequest(
            body:
                'Incorrect record chaining, first block has currently "00" for previous');
      }
    } else {
      if (sample.previous != previousSample.hash) {
        return Response.badRequest(
            body:
                'Incorrect record chaining, this block previous does not match hash of previous record');
      }
    }
    // Insert into database
    query.values = sample;
    query.valueMap.remove('id');
    return Response.ok(await query.insert());
  }
}
