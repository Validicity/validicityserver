import 'dart:async';
import 'package:aqueduct/aqueduct.dart';   

class Migration12 extends Migration { 
  @override
  Future upgrade() async {
   		database.addColumn("_Sample", SchemaColumn("comment", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: false, isUnique: false));
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    