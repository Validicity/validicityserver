import 'dart:io';

import 'package:safe_config/safe_config.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../validicityserver.dart';

/// A service sending email. Aqueduct configuration model with safe_config.
class EmailService {
  EmailService(this.config, this.context) {
    server = SmtpServer(config.host,
        port: config.port,
        username: config.username,
        password: config.password);
    defaultFrom = Address(config.fromAddress, config.fromName);
  }

  ManagedContext context;
  EmailServiceConfiguration config;
  SmtpServer server;
  Address defaultFrom;

  Logger get logger => Logger("aqueduct");

  Future sendEmail(String subject, String text, List<Address> recipients,
      {String html, String fromAddress, String fromName}) async {
    var from =
        fromAddress != null ? Address(fromAddress, fromName) : defaultFrom;

    final message = new Message()
      ..from = from
      ..recipients.addAll(recipients)
      ..subject = subject
      ..text = text
      ..html = html;

    try {
      final sendReport = await send(message, server);
      logger.info('Email message sent: ' + sendReport.toString());
    } on MailerException catch (e, s) {
      logger.warning(
          "Failed to send email with subject $subject : $e stacktrace: $s");
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }
}

/// A [Configuration] to represent a Scheduler service.
class EmailServiceConfiguration extends Configuration {
  EmailServiceConfiguration();

  EmailServiceConfiguration.fromFile(File file) : super.fromFile(file);

  EmailServiceConfiguration.fromString(String yaml) : super.fromString(yaml);

  EmailServiceConfiguration.fromMap(Map<dynamic, dynamic> yaml)
      : super.fromMap(yaml);

  /// The SMTP server host name.
  /// This property is required.
  String host;

  /// The SMTP user name.
  /// This property is required.
  String username;

  /// The SMTP user password.
  /// This property is required.
  String password;

  /// The SMTP port.
  @optionalConfiguration
  int port = 587;

  /// Default from address
  @optionalConfiguration
  String fromAddress = 'validicity@validi.city';

  /// Default from name
  @optionalConfiguration
  String fromName = 'Validicity';
}
