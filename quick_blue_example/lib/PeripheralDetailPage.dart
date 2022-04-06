import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';

String gssUuid(String code) => '0000$code-0000-1000-8000-00805f9b34fb';

final GSS_SERV__BATTERY = gssUuid('180f');
final GSS_CHAR__BATTERY_LEVEL = gssUuid('2a19');

const WOODEMI_SUFFIX = 'ba5e-f4ee-5ca1-eb1e5e4b1ce0';

const WOODEMI_SERV__COMMAND = '57444d01-$WOODEMI_SUFFIX';
const WOODEMI_CHAR__COMMAND_REQUEST = '57444e02-$WOODEMI_SUFFIX';
const WOODEMI_CHAR__COMMAND_RESPONSE = WOODEMI_CHAR__COMMAND_REQUEST;

const WOODEMI_MTU_WUART = 247;

class PeripheralDetailPage extends StatefulWidget {
  final String deviceId;

  PeripheralDetailPage(this.deviceId);

  @override
  State<StatefulWidget> createState() {
    return _PeripheralDetailPageState();
  }
}

class _PeripheralDetailPageState extends State<PeripheralDetailPage> {
  bool isConnected = false;
  bool parseValue = false;
  List<BlueServices> discoveredServices = [];
  var readValues = [];

  @override
  void initState() {
    super.initState();
    QuickBlue.setConnectionHandler(_handleConnectionChange);
    QuickBlue.setServiceHandler(_handleServiceDiscovery);
    QuickBlue.setValueHandler(_handleValueChange);
  }

  @override
  void dispose() {
    super.dispose();
    QuickBlue.setValueHandler(null);
    QuickBlue.setServiceHandler(null);
    QuickBlue.setConnectionHandler(null);
  }

  void _handleConnectionChange(String deviceId, BlueConnectionState state) {
    print('_handleConnectionChange $deviceId, ${state.value}');
    setState(() {
      if (deviceId == widget.deviceId) {
        isConnected = (state == BlueConnectionState.connected);
      }
    });
  }

  void _handleServiceDiscovery(
      String deviceId, String serviceId, BlueServices blueService) {
    print('_handleServiceDiscovery $deviceId, $serviceId');
    setState(() {
      if (!discoveredServices
          .any((e) => e.serviceId == blueService.serviceId)) {
        discoveredServices.add(blueService);
      }
    });
  }

  void _handleValueChange(
      String deviceId, String characteristicId, Uint8List value) {
    String s = new String.fromCharCodes(value);
    String data =
        parseValue ? s + '\n' + 'raw :  ${value.toString()}' : value.toString();
    print('_handleValueChange $deviceId, $characteristicId, $s');
    setState(() {
      readValues.add(data);
    });
  }

  void onServiceTap(String serviceID) {}

  void discoverServices() {
    QuickBlue.discoverServices(widget.deviceId);
  }

  final serviceUUID = TextEditingController(text: GSS_SERV__BATTERY);
  final characteristicUUID =
      TextEditingController(text: GSS_CHAR__BATTERY_LEVEL);
  final binaryCode = TextEditingController(
      text: hex.encode([0x01, 0x0A, 0x00, 0x00, 0x00, 0x01]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Peripheral Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      child: Text('Connect'),
                      onPressed: () {
                        QuickBlue.connect(widget.deviceId);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: ElevatedButton(
                        child: Text('Connected : $isConnected'),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          primary: isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      child: Text('Disconnect'),
                      onPressed: () {
                        QuickBlue.disconnect(widget.deviceId);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: serviceUUID,
                decoration: InputDecoration(
                  labelText: 'ServiceUUID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: characteristicUUID,
                decoration: InputDecoration(
                  labelText: 'CharacteristicUUID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: binaryCode,
                decoration: InputDecoration(
                  labelText: 'Binary code',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Divider(),
            CheckboxListTile(
                title: Text('Parse Value'),
                value: parseValue,
                onChanged: (value) {
                  setState(() {
                    parseValue = value ?? false;
                  });
                }),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: Text('send'),
                  onPressed: () {
                    var value = Uint8List.fromList(hex.decode(binaryCode.text));
                    print(value);
                    QuickBlue.writeValue(
                        widget.deviceId,
                        serviceUUID.text,
                        characteristicUUID.text,
                        value,
                        BleOutputProperty.withResponse);
                  },
                ),
                ElevatedButton(
                  child: Text('Read Value'),
                  onPressed: () async {
                    await QuickBlue.readValue(widget.deviceId, serviceUUID.text,
                        characteristicUUID.text);
                  },
                ),
                ElevatedButton(
                  child: Text('Request Mtu'),
                  onPressed: () async {
                    var mtu = await QuickBlue.requestMtu(
                        widget.deviceId, WOODEMI_MTU_WUART);
                    print('requestMtu $mtu');
                  },
                ),
              ],
            ),
            Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: readValues.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          readValues.removeAt(index);
                        });
                      },
                      title: Text(readValues[index]),
                      trailing: Icon(Icons.clear),
                    ),
                  ),
                );
              },
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      child: Text('discoverServices'),
                      onPressed: () {
                        discoverServices();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: ElevatedButton(
                        child: Text('Services'),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          primary: Colors.grey,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      child: Text('setNotifiable'),
                      onPressed: () {
                        QuickBlue.setNotifiable(
                            widget.deviceId,
                            serviceUUID.text,
                            characteristicUUID.text,
                            BleInputProperty.indication);
                      },
                    ),
                  ],
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: discoveredServices.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: ExpandablePanel(
                      header: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_forward_ios),
                            Expanded(
                                child:
                                    Text(discoveredServices[index].serviceId)),
                          ],
                        ),
                      ),
                      collapsed: SizedBox(),
                      expanded: Column(
                        children: discoveredServices[index]
                            .characteristics
                            .map((e) => Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.arrow_right_outlined),
                                          Expanded(
                                              child: Text(e.characteristicId)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text("Properties : "),
                                          if (e.isWritableWithResponse)
                                            Text(' WriteWithResponse ,'),
                                          if (e.isReadable) Text(' Read ,'),
                                          if (e.isWritableWithoutResponse)
                                            Text(' WriteWithoutResponse ,'),
                                          if (e.isNotifiable)
                                            Text(' Notifiable ,'),
                                          if (e.isIndicatable)
                                            Text(' Indicatable '),
                                        ],
                                      )
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),

                    // ListTile(
                    //   onTap: () {
                    //     // onServiceTap(discoveredServices[index]);
                    //     setState(() {
                    //       discoveredServices.removeAt(index);
                    //     });
                    //   },
                    //   title: Text(discoveredServices[index]),
                    //   trailing: Icon(Icons.clear),
                    // ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
