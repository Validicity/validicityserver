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
  @Operation.post()
  Future<Response> submitSample(@Bind.body() Sample sample) async {
    var user = await User.currentUser(query.context, request);
    var publicKey = user.publicKey;
    var verified = verifySignature(sample.signature, sample.hash, publicKey);
    if (!verified) {
      return Response.badRequest(
          body: 'Sample record not properly signed by APU user $user');
    }
    query
      ..where((u) => u.serial).equalTo(sample.serial)
      ..where((u) => u.next).isNull();
    var previousSample = await query.fetchOne();
    if (previousSample == null) {
      // First block!
      if (sample.previous != null) {
        return Response.badRequest(
            body:
                'Incorrect record chaining, first block has currently null for previous');
      }
    }
    if (sample.previous != previousSample.hash) {
      return Response.badRequest(
          body:
              'Incorrect record chaining, this block previous does not match hash of previous record');
    }
    // Insert into database
    query.values = sample;
    return Response.ok(await query.insert());
  }
}
