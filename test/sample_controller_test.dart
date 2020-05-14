import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:validicitylib/validicitylib.dart';

import 'harness/app.dart';

Future main() async {
  Harness harness = new Harness()..install();

  test("POST /sample creates a Sample without Project", () async {
    var response = await harness.adminAgent.post("/sample", body: {
      "hash": "AA",
      "previous": "root",
      "signature": "sig",
      "publicKey": "creator",
      "serial": "XX000001",
      "metadata": {}
    });
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
          "project": isNull
        }));
  });

  test("POST /sample fails to create a Sample with a bad state", () async {
    var response = await harness.adminAgent.post("/sample", body: {
      "hash": "AA",
      "previous": "root",
      "signature": "sig",
      "publicKey": "creator",
      "serial": "XX000001",
      "state": "destructed",
      "project": {"id": 1},
      "metadata": {}
    });
    expect(
        response,
        hasResponse(400,
            body: {"error": "bad_sample_state", "detail": isString}));
  });

  test("POST /sample fails to create a Sample with non existing Project",
      () async {
    var response = await harness.adminAgent.post("/sample", body: {
      "hash": "AA",
      "previous": "root",
      "signature": "sig",
      "publicKey": "creator",
      "serial": "XX000001",
      "project": {"id": 1},
      "metadata": {}
    });
    expect(
        response,
        hasResponse(400,
            body: {"error": "foreign_key_violation", "detail": isString}));
  });

  test("POST /sample create a Sample with existing Project", () async {
    await harness.adminAgent.post("/organisation",
        body: {"name": "Org", "description": "Nice", "metadata": {}});
    await harness.adminAgent.post("/project", body: {
      "name": "Project",
      "description": "Cool",
      "organisation": {"id": 1},
      "metadata": {}
    });
    var response = await harness.adminAgent.post("/sample", body: {
      "hash": "AA",
      "previous": "root",
      "signature": "sig",
      "publicKey": "creator",
      "serial": "XX000001",
      "project": {"id": 1},
      "metadata": {}
    });
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

  test("GET /sample/:id returns previously created Sample", () async {
    var response = await harness.adminAgent.post("/sample", body: {
      "hash": "AA",
      "previous": "root",
      "signature": "sig",
      "publicKey": "creator",
      "serial": "XX000001",
      "metadata": {}
    });
    final createdObject = response.body.as<Map>();
    response = await harness.adminAgent
        .request("/sample/${createdObject["id"]}")
        .get();
    expect(
        response,
        hasResponse(200, body: {
          "id": createdObject["id"],
          "serial": "XX000001",
          "hash": "AA",
          "previous": "root",
          "signature": "sig",
          "publicKey": "creator",
          "created": createdObject["created"],
          "modified": createdObject["modified"],
          "state": enumString(SampleState.registered),
          "metadata": {},
          "project": isNull
        }));
  });
}
