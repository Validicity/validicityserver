import 'dart:async';
import 'package:aqueduct/aqueduct.dart';   

class Migration8 extends Migration { 
  @override
  Future upgrade() async {
   		database.alterColumn("_Proof", "cal", (c) {c.defaultValue = "false";});
		database.alterColumn("_Proof", "btc", (c) {c.defaultValue = "false";});
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    