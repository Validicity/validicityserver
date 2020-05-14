import 'dart:async';
import 'package:aqueduct/aqueduct.dart';   

class Migration2 extends Migration { 
  @override
  Future upgrade() async {
   		database.addColumn("_User", SchemaColumn("publicKey", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: true, isUnique: true));
		database.addColumn("_User", SchemaColumn("uniqueId", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: true, isUnique: false));
		database.deleteColumn("_Organisation", "extId");
		database.deleteColumn("_Project", "extId");
		database.addColumn("_Sample", SchemaColumn("hash", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: true, isNullable: false, isUnique: true));
		database.addColumn("_Sample", SchemaColumn("previous", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: false, isUnique: true));
		database.addColumn("_Sample", SchemaColumn("signature", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: false, isUnique: false));
		database.addColumn("_Sample", SchemaColumn("publicKey", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: false, isUnique: false));
		database.deleteColumn("_Sample", "extId");
		database.alterColumn("_Sample", "serial", (c) {c.isUnique = false;});
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    