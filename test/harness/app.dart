import 'package:validicitylib/util.dart';
import 'package:validicityserver/model/user.dart';
import 'package:validicityserver/validicityserver.dart';
import 'package:aqueduct_test/aqueduct_test.dart';

export 'package:test/test.dart';
export 'package:aqueduct/aqueduct.dart';

/// A testing harness for Validicity.
class Harness extends TestHarness<ValidicityServerChannel>
    with TestHarnessAuthMixin<ValidicityServerChannel>, TestHarnessORMMixin {
  @override
  ManagedContext get context => channel.context;

  @override
  AuthServer get authServer => channel.authServer;

  // For CLI tool
  Agent validAgent;
  Agent adminAgent;
  Agent userAgent;
  Agent validicityAgent;

  @override
  Future onSetUp() async {
    await resetData();

    validAgent = await addClient("validi.city.valid",
        allowedScope: allScopes()); // Can not use 'any' here
    adminAgent = await registerUser(
        "admin", "admin", UserType.admin, "admin@validi.city",
        requestScopes: allScopes());
    // await BasicCredential.insertOrUpdate(
    //    BasicCredential()
    //      ..username = 'public'
    //      ..password = 's91hnc7ayhf',
    //    context);
  }

  Future<Agent> createUserAgent() async {
    userAgent = await registerUser(
        "user", "user", UserType.user, "user@validi.city",
        requestScopes: allScopes());
    return userAgent;
  }

  Future<Agent> createClientAgent() async {
    validicityAgent = await registerUser(
        "client", "client", UserType.client, "client@validi.city",
        requestScopes: allScopes());
    return validicityAgent;
  }

  Future<Agent> registerUser(
      String username, String password, UserType type, String email,
      {List<String> requestScopes}) async {
    final salt = AuthUtility.generateRandomSalt();
    final hashedPassword = authServer.hashPassword(password, salt);
    var user = User()
      ..email = email
      ..username = username
      ..type = type
      ..hashedPassword = hashedPassword
      ..salt = salt;
    await Query.insertObject(context, user);
    return loginUser(validAgent, username, password, scopes: requestScopes);
  }

  @override
  Future beforeStart() async {
    // add initialization code that will run prior to the test application starting
  }

  @override
  Future afterStart() async {
    // add initialization code that will run once the test application has started
    await resetData();
  }

  @override
  Future seed() async {
    // restore any static data. called afterStart and after resetData
  }

  /// Reusable functions for tests
  Future<TestResponse> getOrganisationResponse() async {
    var response = await adminAgent.post("/organisation",
        body: {"name": "Winniepeg", "description": "Nice", "metadata": {}});
    return response;
  }

  Future<Map> getOrganisation() async {
    return (await getOrganisationResponse()).body.as<Map>();
  }

  Future<TestResponse> makeProjectResponse(Map organisation) async {
    var response = await adminAgent.post("/project", body: {
      "name": "Project",
      "description": "Cool",
      "location": "Europe/Stockholm",
      "organisation": {"id": organisation['id']},
      "metadata": {}
    });
    return response;
  }

  Future<Map> makeProject(Map organisation) async {
    return (await makeProjectResponse(organisation)).body.as<Map>();
  }

  Future<TestResponse> makeUser({
    String username = "foo1",
    String password = "bar1",
    String name = "Foo Bar",
    String type = "user",
    String email = "foo@bar.com",
    String publicKey,
    String avatar,
    int customerId,
    int lastCode,
  }) async {
    return await adminAgent.post("/user", body: {
      "username": username,
      "name": name,
      "type": type,
      "password": password,
      "email": email,
      "lastCode": lastCode,
      "publicKey": lastCode,
      "avatar": avatar,
      "organisation": {"id": customerId},
    });
  }
}

// shorthand for converting a [TestResponse]'s body to a Map
extension FutureResponseToBody on Future<TestResponse> {
  Future<Map> get map async => (await this).body.as<Map>();
  Future<int> get id async => (await this.map)['id'];
}

extension ResponseToBody on TestResponse {
  Map get map => this.body.as<Map>();
  int get id => this.map['id'];
}
