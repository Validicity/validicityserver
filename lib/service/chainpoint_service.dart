import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:safe_config/safe_config.dart';
import 'package:http/http.dart' as http;
import 'package:validicityserver/model/proof.dart';
import '../validicityserver.dart';

/// A service interacting with the Chainpoint network. Aqueduct configuration model with safe_config.
class ChainpointService {
  ChainpointService(this.config, this.context) {}

  ManagedContext context;
  ChainpointServiceConfiguration config;

  Logger get logger => Logger("aqueduct");

  Future<Uri> findPublicUri() async {
    var uri = Uri.parse(config.publicUriUrl);
    var result = await http.get(uri);
    List ips = json.decode(result.body);
    return Uri.parse("http://${ips[Random().nextInt(ips.length)]}");
  }

  // Default headers used
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };

  /*
    {
      "meta": {
        "submitted_at": "2018-07-23T04:01:52Z",
        "processing_hints": {
          "cal": "2018-07-23T04:02:07Z",
          "btc": "2018-07-23T06:00:00Z"
        }
      },
      "hashes": [
        {
          "proof_id": "21e44280-8e2d-11e8-8690-0112cb9597ab",
          "hash": "1957db7fe23e4be1740ddeb941ddda7ae0a6b782e536a9e00b5aa82db1e84547"
        }
      ]
    }
  */
  Future submit(Proof proof) async {
    try {
      var tries = 0;
      var success = false;
      while (!success & (tries < 5)) {
        var uri = await findPublicUri();
        var submitUri = uri.resolve('/hashes');
        var body = json.encode({
          "hashes": [proof.hash]
        });
        print("Uri: $uri hash: ${proof.hash}");
        var response = await http.post(submitUri, body: body, headers: headers);
        if (response.statusCode == 200) {
          success = true;
          Map map = json.decode(response.body);
          proof.extractSubmission(map);
          logger.info('Proof submitted as: ${proof.proofId}');
          return proof;
        } else {
          tries += 1;
          logger.warning("Failed to submit proof ${proof.id}: $response");
        }
      }
      return null;
    } on Exception catch (e, s) {
      logger.warning("Failed to submit proof ${proof.id} : $e stacktrace: $s");
    }
  }

  Future retrieve(Proof proof) async {
    try {
      var tries = 0;
      var success = false;
      while (!success & (tries < 5)) {
        var uri = await findPublicUri();
        var retrieveUri = uri.resolve('/proofs/${proof.proofId}');
        print("Uri: $uri hash: ${proof.hash}");
        var response = await http.get(retrieveUri, headers: headers);
        if (response.statusCode == 200) {
          success = true;
          Map map = json.decode(response.body);
          proof.extractRetrieval(map);
          logger.info('Proof retrieved: ${proof.proofId}');
          return proof;
        } else {
          tries += 1;
          logger.warning("Failed to retrieve proof ${proof.id}: $response");
        }
      }
      return null;
    } on Exception catch (e, s) {
      logger
          .warning("Failed to retrieve proof ${proof.id} : $e stacktrace: $s");
    }
  }
}

/// A [Configuration] to represent a Scheduler service.
class ChainpointServiceConfiguration extends Configuration {
  ChainpointServiceConfiguration();

  ChainpointServiceConfiguration.fromFile(File file) : super.fromFile(file);

  ChainpointServiceConfiguration.fromString(String yaml)
      : super.fromString(yaml);

  ChainpointServiceConfiguration.fromMap(Map<dynamic, dynamic> yaml)
      : super.fromMap(yaml);

  /// Url to get ips TODO: Should be a List really, abc
  String publicUriUrl = "http://52.14.86.247/gateways/public";
}
