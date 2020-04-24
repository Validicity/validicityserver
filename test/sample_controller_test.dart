import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:validicitylib/validicitylib.dart';

import 'harness/app.dart';

Future main() async {
  Harness harness = new Harness()..install();

  test("POST /sample creates a Sample without Project", () async {
    var response = await harness.adminAgent.post("/sample",
        body: {"extId": "whatever", "serial": "XX000001", "metadata": {}});
    expect(
        response,
        hasResponse(200, body: {
          "extId": "whatever",
          "id": isNotNull,
          "created": isTimestamp,
          "modified": isTimestamp,
          "serial": "XX000001",
          "state": enumString(SampleState.registered),
          "metadata": {},
          "project": isNull
        }));
  });

  test("POST /sample fails to create a Sample with a bad state", () async {
    var response = await harness.adminAgent.post("/sample", body: {
      "extId": "whatever",
      "serial": "XX000001",
      "state": "inStock",
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
      "extId": "whatever",
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
    await harness.adminAgent.post("/organisation", body: {
      "extId": "whatever",
      "name": "Org",
      "description": "Nice",
      "metadata": {}
    });
    await harness.adminAgent.post("/project", body: {
      "extId": "whatever",
      "name": "Project",
      "description": "Cool",
      "organisation": {"id": 1},
      "metadata": {}
    });
    var response = await harness.adminAgent.post("/sample", body: {
      "extId": "whatever",
      "serial": "XX000001",
      "project": {"id": 1},
      "metadata": {}
    });
    expect(
        response,
        hasResponse(200, body: {
          "extId": "whatever",
          "id": isNotNull,
          "created": isTimestamp,
          "modified": isTimestamp,
          "serial": "XX000001",
          "state": enumString(SampleState.registered),
          "metadata": {},
          "project": {"id": 1}
        }));
  });

  test("GET /sample/:id returns previously created Sample", () async {
    var response = await harness.adminAgent.post("/sample",
        body: {"extId": "whatever", "serial": "XX000001", "metadata": {}});
    final createdObject = response.body.as<Map>();
    response = await harness.adminAgent
        .request("/sample/${createdObject["id"]}")
        .get();
    expect(
        response,
        hasResponse(200, body: {
          "id": createdObject["id"],
          "extId": "whatever",
          "serial": "XX000001",
          "created": createdObject["created"],
          "modified": createdObject["modified"],
          "state": enumString(SampleState.registered),
          "metadata": {},
          "project": isNull
        }));
  });

  test("PUT /sample/:id updated Sample with new state", () async {
    var response = await harness.adminAgent.post("/sample",
        body: {"extId": "whatever", "serial": "XX000001", "metadata": {}});
    final createdObject = response.body.as<Map>();
    createdObject["state"] = enumString(SampleState.assigned);
    var id = createdObject.remove("id");
    response = await harness.adminAgent.put("/sample/$id", body: createdObject);
    expect(
        response,
        hasResponse(200, body: {
          "id": id,
          "extId": "whatever",
          "serial": "XX000001",
          "created": createdObject["created"],
          "modified": isTimestamp,
          "state": enumString(SampleState.assigned), // assigned!
          "metadata": {},
          "project": isNull
        }));
  });

  test(
      "PUT /sample/:id fails to update Sample with state not allowed for this user",
      () async {
    var response = await harness.adminAgent.post("/sample",
        body: {"extId": "whatever", "serial": "XX000001", "metadata": {}});
    final createdObject = response.body.as<Map>();
    createdObject["state"] = enumString(SampleState.assigned);
    var id = createdObject.remove("id");
    var agent = await harness.createUserAgent();
    response = await agent.put("/sample/$id", body: createdObject);
    expect(
        response,
        hasResponse(400,
            body: {"error": "sample_state_not_allowed", "detail": isString}));
  });

  test(
      "PUT /sample/:id succeeds to update Sample with state allowed for this user",
      () async {
    var response = await harness.adminAgent.post("/sample",
        body: {"extId": "whatever", "serial": "XX000001", "metadata": {}});
    final createdObject = response.body.as<Map>();
    createdObject["state"] = enumString(SampleState.used);
    var id = createdObject.remove("id");
    response = await harness.adminAgent.put("/sample/$id", body: createdObject);
    var agent = await harness.createUserAgent();
    createdObject["state"] = enumString(SampleState.used);
    response = await agent.put("/sample/$id", body: createdObject);
    expect(response, hasResponse(200));
  });

  test(
      "PUT /sample/:id fails to update Sample with state allowed for this user but not from current state",
      () async {
    var response = await harness.adminAgent.post("/sample",
        body: {"extId": "whatever", "serial": "XX000001", "metadata": {}});
    final createdObject = response.body.as<Map>();
    createdObject["state"] = enumString(SampleState.used);
    var id = createdObject.remove("id");
    var agent = await harness.createUserAgent();
    response = await agent.put("/sample/$id", body: createdObject);
    expect(
        response,
        hasResponse(400,
            body: {"error": "sample_state_not_allowed", "detail": isString}));
  });

  test("GET /sample/:id returns previously created Sample", () async {
    var response = await harness.adminAgent.post("/sample",
        body: {"extId": "whatever", "serial": "XX000001", "metadata": {}});
    final createdObject = response.body.as<Map>();
    response = await harness.adminAgent
        .request("/sample/${createdObject["id"]}")
        .get();
    expect(
        response,
        hasResponse(200, body: {
          "id": createdObject["id"],
          "extId": "whatever",
          "serial": "XX000001",
          "created": createdObject["created"],
          "modified": createdObject["modified"],
          "state": enumString(SampleState.registered),
          "metadata": {},
          "project": isNull
        }));
  });
}
