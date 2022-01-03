import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

class BTSendingPage extends StatefulWidget {
  const BTSendingPage({Key? key}) : super(key: key);

  @override
  _BTSendingPageState createState() => _BTSendingPageState();
}

class _BTSendingPageState extends State<BTSendingPage> {
  String? _recievedMessage;
  List<Device> devices = [];
  Function()? j;
  List<Device> connectedDevices = [];
  late NearbyService nearbyService;
  late StreamSubscription subscription;
  late StreamSubscription receivedDataSubscription;
  TextEditingController _controller = TextEditingController();
  bool isInit = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    nearbyService = NearbyService();
    String devInfo = '';
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      devInfo = androidInfo.model;
    }
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      devInfo = iosInfo.localizedModel;
    }
    await nearbyService.init(
        serviceType: 'mpconn',
        deviceName: devInfo,
        strategy: Strategy.P2P_CLUSTER,
        callback: (isRunning) async {
          if (isRunning) {
            await nearbyService.stopBrowsingForPeers();
            await Future.delayed(const Duration(microseconds: 200));
            await nearbyService.startBrowsingForPeers();
          }
        });
    subscription =
        nearbyService.stateChangedSubscription(callback: (devicesList) {
      devicesList.forEach((element) {
        print(
            " deviceId: ${element.deviceId} | deviceName: ${element.deviceName} | state: ${element.state}");

        if (Platform.isAndroid) {
          if (element.state == SessionState.connected) {
            nearbyService.stopBrowsingForPeers();
          } else {
            nearbyService.startBrowsingForPeers();
          }
        }
      });

      setState(() {
        devices.clear();
        devices.addAll(devicesList);
        connectedDevices.clear();
        connectedDevices.addAll(devicesList
            .where((d) => d.state == SessionState.connected)
            .toList());
      });
    });

    receivedDataSubscription =
        nearbyService.dataReceivedSubscription(callback: (data) {
      print("dataReceivedSubscription: ${jsonEncode(data)}");
      showToast(jsonEncode(data),
          context: context,
          axis: Axis.horizontal,
          alignment: Alignment.center,
          position: StyledToastPosition.bottom);
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    receivedDataSubscription.cancel();
    nearbyService.stopBrowsingForPeers();
    nearbyService.stopAdvertisingPeer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Flexible(
                  //   fit: FlexFit.tight,
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(8.0),
                  //     child: RaisedButton(
                  //       onPressed: () async {
                  //         await flutterbluetoothadapter.startServer();
                  //       },
                  //       child: Text('LISTEN'),
                  //     ),
                  //   ),
                  // ),
                  Flexible(
                    fit: FlexFit.tight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RaisedButton(
                        onPressed: () async {
                          // devices = await flutterbluetoothadapter.getDevices();
                          setState(() {});
                        },
                        child: Text('LIST DEVICES'),
                      ),
                    ),
                  )
                ],
              ),
              // Text("STATUS - $_connectionStatus"),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 20,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: _createDevices(),
                ),
              ),
              // Text(
              //   _recievedMessage ?? "NO MESSAGE",
              //   style: TextStyle(fontSize: 24),
              // ),
              Row(
                children: <Widget>[
                  // Flexible(
                  //   flex: 4,
                  //   fit: FlexFit.tight,
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(8.0),
                  //     child: TextField(
                  //       controller: _controller,
                  //       decoration: InputDecoration(hintText: "Write message"),
                  //     ),
                  //   ),
                  // ),
                  Flexible(
                    fit: FlexFit.tight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RaisedButton(
                        onPressed: () {
                          // flutterbluetoothadapter.sendMessage(
                          //     jsonEncode(arguments),
                          //     sendByteByByte: false);
                          //                        flutterbluetoothadapter.sendMessage(".",
                          //                            sendByteByByte: true);
                        },
                        child: const Text('SEND DATA'),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  _createDevices() {
    // if (devices.isEmpty) {
    //   return [
    //     Center(
    //       child: Text("No Paired Devices listed..."),
    //     )
    //   ];
    // }
    List<Widget> deviceList = [];
    // devices.forEach((element) {
    //   deviceList.add(
    //     InkWell(
    //       key: UniqueKey(),
    //       onTap: () {
    //         flutterbluetoothadapter.startClient(devices.indexOf(element), true);
    //       },
    //       child: Container(
    //         padding: EdgeInsets.all(4),
    //         decoration: BoxDecoration(border: Border.all()),
    //         child: Text(
    //           element.name.toString(),
    //           style: TextStyle(fontSize: 18),
    //         ),
    //       ),
    //     ),
    //   );
    // });
    return deviceList;
  }
}
