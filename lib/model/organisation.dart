import 'package:validicityserver/model/basic_credential.dart';
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
  @primaryKey
  int id;

  DateTime created;
  DateTime modified;

  String extId; // External id, typically in Fortnox or similar
  String name;
  String description;

  /// All Projects belonging to this Organisation
  ManagedSet<Project> projects;

  /// All Users at this Organisation
  ManagedSet<User> users;

  // Extra metadata
  Document metadata;
}
