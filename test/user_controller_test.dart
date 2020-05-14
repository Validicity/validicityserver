import 'package:aqueduct_test/aqueduct_test.dart';

import 'harness/app.dart';

Future main() async {
  Harness harness = new Harness()..install();

  Map checkUser(TestResponse response) {
    expect(
        response,
        hasResponse(200, body: {
          "id": isNotNull,
          "name": "Göran Krampe",
          "created": isTimestamp,
          "modified": isTimestamp,
          "username": "gokr",
          "type": "user",
          "organisation": null,
          "email": "goran.krampe@gmail.com"
        }));
    return response.body.as<Map>();
  }

  Future<Map> createOrganisationProjectAndUser() async {
    await harness.adminAgent.post("/organisation",
        body: {"name": "Org", "description": "Nice", "metadata": {}});
    await harness.adminAgent.post("/project", body: {
      "name": "Project",
      "description": "Cool",
      "organisation": {"id": 1},
      "metadata": {}
    });
    var response = await harness.adminAgent.post("/user", body: {
      "username": "gokr",
      "name": "Göran Krampe",
      "type": "user",
      "password": "nice",
      "email": "goran.krampe@gmail.com"
    });
    return checkUser(response);
  }

  test("POST /user creates a User", () async {
    await createOrganisationProjectAndUser();
  });

  test("GET /user/:username returns previously created User", () async {
    await createOrganisationProjectAndUser();
    var response = await harness.adminAgent.get("/user/gokr");
    checkUser(response);
  });

  test("POST /user/:userid/project/:id gives access to Project", () async {
    var userMap = await createOrganisationProjectAndUser();
    var response =
        await harness.adminAgent.post("/user/${userMap["id"]}/project/1");
    expect(
        response,
        hasResponse(200, body: {
          "id": isNotNull,
          "project": {"id": 1},
          "user": {"id": 2}
        }));
  });

  test("GET /user/:userid/project gives all Projects", () async {
    var userMap = await createOrganisationProjectAndUser();
    await harness.adminAgent.post("/user/${userMap["id"]}/project/1");
    var response =
        await harness.adminAgent.get("/user/${userMap["id"]}/project");
    expect(
        response,
        hasResponse(200, body: [
          {
            "id": 1,
            "created": isTimestamp,
            "modified": isTimestamp,
            "name": "Project",
            "description": "Cool",
            "location": null,
            "metadata": isMap,
            "organisation": {
              "id": 1,
              "created": isTimestamp,
              "modified": isTimestamp,
              "name": isString,
              "description": isString,
              "metadata": isMap
            }
          }
        ]));
  });

  test("GET /user/:userid/project gives zero Projects if there are none",
      () async {
    var userMap = await createOrganisationProjectAndUser();
    var response =
        await harness.adminAgent.get("/user/${userMap["id"]}/project");
    expect(response, hasResponse(200, body: []));
  });

  test("DELETE /user/:userid/project/:id removes access to Project", () async {
    var userMap = await createOrganisationProjectAndUser();
    await harness.adminAgent.post("/user/${userMap["id"]}/project/1");
    var response =
        await harness.adminAgent.delete("/user/${userMap["id"]}/project/1");
    expect(response, hasResponse(200));
    response = await harness.adminAgent.get("/user/${userMap["id"]}/project");
    expect(response, hasResponse(200, body: []));
  });

  test(
      "GET /project/1/users gets all Users with access to Project if it exists",
      () async {
    var userMap = await createOrganisationProjectAndUser();
    await harness.adminAgent.post("/user/${userMap["id"]}/project/1");
    var response = await harness.adminAgent.get("/project/1/users");
    expect(
        response,
        hasResponse(200, body: [
          {
            "id": 2,
            "email": "goran.krampe@gmail.com",
            "created": isTimestamp,
            "modified": isTimestamp,
            "type": "user",
            "username": "gokr",
            "name": "Göran Krampe",
            "organisation": null
          }
        ]));
  });

  test(
      "GET /project/1/users gets zero Users with access to Project if there are none",
      () async {
    await createOrganisationProjectAndUser();
    var response = await harness.adminAgent.get("/project/1/users");
    expect(response, hasResponse(200, body: []));
  });

  test("GET /project/99/users gets 404 for missing Project", () async {
    var response = await harness.adminAgent.get("/project/99/users");
    expect(response, hasResponse(404));
  });
}
