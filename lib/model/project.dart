import 'package:validicityserver/model/organisation.dart';
import 'package:validicityserver/model/proof.dart';
import 'package:validicityserver/model/sample.dart';
import 'package:validicityserver/model/user.dart';

import '../validicityserver.dart';

/// A specific group of taken Samples.
class Project extends ManagedObject<_Project> implements _Project {
  @override
  void willInsert() {
    created = new DateTime.now().toUtc();
    modified = new DateTime.now().toUtc();
  }

  @override
  void willUpdate() {
    modified = new DateTime.now().toUtc();
  }

  Location getTimezoneLocation() {
    if (location == null) {
      return getLocation('Europe/Stockholm');
    }
    return getLocation(location);
  }
}

class _Project {
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

  /// Organisation hash.
  @Column(unique: true)
  String previous;

  /// Cryptographic signature of this record
  String signature;

  /// Creator of this record
  String publicKey;
*/
  @Column(unique: true)
  String name;
  String description;

  /// According to timezone db, like 'America/Detroit' etc
  /// https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
  @Column(nullable: true)
  String location;

  @Relate(#projects)
  Organisation organisation;

  // All Samples assigned to this Project
  ManagedSet<Sample> samples;

  // All Proofs made in this Project
  ManagedSet<Proof> proofs;

  // All Users with access to this Project
  ManagedSet<UserProject> userProjects;

  // All metadata
  Document metadata;
}

/// Join table for many-to-many relation
class UserProject extends ManagedObject<_UserProject> implements _UserProject {}

class _UserProject {
  @primaryKey
  int id;

  @Relate(#userProjects)
  Project project;

  @Relate(#userProjects)
  User user;
}
