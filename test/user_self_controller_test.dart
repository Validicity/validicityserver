import 'package:aqueduct_test/aqueduct_test.dart';

import 'harness/app.dart';

Future main() async {
  Harness harness = new Harness()..install();

  test("GET /self returns self", () async {
    // await harness.makeUser();
    var agent = await harness.createUserAgent();
    var response = await agent.get("/self");
    expect(response, hasResponse(200));
  });

  test("UPDATE /self updates self", () async {
    var agent = await harness.createUserAgent();
    var user = await agent.get("/self").map;
    user["name"] = "John Doe";
    user["avatar"] = "asdfasdf";
    // var response = await agent.put("/self", body: );
    var response = await agent.put("/self", body: user);
    response = await agent.get("/self");
    expectResponse(response, 200,
        body: partial(
          {
            "name": "John Doe",
            "avatar": "asdfasdf",
          },
        ));
  });
}
