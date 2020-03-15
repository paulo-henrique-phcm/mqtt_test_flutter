import 'package:flutter/material.dart';
import 'package:mqtt_kindle/main.dart';


class Control_Temperature extends StatefulWidget {
  final int temp;
  final String topic;
  const Control_Temperature(this.temp, this.topic);

  @override
  _Control_TemperatureState createState() => _Control_TemperatureState();
}

class _Control_TemperatureState extends State<Control_Temperature> {
  int temp;
  String topic;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      temp = widget.temp;
      topic = widget.topic;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          ButtonTheme(
            minWidth: 100.0,
            height: 200.0,
            child: RaisedButton(
              color: Colors.red,
              onPressed: () {
                setState(() {
                  temp++;
                });
                PublishM(temp.toString(), topic);
              },
              child: Text("+", style: TextStyle(fontSize: 60)),
            ),
          ),
          ButtonTheme(
            minWidth: 100.0,
            height: 200.0,
            child: RaisedButton(
              color: Colors.yellow,
              onPressed: () {
                setState(() {
                  temp--;
                });
                PublishM(temp.toString(), topic);
              },
              child: Text("-", style: TextStyle(fontSize: 70)),
            ),
          ),
          SizedBox(
            height: 100,
          ),
          Container(
            child: Text(
              temp.toString(),
              style: TextStyle(fontSize: 36),
            ),
          )
        ],
      ),
    );
  }
}
