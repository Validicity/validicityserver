import 'package:get_it/get_it.dart';
import 'package:validicitylib/validicitylib.dart';
import 'package:validicityserver/model/project.dart';
import 'package:validicityserver/model/log.dart';
import 'package:validicityserver/model/sample.dart';
import 'package:validicityserver/model/user.dart';
import 'package:validicityserver/service/chainpoint_service.dart';

import '../validicityserver.dart';

/// A single Proof.
class Proof extends ManagedObject<_Proof> implements _Proof {
  Proof();

  @override
  void willInsert() {
    created = new DateTime.now().toUtc();
    modified = new DateTime.now().toUtc();
  }

  @override
  void willUpdate() {
    modified = new DateTime.now().toUtc();
  }

  /// Find Proof based on proofId or int id
  static Future<Proof> find(ManagedContext context, String stringOrInt) async {
    var proofQuery = Query<Proof>(context);
    var id = int.tryParse(stringOrInt);
    if (id == null) {
      proofQuery.where((p) => p.proofId).equalTo(stringOrInt);
    } else {
      proofQuery.where((p) => p.id).equalTo(id);
    }
    return await proofQuery.fetchOne();
  }

  /// Submit this proof hash to Chainpoint
  Future submit(ManagedContext transaction) async {
    await GetIt.I<ChainpointService>().submit(this);
    logger.info("Proof submitted");
    var created = await Query.insertObject<Proof>(transaction, this);
    id = created.id;
    logger.info("Inserted Proof in database");
  }

  /// Retrieve this proof from Chainpoint
  Future retrieve(ManagedContext transaction) async {
    // Retrieve this proof
    await GetIt.I<ChainpointService>().retrieve(this);
    // Update in database TODO: We don't check if proof was really modified here
    final query = Query<Proof>(transaction);
    query.where((p) => p.id).equalTo(id);
    query.values = this;
    query.values.id = null; // Need to remove id
    await query.updateOne();
    logger.info("Proof retrieved and updated");
  }

  /* [
    {
      "proof_id": "21e44280-8e2d-11e8-8690-0112cb9597ab",
      "proof": "eJyNU0tuE0EQ5QgcgiWOq/rfs4rEFVixsaq6qvFIwbY8w28Z2LAkRwgJSkBskBBL7mGJw9B2PkCiCFaj6e736r1XVe/O98tyMeqr8cd8HFdDN52+tL3sLddPp2VO/WK17Bfj9IU9HV+v9POj66PTOQ3zzT5mH4VjVWPVsWJ0IKKcHYoIRVKgwDEZ9TZQVgD2RMkIoybnXfyypZn1MlssRTcPDKpzJsEkqZEJtkeTFDJMANEUzj5H4u87yPCcn/XjqBfIGY3fDGCaQJwY+xhcB9h58+SavizXO/oavfd/0rMxrtF7QFuSDanepN8i76I/5zUtylyHozcfD4j14Guhg9n2aLmeXdydLFfDz3v3D48PNg93Snvp/sfl4Yfl6myY08T4sAPvdOzA//ZwE/x+0Q9jh94ai8kBdLHWIGBy9cb5UrUKRlMq+2JMrCa4GL0TMcU1BmtVMwaVxi6piDprIvjisVrMDKHVRBYrkEADYZNBLteoZfvNjCWwDbFoMgFdoFTLTYH7bLkNiVrNtplBaxtQE9Vago/F15jFJirqQLn9RyyCKbnkOCJzlluEzSVyZikugjYj2aL3qc2iVCUomUgckXXgY4g+iYNtlJyhdUCB821C1hZDrcYaUvRM1oOoD4Y4ZsdFqIXLzV0iUQO2CQu5aSRn2iKEWz1pd4AhuKu2eAwddldLWPZ+b992Gbs2WN0l4vB4vdm3QbkFrzlVyyLZVbAgAIk9cFSK2PJrQbY2UetBixY5xtJCUAvVu7/knF2M7HD0drfmJ63Yp8sp7uXssuzp83U/HG327pI4bShdCK2nl4DpdpN+AbZKagM=",
      "anchors_complete": [
        "cal"
      ]
    }
  ] */
  /// Extract contents from Chainpoint response on submission
  void extractRetrieval(Map map) {
    proof = map["proof"]; // base64 encoded
    List anchors = map["anchors_complete"];
    for (var anchor in anchors) {
      switch (anchor) {
        case "cal":
          cal = true;
          break;
        case "btc":
          btc = true;
          break;
      }
    }
  }

  /// Extract contents from Chainpoint response on submission
  void extractSubmission(Map map) {
    var hashes = map["hashes"];
    hash = hashes.first["hash"];
    proofId = hashes.first["proof_id"];
    meta = Document(map["meta"]);
  }
}

class _Proof {
  @primaryKey
  int id;

  DateTime created;
  DateTime modified;

  /// The proof identifier allocated by Chainpoint on submission
  String proofId;

  /// The submitted cryptographic hash
  String hash;

  /// The proof itself, base64, when retrieved
  @Column(nullable: true)
  String proof;

  // Flags showing anchors ready
  @Column(nullable: false, defaultValue: "false")
  bool cal = false;
  @Column(nullable: false, defaultValue: "false")
  bool btc = false;

  /// The Sample of this Proof, if any
  @Relate(#proof, isRequired: false)
  Sample sample;

  /// The Project of this Proof
  @Relate(#proofs)
  Project project;

  /// Meta information
  Document meta;
}
