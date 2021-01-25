import 'package:validicitylib/model/block.dart';
import 'package:validicitylib/validicitylib.dart';
import 'package:validicityserver/model/log.dart';
import 'package:validicityserver/model/project.dart';
import 'package:validicityserver/model/proof.dart';
import 'package:validicityserver/model/user.dart';

import '../validicityserver.dart';

/// A single Sample.
class Sample extends ManagedObject<_Sample> implements _Sample {
  Sample();

  Sample.fromSerial(String serial) {
    this.serial = serial;
    metadata = Document({});
  }

  @override
  void willInsert() {
    created = new DateTime.now().toUtc();
    modified = new DateTime.now().toUtc();
  }

  @override
  void willUpdate() {
    modified = new DateTime.now().toUtc();
  }

  /// Create proof that this Sample exists
  Future createProof() async {
    await globalContext.transaction((transaction) async {
      var p = Proof();
      p.project = project;
      p.sample = this;
      p.hash = makeHash(
          "Sample with serial=$serial, signature=$signature and hash=$hash exists.");
      await p.submit(transaction);
      logger.info("Proof created for sample $id");
    });
  }

  /// Find Sample based on serial or int id
  static Future<Sample> find(String serialOrId) async {
    var sampleQuery = Query<Sample>(globalContext);
    var id = int.tryParse(serialOrId);
    if (id == null) {
      sampleQuery.where((u) => u.serial).equalTo(serialOrId);
    } else {
      sampleQuery.where((u) => u.id).equalTo(id);
    }
    return await sampleQuery.fetchOne();
  }

  /// Find Sample, or create one, based on serial
  static Future<Sample> findOrCreate(String serial) async {
    var query = Query<Sample>(globalContext);
    query.where((u) => u.serial).equalTo(serial);
    var found = await query.fetchOne();
    if (found != null) {
      return found;
    } else {
      var sample = Sample.fromSerial(serial);
      query = Query<Sample>(globalContext);
      query.values = sample;
      sample = await query.insert();
      return sample;
    }
  }

  String projectTopic() {
    return project == null ? 'project/null' : 'project/${project.id}';
  }

  /// Verify that this new state is allowed for this user.
  /// Currently the logic is centered purely around user type and current state.
  bool verifyState(SampleState newState, User user) {
    var available = availableStates(user);
    return available.contains(state) && available.contains(newState);
  }

  List<SampleState> availableStates(User user) {
    switch (user.type) {
      case UserType.admin:
      case UserType.superuser:
      case UserType.client:
        return SampleState.values;
      case UserType.user:
        return SampleState.values;
      default:
        return [];
    }
  }

  List<String> availableStateStrings(User user) {
    return availableStates(user).map((s) => enumString(s)).toList();
  }

  List<String> allStateStrings() {
    return SampleState.values.map((s) => enumString(s)).toList();
  }
}

class _Sample {
  // -------- These fields are not included in the block
  @primaryKey
  int id;

  DateTime created;
  DateTime modified;
  // --------

  /// Cryptographic hash of this record
  @Column(unique: true, indexed: true)
  String hash;

  /// Previous record hash in the same Project, or Project hash (so not unique for first record in each chain)
  String previous;

  /// Next record hash in the same Project. If null this is the last record.
  @Column(unique: true, nullable: true)
  String next;

  /// Cryptographic signature of this record
  String signature;

  /// Creator of this record
  String publicKey;

  /// The serial identifier for the Sample, the NFC tag id?
  String serial;

  @Column(nullable: true)
  String comment;

  @Column(nullable: true)
  String location;

  @Column(nullable: true)
  double latitude;

  @Column(nullable: true)
  double longitude;

  /// The current state of the Sample's lifecycle
  @Column(defaultValue: "'registered'")
  SampleState state;

  /// The Project of this Sample
  @Relate(#samples)
  Project project;

  /// The Proof of this Sample
  Proof proof;

  ManagedSet<LogEntry> log;

  // All metadata about this Sample
  Document metadata;

  // The user that scanned the sample
  @Relate(#samples, isRequired: false)
  User user;
}
