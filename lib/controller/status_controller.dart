import 'package:validicityserver/model/user.dart';

import '../validicityserver.dart';
import 'package:pubspec/pubspec.dart';
import 'dart:io';

/// This controller shows various information about the Validicity system.
class StatusController extends ResourceController {
  StatusController(this.context);

  PubSpec pubSpec;
  final ManagedContext context;

  // Used to load version of Validicityserver
  Future<void> init() async {
    pubSpec = await PubSpec.load(Directory.current);
  }

  @Operation.get()
  Future<Response> status() async {
    var numberOfUsers = await Query<User>(context).reduce.count();
    var status = {
      'system': {
        'hostname': Platform.localHostname,
        'version': pubSpec.version.toString(),
        'dartversion': Platform.version,
        'osversion': Platform.operatingSystemVersion
      },
      'data': {'users': numberOfUsers}
    };
    return Response.ok(status);
  }
}
