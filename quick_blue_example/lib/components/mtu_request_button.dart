import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';
import 'package:quick_blue_example/extensions/widget.dart';

class MtuRequestWidget extends StatefulWidget {
  final String deviceId;

  const MtuRequestWidget(this.deviceId);

  @override
  _MtuRequestWidgetState createState() => _MtuRequestWidgetState();
}

class _MtuRequestWidgetState extends State<MtuRequestWidget> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'MTU value',
          ),
          keyboardType: TextInputType.number,
        ),
        OutlinedButton(
          onPressed: () {
            QuickBlue.requestMtu(widget.deviceId, int.parse(_controller.text));
          },
          child: Text('Request MTU'),
        ),
      ].spaced(),
    );
  }
}
