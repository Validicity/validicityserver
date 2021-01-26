library validicityserver;

import 'package:aqueduct/aqueduct.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:validicitylib/error.dart';

export 'dart:async';
export 'dart:io';

export 'package:timezone/standalone.dart';
export 'package:aqueduct/aqueduct.dart';
export 'package:aqueduct/managed_auth.dart';
export 'channel.dart';

// Accessible all over ValidicityServer
GetIt getIt = GetIt.I;
ManagedContext get globalContext => getIt<ManagedContext>();
Logger logger = Logger("aqueduct");

/// Construct a specific error response
Response errorResponse(ValidicityServerError error, String detail) {
  return Response.badRequest(body: makeError(error, detail));
}
