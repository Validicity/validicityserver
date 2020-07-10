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
    try {
      // Look up current user
      var user = await User.currentUser(query.context, request);
      // Verify that the User has registered a key
      var publicKey = user.publicKey;
      if (publicKey == null) {
        return Response.badRequest(body: {
          "error": "no_public_key",
          "detail": 'No public key registered for API user $user'
        });
      }
      // Verify that the submitted Sample is signed by the user
      var verified = verify(sample.signature, sample.hash, publicKey);
      if (!verified) {
        return Response.badRequest(body: {
          "error": "bad_signature",
          "detail": 'Sample record not properly signed by API user $user'
        });
      }
      // Fetch the last known record for this Sample
      query
        ..where((u) => u.serial).equalTo(serial)
        ..where((u) => u.next).isNull();
      query.join(object: (s) => s.project);
      var previousSample = await query.fetchOne();
      var project;
      // Is there no previous Sample record?
      if (previousSample == null) {
        // OK, this is the first block!
        if (sample.previous != "00") {
          return Response.badRequest(
              body:
                  'Incorrect record chaining, first block should currently have "00" for previous');
        }
        // Pick Project from User's access list, we presume only one right now TODO: Fix this
        var projects = await user.accessProjects(query.context);
        if (projects.isEmpty) {
          return Response.badRequest(body: {
            "error": "no_project",
            "detail": 'The user $user submitting has no project access'
          });
        } else {
          project = projects.first;
        }
      } else {
        project = previousSample.project;
        if (sample.previous != previousSample.hash) {
          print("Previous2: ${sample.previous}");
          return Response.badRequest(
              body:
                  'Incorrect record chaining, this block previous does not match hash of previous record');
        }
      }
      // A transaction
      var result = await query.context.transaction((transaction) async {
        if (previousSample != null) {
          // Mark the previous record to refer to this new one
          var q = Query<Sample>(transaction);
          q
            ..where((u) => u.serial).equalTo(serial)
            ..where((u) => u.next).isNull()
            ..values.next = sample.hash
            ..values.project = project;
          await q.updateOne();
        }
        // And insert Sample into database
        var q = Query<Sample>(transaction);
        q.values = sample;
        // We remove the id, should not be there
        q.values.removePropertyFromBackingMap('id');
        await q.insert();
        logger.info("All done");
      });
      return Response.ok(result);
    } catch (e) {
      return Response.serverError(body: {
        "error": "failure",
        "detail": "Failed submit new sample for unknown reason"
      });
    }
  }
}
