import 'package:validicityserver/model/sample.dart';
import 'package:validicityserver/model/user.dart';

import '../validicityserver.dart';

/// History log of Samples and Users. Each time important changes
/// are made to a Sample or a User, a new LogEntry is created.
class LogEntry extends ManagedObject<_LogEntry> implements _LogEntry {
  @override
  void willInsert() {
    created = new DateTime.now().toUtc();
    modified = new DateTime.now().toUtc();
  }

  @override
  void willUpdate() {
    modified = new DateTime.now().toUtc();
  }

  static Future<LogEntry> create(ManagedObject obj, ManagedContext context,
      {String message, Map<String, dynamic> entry}) async {
    var q = Query<LogEntry>(context);
    // Ugly, but... not sure how to do this
    if (obj is Sample) {
      q.values.sample = obj;
    } else if (obj is User) {
      q.values.user = obj;
    }
    q.values.entry = Document(entry ?? {"message": message});
    return await q.insert();
  }
}

class _LogEntry {
  @primaryKey
  int id;

  DateTime created;
  DateTime modified;

  @Relate(#log, isRequired: false)
  Sample sample;

  @Relate(#log, isRequired: false)
  User user;

  // The actual log entry
  Document entry;
}
