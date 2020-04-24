import 'package:validicityserver/validicityserver.dart';

/// Defines a class that has a Document member to keep
/// unstructured metadata.
abstract class MetaHolder {
  Document get metadata;
}
