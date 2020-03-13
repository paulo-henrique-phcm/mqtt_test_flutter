import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_kindle/thermometer.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_kindle/Control_Temperature.dart';

import 'Control_Temperature.dart';


//################################################################ var necessarias p conexão
String broker = 'aaa';
int port = ;
String username = '';
String passwd = '';
String clientIdentifier = '';
String topic = '';

mqtt.MqttClient client;
mqtt.MqttConnectionState connectionState;

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
          Center(
            child: SizedBox(
              child: Control_Temperature(),
            ),
          ),
          Text(textStatus),
          Text(_temp.toString()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          PublishM(_temp.toString());
        },
        tooltip: 'Play',
        child: Icon(Icons.play_arrow),
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

    _subscribeToTopic(topic);
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
    setState(() {
      _temp = double.parse(message);
    });
    print("conectado");
  }

  //################################################################
}

void PublishM(String a) {
  final mqtt.MqttClientPayloadBuilder builder =
  mqtt.MqttClientPayloadBuilder();
  builder.addString(a);
  client.publishMessage("temp", mqtt.MqttQos.values[1], 
  builder.payload, retain: true,
  );
}