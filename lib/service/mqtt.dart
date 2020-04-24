import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:logging/logging.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:safe_config/safe_config.dart';
import 'package:typed_data/typed_buffers.dart';

// We export this in order for users of this service
export 'package:typed_data/typed_buffers.dart';

/// A service wrapping the MQTT client for convenience and using the
/// Aqueduct configuration model with safe_config.
class MqttService {
  MqttService(this.config);

  MqttServerClient client;
  MqttConfiguration config;

  Logger get logger => Logger("aqueduct");

  /// Connect to MQTT
  Future<bool> connect() async {
    var clientID = config.clientID ??
        'validicityserver_' + new Random().nextInt(99999).toString();

    client = MqttServerClient(config.host, clientID);
    client
      ..keepAlivePeriod = 7
      ..setProtocolV311()
      ..useWebSocket = config.websocket
      ..secure = config.secure
      ..port = config.port
      ..logging(on: config.logging);
    logger.info("Connecting to ${config.host}");
    try {
      await client.connect(config.username, config.password);
    } catch (e, s) {
      logger.severe("Failed to connect to MQTT: $e stack: $s config: $config");
      client.disconnect();
      return false;
    }

    // Check if we are not connected
    if (client.connectionStatus.state != MqttConnectionState.connected) {
      logger.severe("Failed to connect to MQTT");
      client.disconnect();
      return false;
    }

    logger.info("Connected");
    return true;
  }

  bool isConnected() {
    if (client == null) {
      return false;
    }
    return client.connectionStatus.state == MqttConnectionState.connected;
  }

  int publishJSONMessage(
      String topic, MqttQos qualityOfService, Map<String, dynamic> map,
      {bool retain: false}) {
    final payload = json.encode(map);
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    return client.publishMessage(topic, qualityOfService, builder.payload,
        retain: retain);
  }

  int publishMessage(String topic, MqttQos qos, Uint8Buffer data,
      {bool retain: false}) {
    return client.publishMessage(topic, qos, data, retain: retain);
  }

  /// Publishing en empty retained message will remove the existing retained message
  int unpublishMessage(String topic, MqttQos qos) {
    return client.publishMessage(topic, qos, Uint8Buffer(0), retain: true);
  }

  void unsubscribe(String topic) {
    client.unsubscribe(topic);
  }

  void subscribe(
      String topic, MqttQos qos, Function(String, MqttPublishMessage) handler) {
    client.subscribe(topic, qos);
    var filter = MqttClientTopicFilter(topic, client.updates);
    filter.updates.listen((List<MqttReceivedMessage> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final topic = c[0].topic;
      handler(topic, message);
    });
  }
}

/// A [Configuration] to represent an MQTT service.
class MqttConfiguration extends Configuration {
  MqttConfiguration();

  MqttConfiguration.fromFile(File file) : super.fromFile(file);

  MqttConfiguration.fromString(String yaml) : super.fromString(yaml);

  MqttConfiguration.fromMap(Map<dynamic, dynamic> yaml) : super.fromMap(yaml);

  /// Which server host to connect to.
  ///
  /// This property is required.
  String host;

  /// The username to connect as.
  ///
  /// This property is required.
  String username;

  /// The password for the user.
  ///
  /// This property is required.
  String password;

  /// The client ID.
  ///
  /// This property is optional.
  @optionalConfiguration
  String clientID;

  /// If logging is turned on.
  ///
  /// This property is optional.
  @optionalConfiguration
  bool logging = false;

  /// If we connect using SSL.
  ///
  /// This property is optional.
  @optionalConfiguration
  bool secure = false;

  /// If we connect using a websocket.
  ///
  /// This property is optional.
  @optionalConfiguration
  bool websocket = false;

  /// Which port to use.
  ///
  /// This property is optional.
  @optionalConfiguration
  int port = 1883;
}
