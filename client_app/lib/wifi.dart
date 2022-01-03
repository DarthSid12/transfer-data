import 'package:flutter/material.dart';
// import 'package:wifi_configuration_2/wifi_configuration_2.dart';
import 'package:wifi_iot/wifi_iot.dart';

class WifiPage extends StatefulWidget {
  const WifiPage({Key? key}) : super(key: key);

  @override
  _WifiPageState createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  // WifiConfiguration wifiConfiguration = WifiConfiguration();
  List<WifiNetwork> wifiNetworks = [];
  WifiNetwork? selectedNetwork;

  @override
  void initState() {
    super.initState();
    availableDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select wifi"),
        actions: [
          InkWell(
              onTap: () {
                availableDevices();
              },
              child: Icon(Icons.search)),
          SizedBox(
            width: 10,
          )
        ],
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: ListView(
          children: wifiNetworks.map<Widget>((e) {
            return ListTile(
              title: Text(e.ssid ?? "Unknown SSID"),
              onTap: () async {
                selectedNetwork = e;
                await showDialog(
                    context: context,
                    builder: (context) {
                      TextEditingController passController =
                          TextEditingController();
                      return AlertDialog(
                        title:
                            Text("Enter Password for ${selectedNetwork!.ssid}"),
                        content: SizedBox(
                          height: 170,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: passController,
                                cursorColor: Theme.of(context).cursorColor,
                                // initialValue: '',
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: TextStyle(
                                    color: Color(0xFF6200EE),
                                  ),
                                  // suffixIcon: Icon(
                                  //   Icons.check_circle,
                                  // ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFF6200EE)),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    Navigator.pop(context, {
                                      "wifiNetwork": selectedNetwork,
                                      "pass": passController.text,
                                    });
                                  },
                                  child: Center(child: Text("Submit")))
                            ],
                          ),
                        ),
                      );
                    });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void availableDevices() async {
    wifiNetworks = [];
    // print(await wifiConfiguration.isConnectedToWifi('hemant'));
    // wifiConfiguration.enableWifi().then((value) async {
    //   print(await wifiConfiguration.isWifiEnabled());
    //   wifiNetworks = await wifiConfiguration.getWifiList() as List<WifiNetwork>;
    //   print(wifiNetworks.map((e) => e.ssid));
    //   setState(() {});
    // });
    WiFiForIoTPlugin.loadWifiList().then((value) {
      print(value);
      wifiNetworks = value;
      setState(() {});
    });
  }
}
