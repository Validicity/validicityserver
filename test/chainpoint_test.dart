import "package:test/test.dart";
import 'package:validicitylib/model/block.dart';
import 'package:validicityserver/model/proof.dart';
import 'package:validicityserver/service/chainpoint_service.dart';
import 'harness/app.dart';

Future main() async {
  Harness harness = new Harness()..install();

  test("Chainpoint findPublicUri", () async {
    var service = ChainpointService(
        ChainpointServiceConfiguration.fromString("publicUriUrl:"),
        harness.context);
    var uri = await service.findPublicUri();
    expect(uri.toString(), startsWith("http://"));
  });

  test("Chainpoint submit proof", () async {
    var service = ChainpointService(
        ChainpointServiceConfiguration.fromString("publicUriUrl:"),
        harness.context);
    var proof = Proof();
    var fact = "I will make a game called Tankfeud";
    proof.hash = makeHash(fact);
    await service.submit(proof);
    print(proof.toString());
  });
}
