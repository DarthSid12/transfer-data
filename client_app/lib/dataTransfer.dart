import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info/device_info.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

// class Home extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           Expanded(
//             child: InkWell(
//               onTap: () {
//                 Navigator.pushNamed(context, 'browser');
//               },
//               child: Container(
//                 color: Colors.red,
//                 child: Center(
//                     child: Text(
//                   'BROWSER',
//                   style: TextStyle(color: Colors.white, fontSize: 40),
//                 )),
//               ),
//             ),
//           ),
//           Expanded(
//             child: InkWell(
//               onTap: () {
//                 Navigator.pushNamed(context, 'advertiser');
//               },
//               child: Container(
//                 color: Colors.green,
//                 child: Center(
//                     child: Text(
//                   'ADVERTISER',
//                   style: TextStyle(color: Colors.white, fontSize: 40),
//                 )),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class DataTransferPage extends StatefulWidget {
  @override
  _DataTransferPageState createState() => _DataTransferPageState();
}

class _DataTransferPageState extends State<DataTransferPage> {
  List<Device> devices = [];
  List<Device> connectedDevices = [];
  late NearbyService nearbyService;
  late StreamSubscription subscription;
  late StreamSubscription receivedDataSubscription;

  bool isInit = false;
  Map arguments = {};
  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    arguments = ModalRoute.of(context)!.settings.arguments as Map;
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
    return Scaffold(
        appBar: AppBar(
          title: Text("Browser"),
        ),
        backgroundColor: Colors.white,
        body: ListView.builder(
            itemCount: getItemCount(),
            itemBuilder: (context, index) {
              final device = devices[index];
              return Container(
                margin: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: GestureDetector(
                          onTap: () => _onTabItemListener(device),
                          child: Column(
                            children: [
                              Text(device.deviceName),
                              Text(
                                getStateName(device.state),
                                style: TextStyle(
                                    color: getStateColor(device.state)),
                              ),
                            ],
                            crossAxisAlignment: CrossAxisAlignment.start,
                          ),
                        )),
                        // Request connect
                        GestureDetector(
                          onTap: () => _onButtonClicked(device),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 8.0),
                            padding: EdgeInsets.all(8.0),
                            height: 35,
                            width: 100,
                            color: getButtonColor(device.state),
                            child: Center(
                              child: Text(
                                getButtonStateName(device.state),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey,
                    )
                  ],
                ),
              );
            }));
  }

  String getStateName(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
        return "disconnected";
      case SessionState.connecting:
        return "waiting";
      default:
        return "connected";
    }
  }

  String getButtonStateName(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
      case SessionState.connecting:
        return "Connect";
      default:
        return "Disconnect";
    }
  }

  Color getStateColor(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
        return Colors.black;
      case SessionState.connecting:
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  Color getButtonColor(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
      case SessionState.connecting:
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  _onTabItemListener(Device device) {
    if (device.state == SessionState.connected) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            final myController = TextEditingController();
            return AlertDialog(
              title: Text("Send message"),
              content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.08,
                child: Column(
                  children: [
                    Text("Name:" + arguments['name']),
                    Text("Pass:" + arguments['pass']),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text("Send"),
                  onPressed: () {
                    nearbyService.sendMessage(
                        device.deviceId, jsonEncode(arguments));
                    myController.text = '';
                  },
                )
              ],
            );
          });
    }
  }

  int getItemCount() {
    return devices.length;
  }

  _onButtonClicked(Device device) {
    switch (device.state) {
      case SessionState.notConnected:
        nearbyService.invitePeer(
          deviceID: device.deviceId,
          deviceName: device.deviceName,
        );
        break;
      case SessionState.connected:
        nearbyService.disconnectPeer(deviceID: device.deviceId);
        break;
      case SessionState.connecting:
        break;
    }
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
        strategy: Strategy.Wi_Fi_P2P, // Wi_Fi_P2P, P2P_POINT_TO_POINT, P2P_STAR, P2P_CLUSTER ?
        callback: (isRunning) async {
          if (isRunning) {
            // if (widget.deviceType == DeviceType.browser) {
            await nearbyService.stopBrowsingForPeers();
            await Future.delayed(Duration(microseconds: 200));
            await nearbyService.startBrowsingForPeers();
            // } else {
            //   await nearbyService.stopAdvertisingPeer();
            //   await nearbyService.stopBrowsingForPeers();
            //   await Future.delayed(Duration(microseconds: 200));
            //   await nearbyService.startAdvertisingPeer();
            //   await nearbyService.startBrowsingForPeers();
            // }
          }
        });
    subscription =
        nearbyService.stateChangedSubscription(callback: (devicesList) {
      devicesList.forEach((element) {
//Works doesnt crash server app but doesnt get a response connection sucessful from server
        /*
        if (element.deviceName == "5TdXcH9YdZCOC2iCfN7j") {
          if (element.state == SessionState.connected) {
            //after auto connect, now auto send
            print("*** Auto sending credentials: " + jsonEncode(arguments));
            nearbyService.sendMessage(element.deviceId, jsonEncode(arguments));
          } else {
            print("** Auto connecting to: 5TdXcH9YdZCOC2iCfN7j");
            _onButtonClicked(element);
          }
        }
*/
        //crashes server app but it connects server to to wIFI
        /*if (element.deviceName == "5TdXcH9YdZCOC2iCfN7j") {
          if (element.state == SessionState.connected) {
            print("** Auto connecting to: 5TdXcH9YdZCOC2iCfN7j");
            print("*** Auto sending credentials: " + jsonEncode(arguments));
            nearbyService.sendMessage(element.deviceId, jsonEncode(arguments));
          } else {
            _onButtonClicked(element);
          }
        }
        */


        /*if(element.deviceName == "5TdXcH9YdZCOC2iCfN7j"){
          print("** Auto connecting to: 5TdXcH9YdZCOC2iCfN7j");
          _onButtonClicked(element);
          //after auto connect, now auto send
          print("*** Auto sending credentials: "+jsonEncode(arguments));
          nearbyService.sendMessage(element.deviceId, jsonEncode(arguments));
        }*/
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
}