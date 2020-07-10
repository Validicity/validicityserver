import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:safe_config/safe_config.dart';
import 'package:cron/cron.dart';
import 'package:validicityserver/model/proof.dart';

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
    cron.schedule(Schedule.parse(config.proofsRetrieveSchedule), () async {
      logger.info('Retrieving proofs...');
      try {
        await retrieveProofs();
      } catch (e, s) {
        logger.warning("Failed to retrieve proofs: $e stacktrace: $s");
      }
      logger.info('Done retrieving proofs.');
    });
  }

  /// Retrieve all proofs not yet completely anchored
  Future retrieveProofs() async {
    var context = GetIt.I<ManagedContext>();
    final query = Query<Proof>(context);
    query.where((p) => !(p.btc & p.cal));
    var proofs = await query.fetch();
    for (var proof in proofs.toList()) {
      await proof.retrieve(context);
    }
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

  /// The cron schedule for proof retrieval
  ///
  /// This property is required.
  String proofsRetrieveSchedule;
}
