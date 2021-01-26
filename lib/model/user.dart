import 'dart:math';

import 'package:get_it/get_it.dart';
import 'package:mailer/mailer.dart';
import 'package:validicitylib/util.dart';
import 'package:validicityserver/model/project.dart';
import 'package:validicityserver/model/log.dart';
import 'package:validicityserver/model/sample.dart';
import 'package:validicityserver/service/email_service.dart';
import 'package:validicityserver/validicityserver.dart';

import '../validicityserver.dart';
import 'organisation.dart';

/// This is a User of the system. The username property is inherited.
class User extends ManagedObject<_User>
    implements _User, ManagedAuthResourceOwner<_User> {
  @Serialize(input: true, output: false)
  String password;

  @override
  void willInsert() {
    created = new DateTime.now().toUtc();
    modified = new DateTime.now().toUtc();
  }

  @override
  void willUpdate() {
    modified = new DateTime.now().toUtc();
  }

  /// Create a 6 digit random number between 111111-999999
  /// and store it in the database for this User.
  Future<int> createRecoveryCode() async {
    var code = getRandomRecoveryCode();
    var query = Query<User>(globalContext);
    query
      ..where((u) => u.id).equalTo(id)
      ..values.lastCode = code;
    await query.updateOne();
    return code;
  }

  /// Return a 6 digit random number between 111111-999999.
  int getRandomRecoveryCode() {
    return (111111 + Random.secure().nextInt(888888));
  }

  /// Return true if this password meets rules
  bool passwordGoodEnough(String newPassword) {
    // TODO: Password policy?
    return true;
  }

  /// Send recovery code for password reset
  Future<bool> sendRecoveryCode() async {
    var code = await createRecoveryCode();
    var emailService = GetIt.I<EmailService>();
    return emailService.sendEmail('Validicity password recovery', '''
Hi!

A 6 digit recovery code has been requested for the Validicity user account associated with this email.
If you did not do this you can ignore this email.

Code: $code

In Validicity, use the code above to create a new password. Have a good day!

regards, Validicity
''', [getEmailAddress()]);
  }

  Address getEmailAddress() {
    return Address(email, name);
  }

  /// Make a Project accessible to the User
  Future<UserProject> addProject(Project im) async {
    final join = Query<UserProject>(globalContext);
    join
      ..values.user = this
      ..values.project = im;
    return await join.insert();
  }

  /// Remove a Project accessible to the User
  Future removeProject(Project im) async {
    final join = Query<UserProject>(globalContext);
    join
      ..where((u) => u.user).identifiedBy(id)
      ..where((im) => im).identifiedBy(im.id);
    return await join.delete();
  }

  /// Do we have a mapping to this Project?
  Future<bool> canAccessProject(Project im) async {
    final join = Query<UserProject>(globalContext);
    join
      ..where((u) => u.user).identifiedBy(id)
      ..where((im) => im).identifiedBy(im.id);
    return join.fetchOne() == null;
  }

  /// Return all Projects we have access to
  Future<List<Project>> accessProjects() async {
    final join = Query<UserProject>(globalContext);
    join..where((u) => u.user).identifiedBy(id);
    var ups = await join.fetch();
    return ups.map((ui) => ui.project).toList();
  }

  /// Easy function to find one by id
  static Future<User> find(int id) async {
    var query = Query<User>(globalContext);
    query.where((user) => user.id).equalTo(id);
    return query.fetchOne();
  }

  /// Easy function to find one User by username
  static Future<User> findByUsername(String username) async {
    var query = Query<User>(globalContext);
    query.where((user) => user.username).equalTo(username);
    return query.fetchOne();
  }

  /// Return the User doing this request
  static Future<User> currentUser(Request request) async {
    print("Scopes of user: ${request.authorization.scopes}");
    var userId = request.authorization.ownerID;
    var user = User.find(userId);
    print("User: $user");
    return user;
  }

  @override
  String toString() {
    return email + '($type)';
  }
}

class _User extends ResourceOwnerTableDefinition {
  @Serialize(input: true, output: false)
  String password;

  @Column(unique: true)
  String email;

  @Column(nullable: true, unique: true)
  String publicKey;

  @Column(nullable: true, omitByDefault: true)
  int lastCode;

  // The full name of the user
  @Column(defaultValue: "''")
  String name;

  // A unique id, for clients this is the board id
  @Column(nullable: true)
  String uniqueId;

  DateTime created;
  DateTime modified;

  @Column(defaultValue: "'user'")
  UserType type;

  /// The users avatar, base64 encoded
  @Column(nullable: true, defaultValue: "null")
  String avatar;

  // All projects I have access to
  ManagedSet<UserProject> userProjects;

  /// The log of the User
  ManagedSet<LogEntry> log;

  /// The samples that the user has scanned.
  ManagedSet<Sample> samples;

  /// The Organisation the User belongs to
  @Relate(#users)
  Organisation organisation;
}
