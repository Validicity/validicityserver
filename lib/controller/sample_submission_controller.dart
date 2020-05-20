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
    // Look up current user
    var user = await User.currentUser(query.context, request);
    // Verify that the submitted Sample is signed by the user
    var publicKey = user.publicKey;
    var verified = verify(sample.signature, sample.hash, publicKey);
    if (!verified) {
      return Response.badRequest(
          body: 'Sample record not properly signed by API user $user');
    }
    // Fetch the last known record for this Sample
    query
      ..where((u) => u.serial).equalTo(serial)
      ..where((u) => u.next).isNull();
    var previousSample = await query.fetchOne();
    // Is there no previous Sample record?
    if (previousSample == null) {
      // OK, this is the first block!
      if (sample.previous != "00") {
        return Response.badRequest(
            body:
                'Incorrect record chaining, first block should currently have "00" for previous');
      }
    } else {
      if (sample.previous != previousSample.hash) {
        return Response.badRequest(
            body:
                'Incorrect record chaining, this block previous does not match hash of previous record');
      }
    }
    var result = await query.context.transaction((transaction) async {
      if (previousSample != null) {
        // Mark the previous record to refer to this new one
        query
          ..where((u) => u.serial).equalTo(serial)
          ..where((u) => u.next).isNull()
          ..values.next = sample.hash;
        await query.updateOne();
      }
      // And insert Sample into database
      query.values = sample;
      // We remove the id, should not be there
      query.values.removePropertyFromBackingMap('id');
      return await query.insert();
    });
    return Response.ok(result);
  }
}
