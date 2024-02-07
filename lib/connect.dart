// ignore_for_file: avoid_print, use_build_context_synchronously, unnecessary_brace_in_string_interps
import 'dart:async';
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
  bool _isLoading = false;
  Timer? _timer1;
  Timer? _timer2;
  Timer? _timer3;
  Timer? _timer4;
  Timer? _timer5;

  @override
  void initState() {
    super.initState();
    setState(() {
      if (switchValue == false || bluetoothConnection == null) {
        isconnected = "Not Connected !";
      } else {
        isconnected = "Connected !";
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

  Future<void>  _sendData(String data) async {
    print("Sending Data : ${data}");
    try {
      if (bluetoothConnection != null) {
        bluetoothConnection!.output.add(Uint8List.fromList(data.codeUnits));
        await bluetoothConnection!.output.allSent.then((_) {
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
      final BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      print('Connected to ${device.name}');
      print(device.name);
      setState(() {
        switchValue = true;
        isconnected = "Connected !";
      });
      bluetoothConnection = connection;
      Navigator.of(context).pop();
      connection.input!.listen((Uint8List data) {
        print("listening:");
        print(data);
      }).onDone(() {
        setState(() {
          switchValue = false;
          if (switchValue == false || bluetoothConnection == null) {
            isconnected = "Not Connected !";
          } else {
            isconnected = "Connected !";
          }
        });
        print('Device Disconnected.');
        bluetoothConnection = null;
      });
    } catch (error) {
      print('Error connecting to ${device.name}: $error');
      Navigator.of(context).pop();
    }
  }

  Future<void> _askUserToEnableBluetooth(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bluetooth is turned off'),
          content:
              const Text('Please turn on Bluetooth and try again to continue.'),
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

  void _startDiscovery(BuildContext context) async {
    print("Started");
    setState(() {
      _isLoading = true;
      _devicesList.clear();
      print("Cleared");
    });
    await FlutterBluetoothSerial.instance.cancelDiscovery();

    FlutterBluetoothSerial.instance.startDiscovery().listen((device) {
      setState(() {
        print("Added");
        _devicesList.add(device);
      });
    }).onDone(() {
      print("Scanning completed");
      setState(() {
        _isLoading = false;
      });
      _showCustomDialog(context);
    });
  }

  Future<void> _checkBluetoothStatus(BuildContext context) async {
    print('Check2');
    bool isEnabled = (await FlutterBluetoothSerial.instance.isEnabled) ?? false;
    if (!isEnabled) {
      print("Blutooth OFF");
      _askUserToEnableBluetooth(context);
    } else {
      print("Blutooth ON");
      _startDiscovery(context);
    }
  }

  Future<void> requestBluetoothScanPermission(BuildContext context) async {
    print("Check1");
    var status = await Permission.bluetoothScan.status;
    if (status.isDenied) {
      PermissionStatus result = await Permission.bluetoothScan.request();
      if (result.isGranted) {
        print('Granted, Bluetooth check');
        _checkBluetoothStatus(context);
      } else {
        print("Not granted");
      }
    } else if (status.isPermanentlyDenied) {
      print('Request settings');
      openAppSettings();
    } else {
      print('All ready Granted, Bluetooth check');
      _checkBluetoothStatus(context);
    }
  }

  void _showCustomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                    child: _devicesList.isEmpty
                        ? const Center(
                            child: Text(
                            'No devices !',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 20,
                            ),
                          ))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _devicesList.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(_devicesList[index].device.name ??
                                    'Unknown'),
                                subtitle:
                                    Text(_devicesList[index].device.address),
                                trailing: _devicesList[index].device.isBonded
                                    ? const Icon(Icons.bluetooth_connected,
                                        color: Colors.green)
                                    : const Icon(Icons.bluetooth,
                                        color: Colors.grey),
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
              padding: const EdgeInsets.only(
                top: 50.0,
                right: 35.0,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.only(
                      top: 12.0, right: 23.0, left: 23.0, bottom: 12.0),
                  backgroundColor: Colors.black12, // Set background color
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(30.0), // Set border radius
                    side: const BorderSide(
                      color: Colors.grey,
                      width: 3.0,
                    ), // Set border color
                  ),
                  elevation: 4, // Add elevation
                ),
                onPressed: () async {
                  await requestBluetoothScanPermission(context);
                  print("Connected");
                },
                child: _isLoading
              ? const SizedBox(
                  width: 33,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : const Text(
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
                    const SizedBox(
                      width: 25.0,
                    ),
                    GestureDetector(
                      onLongPressStart: (_) {
                        _timer1 = Timer.periodic(
                            const Duration(milliseconds: 300), (_) {
                          setState(() {
                            if (switchValue == false ||
                                bluetoothConnection == null) {
                              switchValue = false;
                              isconnected = "Not Connected !";
                            } else {
                              isconnected = "Connected !";
                            }
                          });
                          _sendData("left");
                        });
                      },
                      onLongPressEnd: (_) {
                        _timer1?.cancel();
                        setState(() {});
                      },
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(10.0),
                        ),
                        onPressed: () {
                          setState(() {
                            if (switchValue == false ||
                                bluetoothConnection == null) {
                              switchValue = false;
                              isconnected = "Not Connected !";
                            } else {
                              isconnected = "Connected !";
                            }
                          });
                          _sendData("left");
                        },
                        child: Image.asset(
                          'assets/left.png',
                          width: 100.0,
                          height: 100.0,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 35.0,
                    ),
                    GestureDetector(
                      onLongPressStart: (_) {
                        _timer2 = Timer.periodic(
                            const Duration(milliseconds: 300), (_) {
                          setState(() {
                            if (switchValue == false ||
                                bluetoothConnection == null) {
                              switchValue = false;
                              isconnected = "Not Connected !";
                            } else {
                              isconnected = "Connected !";
                            }
                          });
                          _sendData("right");
                        });
                      },
                      onLongPressEnd: (_) {
                        _timer2?.cancel();
                        setState(() {});
                      },
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(10.0),
                        ),
                        onPressed: () {
                          setState(() {
                            if (switchValue == false ||
                                bluetoothConnection == null) {
                              switchValue = false;
                              isconnected = "Not Connected !";
                            } else {
                              isconnected = "Connected !";
                            }
                          });
                          _sendData("right");
                        },
                        child: Image.asset(
                          'assets/right.png',
                          width: 100.0,
                          height: 100.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 25.0,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding:
                  const EdgeInsets.only(right: 200.0, top: 160.0, bottom: 25.0),
              child: GestureDetector(
                onLongPressStart: (_) {
                  _timer3 =
                      Timer.periodic(const Duration(milliseconds: 300), (_) {
                    setState(() {
                      if (switchValue == false || bluetoothConnection == null) {
                        switchValue = false;
                        isconnected = "Not Connected !";
                      } else {
                        isconnected = "Connected !";
                      }
                    });
                    _sendData("brake");
                  });
                },
                onLongPressEnd: (_) {
                  _timer3?.cancel();
                  setState(() {});
                },
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(10.0),
                  ),
                  onPressed: () {
                    setState(() {
                      if (switchValue == false || bluetoothConnection == null) {
                        switchValue = false;
                        isconnected = "Not Connected !";
                      } else {
                        isconnected = "Connected !";
                      }
                    });
                    _sendData("brake");
                  },
                  child: Image.asset(
                    'assets/brake.png',
                    width: 100.0,
                    height: 100.0,
                  ),
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
                    GestureDetector(
                      onLongPressStart: (_) {
                        _timer4 = Timer.periodic(
                            const Duration(milliseconds: 300), (_) {
                          setState(() {
                            if (switchValue == false ||
                                bluetoothConnection == null) {
                              switchValue = false;
                              isconnected = "Not Connected !";
                            } else {
                              isconnected = "Connected !";
                            }
                          });
                          _sendData("forward");
                        });
                      },
                      onLongPressEnd: (_) {
                        _timer4?.cancel();
                        setState(() {});
                      },
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(10.0),
                        ),
                        onPressed: () {
                          setState(() {
                            if (switchValue == false ||
                                bluetoothConnection == null) {
                              switchValue = false;
                              isconnected = "Not Connected !";
                            } else {
                              isconnected = "Connected !";
                            }
                          });
                          _sendData("forward");
                        },
                        child: Image.asset(
                          'assets/up.png',
                          width: 100.0,
                          height: 100.0,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    GestureDetector(
                      onLongPressStart: (_) {
                        _timer5 = Timer.periodic(
                            const Duration(milliseconds: 300), (_) {
                          setState(() {
                            if (switchValue == false ||
                                bluetoothConnection == null) {
                              switchValue = false;
                              isconnected = "Not Connected !";
                            } else {
                              isconnected = "Connected !";
                            }
                          });
                          _sendData("backward");
                        });
                      },
                      onLongPressEnd: (_) {
                        _timer5?.cancel();
                        setState(() {});
                      },
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(10.0),
                        ),
                        onPressed: () {
                          setState(() {
                            if (switchValue == false ||
                                bluetoothConnection == null) {
                              switchValue = false;
                              isconnected = "Not Connected !";
                            } else {
                              isconnected = "Connected !";
                            }
                          });
                          _sendData("backward");
                        },
                        child: Image.asset(
                          'assets/down.png',
                          width: 100.0,
                          height: 100.0,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 25.0,
                    ),
                  ],
                ),
                const SizedBox(
                  width: 20.0,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
