import 'dart:async';
import 'package:aqueduct/aqueduct.dart';
import 'package:validicityserver/model/basic_credential.dart';

/// Used to protect resources using basic auth only
class BasicCredentialVerifier extends AuthValidator {
  BasicCredentialVerifier(this.context);

  ManagedContext context;

  @override
  FutureOr<Authorization> validate<T>(
      AuthorizationParser<T> parser, T authorizationData,
      {List<AuthScope> requiredScope}) {
    if (parser is AuthorizationBasicParser) {
      return _validateClientCredentials(
          authorizationData as AuthBasicCredentials);
    }
    throw ArgumentError(
        "Invalid 'parser' for 'BasicCredentialVerifier.validate'. Use 'AuthorizationBasicParser'.");
  }

  Future<Authorization> _validateClientCredentials(
      AuthBasicCredentials credentials) async {
    final username = credentials.username;
    final password = credentials.password;

    // At this point we do not care what resource is being accessed,
    // as long as there is a BasicCredential with this username/password combo.
    var query = Query<BasicCredential>(context);
    query.where((bc) => bc.username).equalTo(username);
    var bc = await query.fetchOne();

    // No known BasicCredential with that username
    if (bc == null) {
      throw AuthServerException(AuthRequestError.invalidClient, null);
    }

    // Wrong password. TODO: Use hashing instead
    if (bc.password != password) {
      throw AuthServerException(AuthRequestError.invalidClient, null);
    }

    // We are good
    return Authorization(bc.id.toString(), null, this,
        credentials: credentials);
  }
}
