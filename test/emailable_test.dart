import 'package:aqueduct/aqueduct.dart';
import 'package:mailer/mailer.dart';
import "package:test/test.dart";
import 'package:validicityserver/model/emailable.dart';
import 'package:validicityserver/model/metaholder.dart';

void main() {
  test("Emailable recipients", () {
    var a = EmailTest(Document({}));
    List<Address> testRecipients = [Address('george@validi.city', 'George')];
    a.recipients = testRecipients;
    expect(
        a.metadata['recipients'],
        equals([
          {'name': 'George', 'email': 'george@validi.city'}
        ]));
    expect(a.recipients[0].name, equals(testRecipients[0].name));
    expect(a.recipients[0].mailAddress, equals(testRecipients[0].mailAddress));
  });
}

class EmailTest with MetaHolder, Emailable {
  EmailTest(this.metadata);

  Document metadata;
}
