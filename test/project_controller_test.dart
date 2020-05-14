import 'package:aqueduct_test/aqueduct_test.dart';

import 'harness/app.dart';

Future main() async {
  Harness harness = new Harness()..install();

  test("POST /project creates a Project if Organisation exists", () async {
    var organisation = await harness.getOrganisation();
    var response = await harness.makeProjectResponse(organisation);
    expect(
        response,
        hasResponse(200, body: {
          "id": isNotNull,
          "organisation": {"id": organisation['id']},
          "created": isTimestamp,
          "modified": isTimestamp,
          "name": "Project",
          "description": "Cool",
          "location": "Europe/Stockholm",
          "metadata": {}
        }));
  });

  test("GET /project/1 gets a Project if it exists", () async {
    var organisation = await harness.getOrganisation();
    await harness.makeProjectResponse(organisation);
    var response = await harness.adminAgent.get("/project/1");
    expect(
        response,
        hasResponse(200, body: {
          "id": isNotNull,
          "organisation": {"id": organisation['id']},
          "created": isTimestamp,
          "modified": isTimestamp,
          "name": "Project",
          "description": "Cool",
          "location": "Europe/Stockholm",
          "metadata": {}
        }));
  });

  test("POST /project fails to create a Project if Organisation is missing",
      () async {
    var response = await harness.adminAgent.post("/project", body: {
      "name": "Project",
      "organisation": {"id": 99},
      "description": "Cool",
      "metadata": {}
    });
    expect(
        response,
        hasResponse(400,
            body: {"error": "foreign_key_violation", "detail": isString}));
  });

  test("PUT /project updates Project", () async {
    var organisation = await harness.getOrganisation();
    await harness.makeProjectResponse(organisation);
    var response = await harness.adminAgent.put("/project/1", body: {
      "name": "Project",
      "description": "Cooler",
      "metadata": {"some": 43}
    });
    expect(
        response,
        hasResponse(200, body: {
          "id": isNotNull,
          "organisation": {"id": organisation['id']},
          "created": isTimestamp,
          "modified": isTimestamp,
          "name": "Project",
          "description": "Cooler",
          "location": "Europe/Stockholm",
          "metadata": {"some": 43}
        }));
  });
}
