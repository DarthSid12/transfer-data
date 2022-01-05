import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections_example/dataTransfer.dart';
import 'package:flutter_nearby_connections_example/wifi.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';
// import 'package:wifi_configuration_2/wifi_configuration_2.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => const HomePage(),
      '/wifi': (context) => const WifiPage(),
      '/bt': (context) => DataTransferPage(),
    },
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  WifiNetwork? wifiNetwork;
  String wifiPassword = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // startClient();
    requestPerms();
  }

  void requestPerms() async {
    await [Permission.bluetooth, Permission.location].request();
    // if (await Permission.location.isDenied) {
    //   showToast("Location perms were denied");
    // } else if (await Permission.location.isPermanentlyDenied) {
    //   showToast("Location perms were permanently denied");
    // }
    // else {}
    //   showToast("Location perms were granted");
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Data Sender app"),
        ),
        body: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    Map arguments =
                    (await Navigator.pushNamed(context, '/wifi')) as Map;
                    wifiNetwork = arguments['wifiNetwork'];
                    wifiPassword = arguments['pass'];
                  },
                  child: const Center(child: Text("Put wifi credentials")),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (wifiNetwork == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Select wifi first")));
                      return;
                    }
                    Navigator.pushNamed(context, '/bt', arguments: {
                      'name': wifiNetwork!.ssid,
                      'pass': wifiPassword,
                    });
                  },
                  child: const Center(child: Text("Send data")),
                ),
              ],
            ),
          ),
        ));
  }
}