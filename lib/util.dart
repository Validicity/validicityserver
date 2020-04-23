import 'package:validicityserver/validicityserver.dart';

class JsonMap extends Serializable {
  Map<String, dynamic> map;

  @override
  void readFromMap(Map<String, dynamic> m) {
    map = m;
  }

  @override
  Map<String, dynamic> asMap() {
    return map;
  }
}
