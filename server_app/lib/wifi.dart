import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WifiPage extends StatefulWidget {
  Map arguments = {};
  WifiPage({Key? key, required this.arguments}) : super(key: key);

  @override
  _WifiPageState createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  Map arguments = {};
  TextEditingController urlController =
      TextEditingController(text: 'https://gorest.co.in/public/v1/users');
  String result = '';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    arguments = widget.arguments;
  }

  @override
  Widget build(BuildContext context) {
    print(arguments);
    return Scaffold(
      appBar: AppBar(
        title: Text("Connect to wifi"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 170,
                child: Column(
                  children: [
                    TextFormField(
                      controller: urlController,
                      cursorColor: Theme.of(context).cursorColor,
                      // initialValue: '',
                      decoration: const InputDecoration(
                        labelText: 'URL',
                        labelStyle: TextStyle(
                          color: Color(0xFF6200EE),
                        ),
                        // suffixIcon: Icon(
                        //   Icons.check_circle,
                        // ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6200EE)),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: () async {
                          print("Hey");
                          connectToNet();
                        },
                        child: const Center(child: Text("Submit"))),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(result)
            ],
          ),
        ),
      ),
    );
  }

  void connectToNet() async {
    print("BEfore request");
    print(urlController.text);
    if (!urlController.text.startsWith('http')) {
      urlController.text = 'http://' + urlController.text;
    }
    http.Response response = await http.get(Uri.parse(urlController.text));
    print("After request");
    print(response.headers);
    print(response.body);
    result = response.body;
    setState(() {});
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
