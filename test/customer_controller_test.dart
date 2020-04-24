import 'package:aqueduct_test/aqueduct_test.dart';

import 'harness/app.dart';

Future main() async {
  Harness harness = new Harness()..install();

  test("POST /organisation creates a Organisation", () async {
    var response = await harness.adminAgent.post("/organisation", body: {
      "extId": "whatever",
      "name": "Org",
      "description": "Nice",
      "metadata": {}
    });
    expect(
        response,
        hasResponse(200, body: {
          "extId": "whatever",
          "id": isNotNull,
          "created": isTimestamp,
          "modified": isTimestamp,
          "name": "Org",
          "description": "Nice",
          "metadata": {},
          "credential": null
        }));
  });

  test("GET /organisation/:id returns previously created Organisation",
      () async {
    var response = await harness.adminAgent.post("/organisation", body: {
      "extId": "whatever",
      "name": "Org",
      "description": "Nice",
      "metadata": {}
    });
    final createdObject = response.body.as<Map>();
    response = await harness.adminAgent
        .request("/organisation/${createdObject["id"]}")
        .get();
    expect(
        response,
        hasResponse(200, body: {
          "id": createdObject["id"],
          "extId": "whatever",
          "name": "Org",
          "description": "Nice",
          "created": createdObject["created"],
          "modified": createdObject["modified"],
          "metadata": {},
          "credential": null
        }));
  });
}
