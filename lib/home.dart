// ignore_for_file: avoid_print, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_seria_changed/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_settings/open_settings.dart';

final List<BluetoothDiscoveryResult> _devicesList = [];
BluetoothConnection? bluetoothConnection;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool switchValue = false;
  String isconnected = "";

  @override
  void initState () {
    super.initState();
    setState(() {
      if(switchValue == true){
        isconnected = "Connected !";
      }else{
        isconnected = "Not Connected !";
      }
    });
  }

  void _disconnect() {
    if (bluetoothConnection != null) {
      bluetoothConnection!.dispose();
      bluetoothConnection = null;
      print('Disconnected');
    }
  }

  void _sendData(String data) {
    try {
      if (bluetoothConnection != null) {
        bluetoothConnection!.output.add(Uint8List.fromList(data.codeUnits));
        bluetoothConnection!.output.allSent.then((_) {
          print('Data sent: $data');
        });
      } else {
        print("Not connected");
        setState(() {
          switchValue = false;
        });
      }
    } catch (error) {
      if (error is StateError) {
        print("Not paired");
      } else {
        print('Error sending data: $error');
      }
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    print("Connect to device");
    try {
      _disconnect();
      final BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      print('Connected to ${device.name}');
      print(device.name);
      Navigator.of(context).pop();
      bluetoothConnection = connection;
      connection.input!.listen((Uint8List data) {
        setState(() {
          switchValue = true;
        });
        print("listening:");
        print(data);
      }).onDone(() {
        setState(() {
          switchValue = false;
        });
        print('Device Disconnected.');
        bluetoothConnection = null;
      });
    } catch (error) {
      setState(() {
        switchValue = false;
      });
      print('Error connecting to ${device.name}: $error');
    }
  }

  Future<void> _askUserToEnableBluetooth(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bluetooth is turned off'),
          content: const Text('Please turn on Bluetooth and try again to continue.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                OpenSettings.openBluetoothSetting();
                setState(() {});
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkBluetoothStatus(BuildContext context) async {
    bool isEnabled = (await FlutterBluetoothSerial.instance.isEnabled) ?? false;
    if (!isEnabled) {
      print("Blutooth OFF");
      _askUserToEnableBluetooth(context); // Pass context here
    } else {
      print("Blutooth ON");
      _startDiscovery(context);
    }
  }

  void _startDiscovery(BuildContext context) async {
    print("Started");
    setState(() {
      _devicesList.clear();
      print("Cleared");
    });

    await FlutterBluetoothSerial.instance.cancelDiscovery();

    FlutterBluetoothSerial.instance.startDiscovery().listen((device) {
      setState(() {
        print("Added");
        _devicesList.add(device);
      });
    });
  }

  Future<void> requestBluetoothScanPermission(BuildContext context) async {
    print('Check2');
    var status = await Permission.bluetoothScan.status;
    if (status.isDenied) {
      PermissionStatus result = await Permission.bluetoothScan.request();
      if (result.isGranted) {
        print('Granted');
        _startDiscovery(context);
      } else {
        print("Not granted");
      }
    } else if (status.isPermanentlyDenied) {
      print('Bluetooth settings');
      openAppSettings();
    } else {
      print('Bluetooth check');
      _checkBluetoothStatus(context);
    }
  }

  Future<void> _showCustomDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        print("Check1");
        requestBluetoothScanPermission(context);
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discovered Devices:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _devicesList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_devicesList[index].device.name ?? 'Unknown'),
                          subtitle: Text(_devicesList[index].device.address),
                          trailing: _devicesList[index].device.isBonded
                              ? const Icon(Icons.bluetooth_connected, color: Colors.green)
                              : const Icon(Icons.bluetooth, color: Colors.grey),
                          onTap: () {
                            _connectToDevice(_devicesList[index].device);
                          },
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 53.0,
            left: 25.0,
            right: 0,
            child: Center(
              child: Text(
                isconnected,
                style: const TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 35.0, top: 50.0),
              child: Transform.scale(
                scale: 1.5,
                child: Switch(
                  value: switchValue,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0,right: 35.0,),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.only(top: 12.0, right: 23.0, left: 23.0, bottom: 12.0),
                  backgroundColor: Colors.black12, // Set background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0), // Set border radius
                    side: const BorderSide(color: Colors.grey,width: 3.0,), // Set border color
                  ),
                  elevation: 4, // Add elevation
                ),
                onPressed: () {
                  _showCustomDialog(context);
                  print("Check");
                },
                child: const Text(
                  "Pair",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 25.0,),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(10.0,), // Set padding to zero
                      ),
                      onPressed: () {
                        // Handle forward button press
                      },
                      child: Image.asset(
                        'assets/left.png',
                        width: 100.0, 
                        height: 100.0,
                      ),
                    ),
                    const SizedBox(width: 35.0,),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(10.0,), // Set padding to zero
                      ),
                      onPressed: () {
                        // Handle rightward button press
                      },
                      child: Image.asset(
                        'assets/right.png',
                        width: 100.0, 
                        height: 100.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25.0,),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 200.0,top: 160.0,bottom: 25.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(10.0,), // Set padding to zero
                ),
                onPressed: () {
                  // Handle brake button press
                },
                child: Image.asset(
                  'assets/brake.png',
                  width: 100.0, 
                  height: 100.0,
                ),
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(10.0,), // Set padding to zero
                      ),
                      onPressed: () {
                        // Handle forward button press
                      },
                      child: Image.asset(
                        'assets/up.png',
                        width: 100.0, 
                        height: 100.0,
                      ),
                    ),
                    const SizedBox(height: 10.0,),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(10.0,), // Set padding to zero
                      ),
                      onPressed: () {
                        // Handle rightward button press
                      },
                      child: Image.asset(
                        'assets/down.png',
                        width: 100.0, 
                        height: 100.0,
                      ),
                    ),
                    const SizedBox(height: 25.0,),
                  ],
                ),
                const SizedBox(width: 20.0,),
              ],
            ),
          )
        ],
      ),
    );
  }
}
