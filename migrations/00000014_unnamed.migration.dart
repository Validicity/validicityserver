import 'dart:async';
import 'package:aqueduct/aqueduct.dart';   

class Migration14 extends Migration { 
  @override
  Future upgrade() async {
   		database.addColumn("_Sample", SchemaColumn("latitude", ManagedPropertyType.doublePrecision, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: true, isUnique: false));
		database.addColumn("_Sample", SchemaColumn("longitude", ManagedPropertyType.doublePrecision, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: true, isUnique: false));
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    