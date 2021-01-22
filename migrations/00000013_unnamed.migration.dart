import 'dart:async';
import 'package:aqueduct/aqueduct.dart';   

class Migration13 extends Migration { 
  @override
  Future upgrade() async {
   		database.addColumn("_Sample", SchemaColumn("location", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: true, isUnique: false));
		database.alterColumn("_Sample", "comment", (c) {c.isUnique = false;});
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    