import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:validicitylib/model/key.dart';
import 'package:validicitylib/model/sample.dart';
import 'package:validicitylib/validicitylib.dart';

import 'harness/app.dart';

Future main() async {
  Harness harness = new Harness()..install();

  test("POST /sample fails to create a Sample with a missing public key",
      () async {
    var response =
        await harness.adminAgent.post("/sample/submit/XX000001", body: {
      "hash": "AA",
      "previous": "root",
      "signature": "sig",
      "publicKey": "creator",
      "serial": "XX000001",
      "project": {"id": 1},
      "metadata": {}
    });
    expect(response,
        hasResponse(400, body: {"error": "no_public_key", "detail": isString}));
  });

  test("POST /sample fails to create a Sample with a bad signature", () async {
    // TODO: FIrst register public key for admin
    var response =
        await harness.adminAgent.post("/sample/submit/XX000001", body: {
      "hash": "AA",
      "previous": "root",
      "signature": "sig",
      "publicKey": "creator",
      "serial": "XX000001",
      "project": {"id": 1},
      "metadata": {}
    });
    expect(response,
        hasResponse(400, body: {"error": "bad_signature", "detail": isString}));
  });

  test("POST /sample fails to create a Sample with non existing Project",
      () async {
    var response = await harness.adminAgent.post("/sample", body: {
      "hash": "AA",
      "previous": "root",
      "signature": "sig",
      "publicKey": "creator",
      "serial": "XX000001",
      "project": {"id": 99},
      "metadata": {}
    });
    expect(
        response,
        hasResponse(400,
            body: {"error": "foreign_key_violation", "detail": isString}));
  });

  test("POST /sample creates a Sample", () async {
    await harness.adminAgent.post("/organisation",
        body: {"name": "Org", "description": "Nice", "metadata": {}});
    int projId = await harness.adminAgent.post("/project", body: {
      "name": "Project",
      "description": "Cool",
      "organisation": {"id": 1},
      "metadata": {}
    }).id;
    // todo: register endpoint does not exist
    // var projId = await harness.adminAgent.post("/register", body: {
    //   "name": "Project",
    //   "description": "Cool",
    //   "organisation": {"id": 1},
    //   "metadata": {}
    // });

    var agent = await harness.createUserAgent();
    var user = await agent.get("/self");
    int userId = user.id;

    await harness.adminAgent.post("user/$userId/project/$projId");

    KeyPair key = createKeyMobile();
    await agent.post('key/${key.publicKey}');

    var sample = Sample()
      ..serial = "XX000001"
      ..previous = "00";
    sample.seal(key, null);
    var json = sample.toJson();

    var response =
        await agent.post("/sample/submit/${sample.serial}", body: json);
    expect(
        response,
        hasResponse(200, body: {
          "id": isNotNull,
          "created": isTimestamp,
          "modified": isTimestamp,
          "hash": "AA",
          "previous": "root",
          "signature": "sig",
          "publicKey": "creator",
          "serial": "XX000001",
          "state": enumString(SampleState.registered),
          "metadata": {},
          "project": {"id": 1}
        }));
  });
}
