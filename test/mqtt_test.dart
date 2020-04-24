import 'package:mqtt_client/mqtt_client.dart';
import "package:test/test.dart";

void main() {
  test("Topic test", () {
    var temp = PublicationTopic('shell/34/open');
    expect(temp.topicFragments, equals(['shell', '34', 'open']));
  });
}
