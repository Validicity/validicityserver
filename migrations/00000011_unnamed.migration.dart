import 'dart:async';
import 'package:aqueduct/aqueduct.dart';   

class Migration11 extends Migration { 
  @override
  Future upgrade() async {
   		database.addColumn("_User", SchemaColumn("avatar", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, defaultValue: "null", isIndexed: false, isNullable: true, isUnique: false));
		database.addColumn("_Sample", SchemaColumn.relationship("user", ManagedPropertyType.bigInteger, relatedTableName: "_User", relatedColumnName: "id", rule: DeleteRule.nullify, isNullable: true, isUnique: false));
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    