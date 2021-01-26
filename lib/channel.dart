import 'package:timezone/standalone.dart';
import 'package:validicitylib/util.dart';
import 'package:validicityserver/controller/project_last_sample_controller.dart';
import 'package:validicityserver/controller/register_controller.dart';
import 'package:validicityserver/controller/sample_chain_controller.dart';
import 'package:validicityserver/service/chainpoint_service.dart';

import 'controller/bootstrap_controller.dart';
import 'controller/organisation_controller.dart';
import 'controller/organisation_project_controller.dart';
import 'controller/project_controller.dart';
import 'controller/project_sample_controller.dart';
import 'controller/recovery_controller.dart';
import 'controller/register_key_controller.dart';
import 'controller/sample_controller.dart';
import 'controller/sample_find_controller.dart';
import 'controller/sample_submission_controller.dart';
import 'controller/status_controller.dart';
import 'controller/user_controller.dart';
import 'controller/user_project_controller.dart';
import 'controller/user_self_controller.dart';
import 'model/user.dart';
import 'service/email_service.dart';
import 'service/mqtt.dart';
import 'service/validicityserver_scheduler.dart';
import 'validicityserver.dart';

/// This type initializes an application.
///
/// Override methods in this class to set up routes and initialize services like
/// database connections. See http://aqueduct.io/docs/http/channel/.
class ValidicityServerChannel extends ApplicationChannel {
  ManagedContext context;
  AuthServer authServer;
  // MqttService mqttService;
  EmailService emailService;
  ChainpointService chainpointService;
  StatusController statusController;
  // BasicCredentialVerifier basicCredentialVerifier;

  ValidicityServerScheduler scheduler;

  /// Initialize services in this method.
  ///
  /// Implement this method to initialize services, read values from [options]
  /// and any other initialization required before constructing [entryPoint].
  ///
  /// This method is invoked prior to [entryPoint] being accessed.
  @override
  Future prepare() async {
    RequestBody.maxSize = 20 * 1024 * 1024 * 1024;
    // When developing, turn these lines off later
    Controller.includeErrorDetailsInServerErrorResponses = true;
    hierarchicalLoggingEnabled = true;
    logger.level = Level.ALL;

    logger.onRecord.listen(
        (rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));

    var config = ValidicityServerConfiguration(options.configurationFilePath);
    context = contextWithConnectionInfo(config.database);

    // User authentication handling
    final delegate = TransformerAuthDelegate(context);
    authServer = AuthServer(delegate);
    // basicCredentialVerifier = BasicCredentialVerifier(context);

    // Initialize timezone db?
    await initializeTimeZone();

    // Read pubspec for status controller
    statusController = StatusController(context);

    // Create and connect to MQTT
    // mqttService = MqttService(config.mqtt);
    // await mqttService.connect();

    // Create emailService
    emailService = EmailService(config.email, context);

    // Create chainpointService
    chainpointService = ChainpointService(config.chainpoint, context);

    // Register getIts
    getIt.registerSingleton(config);
    // getIt.registerSingleton(mqttService);
    getIt.registerSingleton(emailService);
    getIt.registerSingleton(chainpointService);
    getIt.registerSingleton(context);

    await statusController.init();

    // Create and start Scheduler if this is the first Isolate
    if (server.identifier == 1) {
      scheduler = ValidicityServerScheduler(config.scheduler, context);
      getIt.registerSingleton(scheduler);
      scheduler.start();
    }

    CodecRegistry.defaultInstance
        .setAllowsCompression(ContentType("application", "pdf"), true);
  }

