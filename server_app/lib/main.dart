import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info/device_info.dart';
import 'package:flutter_nearby_connections_example/wifi.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:wifi_configuration_2/wifi_configuration_2.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: DevicesListScreen());
  }
}

enum DeviceType { advertiser, browser }

class DevicesListScreen extends StatefulWidget {
  @override
  _DevicesListScreenState createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  List<Device> devices = [];
  List<Device> connectedDevices = [];
  Device? selectedDevice;
  late NearbyService nearbyService;
  late StreamSubscription subscription;
  late StreamSubscription receivedDataSubscription;

  bool isInit = false;

  @override
  void initState() {
    super.initState();
    init();
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
          title: Text("Server App"),
        ),
        backgroundColor: Colors.white,
        body: ListView.builder(
            itemCount: getItemCount(),
            itemBuilder: (context, index) {
              selectedDevice = connectedDevices[index];
              return Container(
                margin: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: GestureDetector(
                          onTap: () => _onTabItemListener(selectedDevice!),
                          child: Column(
                            children: [
                              Text(selectedDevice!.deviceName),
                              Text(
                                getStateName(selectedDevice!.state),
                                style: TextStyle(
                                    color:
                                        getStateColor(selectedDevice!.state)),
                              ),
                            ],
                            crossAxisAlignment: CrossAxisAlignment.start,
                          ),
                        )),
                        // Request connect
                        GestureDetector(
                          onTap: () => _onButtonClicked(selectedDevice!),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 8.0),
                            padding: EdgeInsets.all(8.0),
                            height: 35,
                            width: 100,
                            color: getButtonColor(selectedDevice!.state),
                            child: Center(
                              child: Text(
                                getButtonStateName(selectedDevice!.state),
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
              content: TextField(controller: myController),
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
                        device.deviceId, myController.text);
                    myController.text = '';
                  },
                )
              ],
            );
          });
    }
  }

  int getItemCount() {
    return connectedDevices.length;
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
        deviceName: "5TdXcH9YdZCOC2iCfN7j",
        strategy: Strategy.Wi_Fi_P2P, // Wi_Fi_P2P, P2P_POINT_TO_POINT, P2P_STAR, P2P_CLUSTER ?
        callback: (isRunning) async {
          if (isRunning) {
            await nearbyService.stopAdvertisingPeer();
            await nearbyService.stopBrowsingForPeers();
            await Future.delayed(Duration(microseconds: 200));
            await nearbyService.startAdvertisingPeer();
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
        nearbyService.dataReceivedSubscription(callback: (data) async {
      print("dataReceivedSubscription: ${jsonEncode(data)}");
      print("Message:" + data['message']);
      nearbyService.sendMessage(
          selectedDevice!.deviceId, "Received: "+data['message'].toString());
      Map arguments = jsonDecode(data['message'].toString());

      WifiConnectionStatus status = await WifiConfiguration().connectToWifi(
          arguments['name'], arguments['pass'], arguments['name']);
      if (status == WifiConnectionStatus.connected ||
          status == WifiConnectionStatus.alreadyConnected) {
        nearbyService.sendMessage(
            selectedDevice!.deviceId, "Connection succesful");
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => WifiPage(arguments: arguments)));
      } else if (status == WifiConnectionStatus.notConnected) {
        nearbyService.sendMessage(
            selectedDevice!.deviceId, "Connection Failed");
        print("There was an error connecting");
      }
      // showToast(jsonEncode(data),
      //     context: context,
      //     axis: Axis.horizontal,
      //     alignment: Alignment.center,
      //     position: StyledToastPosition.bottom);
    });
  }
}
