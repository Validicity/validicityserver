import 'package:validicityserver/model/user.dart';
import 'package:validicityserver/model/log.dart';

import '../validicityserver.dart';

class RegisterKeyController extends ResourceController {
  RegisterKeyController(ManagedContext context) {
    query = Query<User>(context);
  }
  Query<User> query;

  /// Register key for current User
  @Operation.post('publicKey')
  Future<Response> addSample(@Bind.path('publicKey') String publicKey) async {
    var user = await User.currentUser(query.context, request);
    query
      ..where((u) => u.id).equalTo(user.id)
      ..values.publicKey = publicKey;
    var result = await query.updateOne();

    // We could do this async (without await) but then testing fails...
    await LogEntry.create(user, query.context,
        message: "Registered key $publicKey to User ${user.id}");
    return Response.ok(result);
  }
}