  /// Construct the request channel. This method is invoked after [prepare].
  @override
  Controller get entryPoint {
    final router = new Router();

    // Set up auth token route- this grants and refresh tokens
    router.route("/auth/token").link(() => AuthController(authServer));

    // Set up auth code route- this grants temporary access codes that can be exchanged for token
    // We do not use this yet.
    // router.route("/auth/code").link(() => AuthCodeController(authServer));

    // The BootstrapController is for bootstrap purposes and is not protected, it can only be run once
    router
      ..route("/bootstrap")
          .link(() => BootstrapController(context, authServer));

    // Users can register themselves
    router
        .route('/register')
        .link(() => RegisterController(context, authServer));

    // The RecoveryController is not protected, obviously
    router
      ..route("/recovery/:username/[:code/:password]")
          .link(() => RecoveryController(context, authServer));

    // The user controllers are only accessible by superusers.
    router
      ..route("/user/[:username]")
          .link(() => Authorizer.bearer(authServer, scopes: ["superuser"]))
          .link(() => UserController(context, authServer));

    router
      ..route("/user/:userid/project/[:id]")
          .link(() => Authorizer.bearer(authServer, scopes: ["superuser"]))
          .link(() => UserProjectController(context))
      ..route("/project/:projectid/users")
          .link(() => Authorizer.bearer(authServer, scopes: ["superuser"]))
          .link(() => UserProjectController(context));

    // The other controllers are accessible to all users.
    router
      ..route("/status")
          .link(() => Authorizer.bearer(authServer, scopes: ["client"]))
          .link(() => statusController)
      ..route("/key/:publicKey")
          .link(() => Authorizer.bearer(authServer, scopes: ["client"]))
          .link(() => RegisterKeyController(context))
      ..route("/self")
          .link(() => Authorizer.bearer(authServer, scopes: ["user"]))
          .link(() => UserSelfController(context, authServer))
      ..route("/organisation/[:id]")
          .link(() => Authorizer.bearer(authServer, scopes: ["user"]))
          .link(() => OrganisationController(context))
      ..route("/organisation/:organisationid/project")
          .link(() => Authorizer.bearer(authServer, scopes: ["user"]))
          .link(() => OrganisationProjectController(context))
      ..route("/project/[:id]")
          .link(() => Authorizer.bearer(authServer, scopes: ["user"]))
          .link(() => ProjectController(context))
      ..route("/project/:projectid/sample/[:id]")
          .link(() => Authorizer.bearer(authServer, scopes: ["user"]))
          .link(() => ProjectSampleController(context))
      ..route("/project/:projectid/lastsample/[:id]")
          .link(() => Authorizer.bearer(authServer, scopes: ["user"]))
          .link(() => ProjectLastSampleController(context))
      ..route("/sample/[:serial]")
          .link(() => Authorizer.bearer(authServer, scopes: ["user"]))
          .link(() => SampleController(context))
      ..route("/chain/[:serial]")
          .link(() => Authorizer.bearer(authServer, scopes: ["user"]))
          .link(() => SampleChainController(context))
      ..route("/sample/submit/[:serial]")
          .link(() => Authorizer.bearer(authServer, scopes: ["client"]))
          .link(() => SampleSubmissionController(context))
      ..route("/sample/find/[:serial]")
          .link(() => Authorizer.bearer(authServer, scopes: ["client"]))
          .link(() => SampleFindController(context));
    return router;
  }

  ManagedContext contextWithConnectionInfo(
      DatabaseConfiguration connectionInfo) {
    var dataModel = ManagedDataModel.fromCurrentMirrorSystem();
    var psc = PostgreSQLPersistentStore(
        connectionInfo.username,
        connectionInfo.password,
        connectionInfo.host,
        connectionInfo.port,
        connectionInfo.databaseName);
    return ManagedContext(dataModel, psc);
  }
}

/// An instance of this class reads values from a configuration
/// file specific to this application.
///
/// Configuration files must have key-value for the properties in this class.
/// For more documentation on configuration files, see https://aqueduct.io/docs/configure/ and
/// https://pub.dartlang.org/packages/safe_config.
class ValidicityServerConfiguration extends Configuration {
  ValidicityServerConfiguration(String fileName)
      : super.fromFile(new File(fileName));

  DatabaseConfiguration database;
  MqttConfiguration mqtt;
  EmailServiceConfiguration email;
  ChainpointServiceConfiguration chainpoint;
  ValidicityServerSchedulerConfiguration scheduler;

  /// This property is required.
  String host;
}

/// Return all possible scopes
List<String> allScopes() {
  List<String> scopes = [];
  for (UserType type in UserType.values) {
    scopes.add(type.toString().split('.').last);
  }
  scopes.add("canDebug");
  print("Scopes: $scopes");
  return scopes;
}

/// This class defines our rules for which users have what scopes. For the moment
/// "admin" is the only user with all scopes.
class TransformerAuthDelegate extends ManagedAuthDelegate<User> {
  TransformerAuthDelegate(ManagedContext context, {int tokenLimit: 40})
      : super(context, tokenLimit: tokenLimit);

  @override

  /// We override in order to also pull up type
  Future<User> getResourceOwner(AuthServer server, String username) {
    final query = Query<User>(context)
      ..where((u) => u.username).equalTo(username)
      ..returningProperties((t) => [
            t.id,
            t.username,
            t.hashedPassword,
            t.salt,
            t.type,
          ]);
    return query.fetchOne();
  }

  static String typeToString(UserType type) {
    return type.toString().split(".").last;
  }

  @override

  /// The possible List of scopes is the [UserType] and the canXXX permission flags.
  /// The controllers then further use combinations of scopes to decide if the operation is allowed.
  List<AuthScope> getAllowedScopes(covariant User user) {
    var scopes = <AuthScope>[];
    // Add one scope matching the UserType
    scopes.add(AuthScope(typeToString(user.type)));
    // Add further scopes based on UserType and permission flags
    switch (user.type) {
      case UserType.admin:
        // Shortcut, admin match all scopes
        return AuthScope.any;
      case UserType.superuser:
        // A superuser can also do whatever a user can do
        scopes.add(AuthScope(typeToString(UserType.user)));
        break;
      case UserType.client:
      case UserType.user:
        // A user can do all things a client can do
        scopes.add(AuthScope(typeToString(UserType.client)));
    }
    print("Scopes: $scopes");
    return scopes;
  }
}
