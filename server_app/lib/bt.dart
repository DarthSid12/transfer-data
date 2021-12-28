// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:socket_io/socket_io.dart';

// class BTSendingPage extends StatefulWidget {
//   const BTSendingPage({Key? key}) : super(key: key);

//   @override
//   _BTSendingPageState createState() => _BTSendingPageState();
// }

// class _BTSendingPageState extends State<BTSendingPage> {
//   BtAdapter flutterbluetoothadapter = BtAdapter();
//   StreamSubscription? _btConnectionStatusListener, _btReceivedMessageListener;
//   String _connectionStatus = "NONE";
//   List<BtDevice> devices = [];
//   String? _recievedMessage;
//   TextEditingController _controller = TextEditingController();
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     Permission.bluetooth.request();
//     Permission.location.request();
//     flutterbluetoothadapter
//         .initBlutoothConnection("20585adb-d260-445e-934b-032a2c8b2e14");
//     flutterbluetoothadapter
//         .checkBluetooth()
//         .then((value) => print(value.toString()));
//     _startListening();
//     _startSocketServer();
//   }

//   _startSocketServer() {
//     var io = Server(options: {
//       'transports': ['websocket']
//     });

//     var nsp = io.of('/some');
//     print("Server");
//     nsp.on('connection', (client) {
//       print("Connected");
//       client.on('msg', (data) {
//         print('data from /some => $data');
//         client.emit('fromServer', "ok 2");
//       });
//     });
//     print("Server 2");
//     io.on('connection', (client) {
//       print("Connected on io");
//       client.on('msg', (data) {
//         print('data from default => $data');
//         client.emit('fromServer', "ok");
//       });
//     });
//     print("Server 3");
//     io.listen(3000);
//   }

//   _startListening() {
//     _btConnectionStatusListener =
//         flutterbluetoothadapter.connectionStatus().listen((dynamic status) {
//       setState(() {
//         _connectionStatus = status.toString();
//       });
//     });
//     _btReceivedMessageListener =
//         flutterbluetoothadapter.receiveMessages().listen((dynamic newMessage) {
//       setState(() {
//         _recievedMessage = newMessage.toString();
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Plugin example app'),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8.0),
//           child: SingleChildScrollView(
//             child: Column(
//               children: <Widget>[
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: <Widget>[
//                     Flexible(
//                       fit: FlexFit.tight,
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: RaisedButton(
//                           onPressed: () async {
//                             await flutterbluetoothadapter.startServer();
//                           },
//                           child: Text('Start Server'),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Flexible(
//                       fit: FlexFit.tight,
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: RaisedButton(
//                           onPressed: () async {
//                             devices =
//                                 await flutterbluetoothadapter.getDevices();
//                             setState(() {});
//                           },
//                           child: Text('LIST DEVICES'),
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//                 Text("STATUS - $_connectionStatus"),
//                 const SizedBox(height: 10),

//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8.0,
//                     vertical: 20,
//                   ),
//                   child: ListView(
//                     shrinkWrap: true,
//                     children: _createDevices(),
//                   ),
//                 ),
//                 Text(
//                   _recievedMessage ?? "NO MESSAGE",
//                   style: TextStyle(fontSize: 24),
//                 ),
//                 const SizedBox(height: 10),

//                 ElevatedButton(
//                   onPressed: () {
//                     if (_recievedMessage != null &&
//                         _recievedMessage!.isNotEmpty &&
//                         _recievedMessage!.toLowerCase().startsWith('{')) {
//                       print("Hi");
//                       Navigator.pushNamed(context, '/wifi',
//                           arguments: jsonDecode(_recievedMessage ?? '{}'));
//                       return;
//                     }
//                     print("No");
//                     ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text("No data received")));
//                   },
//                   child: const Text('Connect to wifi'),
//                 ),
//                 //             Row(
//                 //               children: <Widget>[
//                 //                 Flexible(
//                 //                   flex: 4,
//                 //                   fit: FlexFit.tight,
//                 //                   child: Padding(
//                 //                     padding: const EdgeInsets.all(8.0),
//                 //                     child: TextField(
//                 //                       controller: _controller,
//                 //                       decoration: InputDecoration(hintText: "Write message"),
//                 //                     ),
//                 //                   ),
//                 //                 ),
//                 //                 Flexible(
//                 //                   fit: FlexFit.tight,
//                 //                   child: Padding(
//                 //                     padding: const EdgeInsets.all(8.0),
//                 //                     child: RaisedButton(
//                 //                       onPressed: () {
//                 //                         flutterbluetoothadapter.sendMessage(
//                 //                             jsonEncode(arguments),
//                 //                             sendByteByByte: false);
//                 // //                        flutterbluetoothadapter.sendMessage(".",
//                 // //                            sendByteByByte: true);
//                 //                       },
//                 //                       child: const Text('SEND DATA'),
//                 //                     ),
//                 //                   ),
//                 //                 )
//                 //               ],
//                 //             )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   _createDevices() {
//     if (devices.isEmpty) {
//       return [
//         Center(
//           child: Text("No Paired Devices listed..."),
//         )
//       ];
//     }
//     List<Widget> deviceList = [];
//     devices.forEach((element) {
//       deviceList.add(
//         InkWell(
//           key: UniqueKey(),
//           onTap: () {},
//           child: Container(
//             padding: EdgeInsets.all(4),
//             decoration: BoxDecoration(border: Border.all()),
//             child: Text(
//               element.name.toString(),
//               style: TextStyle(fontSize: 18),
//             ),
//           ),
//         ),
//       );
//     });
//     return deviceList;
//   }
// }
