import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_kindle/thermometer.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_kindle/Control_Temperature.dart';

import 'Control_Temperature.dart';

//################################################################ var necessarias p conexão
String broker = 'soldier.cloudmqtt.com';
int port = 17843;
String username = 'efbwcvvu';
String passwd = 'FWF3kqx3Yupz';
String clientIdentifier = '27843';
String topic = "temp";

mqtt.MqttClient client;
mqtt.MqttConnectionState connectionState;

int ar1 = 0;
int ar2 = 0;

void main() => runApp(MyApp());

String textStatus = "Bem vindo!";

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: textStatus),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //################################################################
  //conecta automaticamente ao server mqtt quando inicia o app (se nao estiver conectado)
  @override
  void initState() {
    super.initState();
    if (connectionState != mqtt.MqttConnectionState.connected) {
      _connect();
    }
  }
  //################################################################

  double _temp = 30;
  StreamSubscription subscription;

  //#################################################################
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(ar1.toString(), style: TextStyle(fontSize: 60)),
              SizedBox(width: 100,),
              Text(ar2.toString(), style: TextStyle(fontSize: 60)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: SizedBox(
                  child: Control_Temperature(ar1, "temp-1"),
                ),
              ),
              SizedBox(width: 40,),
              Center(
                child: SizedBox(
                  child: Control_Temperature(ar2, "temp-2"),
                ),
              ),
            ],
          ),
          //Text(textStatus),
          //Text(_temp.toString()),
        ],
      ),
    );
  }

  //################################################################ funções importantes pra conexão

  Future _connect() async {
    client = mqtt.MqttClient(broker, '');
    client.port = port;

    client.logging(on: true);

    client.keepAlivePeriod = 30;

    client.onDisconnected = _onDisconnected;

    final mqtt.MqttConnectMessage connMess = mqtt.MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean() // Non persistent session for testing
        .keepAliveFor(30)
        .withWillQos(mqtt.MqttQos.atMostOnce);
    print('[MQTT client] MQTT client connecting....');
    client.connectionMessage = connMess;

    /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
    /// in some circumstances the broker will just disconnect us, see the spec about this, we however will
    /// never send malformed messages.

    try {
      await client.connect(username, passwd);
    } catch (error) {
      print(error);
      _disconnect();
    }

    /// Check if we are connected
    if (client.connectionState == mqtt.MqttConnectionState.connected) {
      print('[MQTT client] connected');
      setState(() {
        connectionState = client.connectionState;
      });
    } else {
      print('[MQTT client] ERROR: MQTT client connection failed - '
          'disconnecting, state is ${client.connectionState}');
      _disconnect();
    }

    /// The client has a change notifier object(see the Observable class) which we then listen to to get
    /// notifications of published updates to each subscribed topic.
    subscription = client.updates.listen(_onMessage);

    _subscribeToTopic("temp-1");
    _subscribeToTopic("temp-2");
  }

  void _subscribeToTopic(String topic) {
    if (connectionState == mqtt.MqttConnectionState.connected) {
      print('[MQTT client] Subscribing to ${topic.trim()}');
      client.subscribe(topic, mqtt.MqttQos.exactlyOnce);
    }
  }

  void _disconnect() {
    print('[MQTT client] _disconnect()');
    client.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    print('[MQTT client] _onDisconnected');
    setState(() {
      //topics.clear();
      connectionState = client.connectionState;
      client = null;
      subscription.cancel();
      subscription = null;
    });
    print('[MQTT client] MQTT client disconnected');
  }

  void _onMessage(List<mqtt.MqttReceivedMessage> event) {
    print(event.length);
    final mqtt.MqttPublishMessage recMess =
        event[0].payload as mqtt.MqttPublishMessage;
    final String message =
        mqtt.MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    /// The above may seem a little convoluted for users only interested in the
    /// payload, some users however may be interested in the received publish message,
    /// lets not constrain ourselves yet until the package has been in the wild
    /// for a while.
    /// The payload is a byte buffer, this will be specific to the topic
    print('[MQTT client] MQTT message: topic is <${event[0].topic}>, '
        'payload is <-- ${message} -->');
    print(client.connectionState);
    print("[MQTT client] message with topic: ${event[0].topic}");
    print("[MQTT client] message with message: ${message}");
    _trataMsg(event[0].topic, message);
    print("conectado");
  }

  void _trataMsg(String topic, String msg) {
    if (topic == "temp-1") {
      setState(() {
        ar1 = int.parse(msg);
      });
    }
    if (topic == "temp-2") {
      setState(() {
        ar2 = int.parse(msg);
      });
    }
  }

  //################################################################
}

void PublishM(String mes, String topic) {
  final mqtt.MqttClientPayloadBuilder builder = mqtt.MqttClientPayloadBuilder();
  builder.addString(mes);
  client.publishMessage(topic, mqtt.MqttQos.values[1],
    builder.payload,
    retain: true,
  );
}
