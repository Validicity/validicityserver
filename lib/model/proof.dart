import 'package:get_it/get_it.dart';
import 'package:validicitylib/validicitylib.dart';
import 'package:validicityserver/model/project.dart';
import 'package:validicityserver/model/log.dart';
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
  Future submit() async {
    await GetIt.I<ChainpointService>().submit(this);
    var context = GetIt.I<ManagedContext>();
    return Query.insertObject<Proof>(context, this);
  }

  /// Retrieve this proof from Chainpoint
  Future retrieve() async {}

  /// Extract contents from Chainpoint response on submission
  void extract(Map map) {
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

  /// The Project of this Proof
  @Relate(#proofs)
  Project project;

  /// Meta information
  Document meta;
}
