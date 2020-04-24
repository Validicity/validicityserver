import 'package:mailer/mailer.dart';
import 'package:validicityserver/model/metaholder.dart';

/// Keeps recipients in metadata.
mixin Emailable on MetaHolder {
  List<Address> get recipients {
    List<Address> result = [];
    var recipients = metadata['recipients'];
    if (recipients != null) {
      for (var r in recipients) {
        result.add(Address(r['email'], r['name']));
      }
    }
    return result;
  }

  set recipients(List<Address> list) {
    var result = [];
    for (var a in list) {
      result.add({'name': a.name, 'email': a.mailAddress});
    }
    metadata['recipients'] = result;
  }
}
