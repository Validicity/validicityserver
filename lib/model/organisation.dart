import 'package:validicityserver/model/project.dart';
import 'package:validicityserver/model/user.dart';

import '../validicityserver.dart';

/// An Organisation that Users can belong to.
class Organisation extends ManagedObject<_Organisation>
    implements _Organisation {
  @override
  void willInsert() {
    created = new DateTime.now().toUtc();
    modified = new DateTime.now().toUtc();
  }

  @override
  void willUpdate() {
    modified = new DateTime.now().toUtc();
  }
}

class _Organisation {
  // -------- These fields are not included in the block
  @primaryKey
  int id;

  DateTime created;
  DateTime modified;
  // --------
/*
  /// Cryptographic hash of this record
  @Column(unique: true, indexed: true)
  String hash;

  /// Root hash of Organisation, a random.
  @Column(unique: true)
  String previous;

  /// Cryptographic signature of this record
  String signature;

  /// Creator of this record
  String publicKey;
  */

  String name;
  String description;

  /// All Projects belonging to this Organisation
  ManagedSet<Project> projects;

  /// All Users at this Organisation
  ManagedSet<User> users;

  // Extra metadata
  Document metadata;
}
