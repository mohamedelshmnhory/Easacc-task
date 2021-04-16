import 'package:easacc_task/pages/login.dart';
import 'package:easacc_task/pages/webView.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:ping_discover_network/ping_discover_network.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi/wifi.dart';

class Screen2 extends StatefulWidget {
  @override
  _Screen2State createState() => _Screen2State();
}

class _Screen2State extends State<Screen2> {
  User user = FirebaseAuth.instance.currentUser;
  TextEditingController textCont = TextEditingController();
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List list = [];
  var selectedUser;
  static const port = 80;
  int found = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    textCont.text = "https://flutter.dev";
    getDevices();
  }

  Future getDevices() async {
    // Start scanning
    flutterBlue.startScan(timeout: Duration(seconds: 4));
    var subscription = flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        print('${r.device.type} found! rssi: ${r.rssi}');
        list.add('Found device: ${r.device.id}');
      }
    });
    final String ip = await Wifi.ip;
    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    final stream = NetworkAnalyzer.discover2(
      subnet,
      port,
      timeout: Duration(milliseconds: 5000),
    );
    stream.listen((NetworkAddress address) {
      if (address.exists) {
        found++;
        list.add('Found device: ${address.ip}');
        print('Found device: ${address.ip}:$port');
      }
    }).onDone(() {
      subscription.cancel();
      flutterBlue.stopScan();
      setState(() {
        loading = false;
      });
      print('Finish. Found $found device(s)');
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(user.photoURL),
                ),
                Text(
                  user.displayName,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: 5,
                )
              ],
            ),
          ),
          actions: [
            IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  FirebaseAuth.instance.signOut();
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.remove('email');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return Login();
                      },
                    ),
                  );
                })
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                    keyboardType: TextInputType.url,
                    controller: textCont,
                  )),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return WebViewExample(textCont.text);
                          },
                        ),
                      );
                    },
                    child: Text("GO"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: loading
                    ? CircularProgressIndicator()
                    : DropdownButton(
                        hint: Text('Devices'),
                        value: selectedUser,
                        onChanged: (value) {
                          setState(() {
                            selectedUser = value;
                          });
                        },
                        items: list.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Row(
                              children: <Widget>[
                                Text(
                                  item,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
