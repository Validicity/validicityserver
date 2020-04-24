import 'dart:io';

import 'package:safe_config/safe_config.dart';
import 'package:cron/cron.dart';

import '../validicityserver.dart';

/// A service triggering actions based on schedules, only active in ONE Isolate.
/// Aqueduct configuration model with safe_config.
class ValidicityServerScheduler {
  ValidicityServerScheduler(this.config, this.context);

  ManagedContext context;
  ValidicityServerSchedulerConfiguration config;
  Cron cron;
  Logger get logger => Logger("aqueduct");

  void start() {
    cron = Cron();

    cron.schedule(Schedule.parse(config.reportsSchedule), () async {
      logger.info('Creating reports...');
      try {
        await createReports();
      } catch (e, s) {
        logger.warning("Failed to create reports: $e stacktrace: $s");
      }
      logger.info('Done creating reports.');
    });
  }

  /// Create all reports
  Future createReports() async {
    // TODO
  }

  /// Logic copied from Cron class
  bool isDue(String cronSchedule) {
    var schedule = Schedule.parse(cronSchedule);
    var now = DateTime.now();
    if (schedule?.minutes?.contains(now.minute) == false) return false;
    if (schedule?.hours?.contains(now.hour) == false) return false;
    if (schedule?.days?.contains(now.day) == false) return false;
    if (schedule?.months?.contains(now.month) == false) return false;
    if (schedule?.weekdays?.contains(now.weekday) == false) return false;
    return true;
  }
}

/// A [Configuration] to represent a Scheduler service.
class ValidicityServerSchedulerConfiguration extends Configuration {
  ValidicityServerSchedulerConfiguration();

  ValidicityServerSchedulerConfiguration.fromFile(File file)
      : super.fromFile(file);

  ValidicityServerSchedulerConfiguration.fromString(String yaml)
      : super.fromString(yaml);

  ValidicityServerSchedulerConfiguration.fromMap(Map<dynamic, dynamic> yaml)
      : super.fromMap(yaml);

  /// The cron schedule for reports
  ///
  /// This property is required.
  String reportsSchedule;
}
