import 'dart:typed_data';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter_app_personal_test/time_utils.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

void main(){
  Fimber.plantTree(DebugTree());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo Polidea',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page Polidea'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  PermissionStatus permissionStatus;
  BleManager bleManager;
  Peripheral peripheral;
  String _CHARACTERISTIC_MI_BAND_DEVICE_BATTERY_INFO = "00000006-0000-3512-2118-0009af100700";
  String _PLX_SPOT_CHECK_MEASUREMENT_CHARACTERISTIC = "00002a5e-0000-1000-8000-00805f9b34fb";
  String _BATTERY_LEVEL_CHARACTERISTIC = "00002a19-0000-1000-8000-00805f9b34fb";
  String miBand3ID = "E3:22:C4:77:73:E8";
  String miBand4ID = "E3:22:C4:77:73:E8";
  String nonin3230ID = "00:1C:05:FF:4E:5B";
  String transactionTagDiscovery = "discovery";
  bool foundFirstTime = false;
  int lastScanTimeInMillis = 0;
  int minSecondsDiffBeforeNewScanStart = 3;

  // TODO: BLE Error Codes: https://github.com/Polidea/react-native-ble-plx/blob/master/ios/BleClientManager/BleError.swift

  @override
  void setState(fn) {
    super.setState(fn);
   // _askForPermission();
    bleManager = BleManager();
    bleManager.createClient();
    bleManager.setLogLevel(LogLevel.error);
    if(bleManager != null) {
      Fimber.d("Ble Manager is Created!");
    } else {
      Fimber.d("Ble Manager is not Created!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            RaisedButton(child: Text("Ask for Permission"),
              onPressed: _askForPermission,
              color: Colors.blueAccent,
              textColor: Colors.black,
              padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              splashColor: Colors.grey,
            ),
            RaisedButton(child: Text("Start Ble Scan"),
              onPressed: _startScan,
              color: Colors.blueAccent,
              textColor: Colors.black,
              padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              splashColor: Colors.grey,
            ),
            RaisedButton(child: Text("Stop Ble Scan"),
              onPressed: (){
                _stopScan(0);
              },
              color: Colors.blueAccent,
              textColor: Colors.black,
              padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              splashColor: Colors.grey,
            ),
            RaisedButton(child: Text("Disconned"),
              onPressed: (){
                _disconnect();
              },
              color: Colors.blueAccent,
              textColor: Colors.black,
              padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              splashColor: Colors.grey,
            ),
            RaisedButton(child: Text("Reset Bluetooth"),
              onPressed: (){
                _resetBluetooth();
              },
              color: Colors.blueAccent,
              textColor: Colors.black,
              padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              splashColor: Colors.grey,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _floatingButtonMethod();
          Flushbar(title: "Hey You Hello :)",
            message: "How are you? :)",
            duration: Duration(seconds: 3),
          ).show(context);
        },
        tooltip: 'Bottom Notification will pop up!',
        child: Icon(Icons.add),
      ),
    );
  }

  void _startScan() {
   // bleManager.enableRadio(); //ANDROID-ONLY turns on BT. NOTE: doesn't check permissions
   // bleManager.disableRadio(); //ANDROID-ONLY turns off BT. NOTE: doesn't check permissions
   // BluetoothState currentState = await bleManager.bluetoothState();

    bleManager.stopPeripheralScan();
    foundFirstTime = false;
    lastScanTimeInMillis = TimeUtils.getCurrentTimeMilliSeconds();
    Fimber.d("Current Time: " + TimeUtils.getDateTimeString(TimeUtils.getCurrentTimeMilliSeconds()));
    Fimber.d("Time Diff: " + TimeUtils.getTimeDiff(lastScanTimeInMillis, TimeUtils.getCurrentTimeMilliSeconds()).toString());

    if(TimeUtils.getTimeDiff(lastScanTimeInMillis, TimeUtils.getCurrentTimeMilliSeconds()) >= minSecondsDiffBeforeNewScanStart) {
      bleManager.startPeripheralScan(allowDuplicates: false, callbackType: CallbackType.allMatches, scanMode: ScanMode.balanced,
          uuids: [
            // CHARACTERISTIC_MI_BAND_DEVICE_BATTERY_INFO.toUpperCase().toString(), // add here a specific char to be searched for
          ]).listen((scanResult) async {
        Fimber.d("Device: " + scanResult.peripheral.name.toString() + " Address: " + scanResult.peripheral.identifier.toUpperCase());
        if (scanResult.peripheral.identifier.toString() == nonin3230ID && foundFirstTime == false) {
          foundFirstTime = true;
          Fimber.d("Device found: " + scanResult.peripheral.name.toString() + " Address: " + scanResult.peripheral.identifier.toUpperCase());
          _stopScan(0);
          //
          peripheral = scanResult.peripheral;
          bool connectedAlready = await peripheral.isConnected();
          Fimber.d("Already Connected: " + connectedAlready.toString());
          if (connectedAlready == false) {
            await peripheral.connect();
          }
          bool connected = await peripheral.isConnected();
          Fimber.d("Connected :: Connected: " + connected.toString());
          if (connected) {
            Fimber.d("Peripheral Connected...");
            await peripheral.discoverAllServicesAndCharacteristics(
                transactionId: transactionTagDiscovery);
            List<Service> services = await peripheral.services(); // getting all services
            bleManager.cancelTransaction(transactionTagDiscovery);
            printServiceAndCharacteristic(services, null);
            // TODO: Start - Do Manipulating characteristics
            services.forEach((service) {
              service.characteristics().then((charList){
                charList.forEach((char) {
                 // Fimber.d("Char :: " + char.uuid.toString());
                  if(char.uuid.toUpperCase() == _PLX_SPOT_CHECK_MEASUREMENT_CHARACTERISTIC.toUpperCase()) {
                        Fimber.d("Found Char :: " + char.uuid.toString());
//                      readCharacteristic(char).then((values){
//                      bleManager.cancelTransaction("read");
//                      Fimber.d("Option 1: Battery Values: " + values.toString());
//                      });

                    // TODO: test
//                    service.writeCharacteristic(char.uuid.toString(), null, true).then((characteristicObj){
//                      Fimber.d("What: " + characteristicObj.toString());
//                      characteristicObj.read(transactionId: "ok123456").then((val){
//                        bleManager.cancelTransaction("ok123456");
//                        Fimber.d("Values: " + val.toString());
//                      });
//                    });
                    // TODO: test

                      service.readCharacteristic(char.uuid.toString(), transactionId: "bat1").then((characteristicObj){
                        bleManager.cancelTransaction("bat1");
                        Fimber.d("Option 2: Complete  Info: " + characteristicObj.toString());
                        Fimber.d("Option 2: Values: " + characteristicObj.value.toString());
                       // Fimber.d("Option 2: Battery procentage: " + characteristicObj.value.elementAt(1).toString() + "%");
                      });

                  }
                });

              });
            });

            // TODO: End
          }

          Future.delayed(Duration(seconds: 5)).then((_) async {
            bool connected = await peripheral.isConnected();
            if (connected) {
              Fimber.d("Delayed Peripheral Disconnected...");
              _disconnect();
            } else {
              Fimber.d("Peripheral Disconnected...");
            }
          });
        }
      });
    } else {
      Fimber.d("Must wait for more then $minSecondsDiffBeforeNewScanStart seconds since the last device scan");
    }
  }

  Future<Uint8List> readCharacteristic(Characteristic characteristic) {
    return characteristic.read(transactionId: "read");
  }

  void printServiceAndCharacteristic(List<Service> services, String searchFoCharacteristic) {
    services.forEach((service) {
      Fimber.d("\n Service: " + service.uuid.toString());
      Future<List<Characteristic>> characteristics = service.characteristics();
      characteristics.asStream().listen((characteristics) {
        characteristics.forEach((characteristic) {
          if (searchFoCharacteristic != null && characteristic.uuid.toUpperCase().toString() == searchFoCharacteristic.toUpperCase()) {
            Fimber.d("\n Searched Characteristic: " + characteristic.uuid.toString() +
                "\n is Indicatable: " + characteristic.isIndicatable.toString() +
                "\n is Notifiable: " + characteristic.isNotifiable.toString() +
                "\n is Readable: " + characteristic.isReadable.toString() +
                "\n is Writable With Response: " + characteristic.isWritableWithResponse.toString() +
                "\n is Writable Without Response: " + characteristic.isWritableWithoutResponse.toString());
          }
          Fimber.d("\n Characteristics: " + characteristic.uuid.toString() +
              "\n is Indicatable: " + characteristic.isIndicatable.toString() +
              "\n is Notifiable: " + characteristic.isNotifiable.toString() +
              "\n is Readable: " + characteristic.isReadable.toString() +
              "\n is Writable With Response: " + characteristic.isWritableWithResponse.toString() +
              "\n is Writable Without Response: " + characteristic.isWritableWithoutResponse.toString());
        });
      });
    });
  }

  Future<void> _disconnect() async {
    if (peripheral != null) {
      Fimber.d("Disconnect Or Cancel Connection Called!");
      if (await peripheral.isConnected()) {
          await peripheral.disconnectOrCancelConnection();
      }
    }
  }

  void _stopScan(int seconds) {
    if (seconds > 0) {
      Fimber.d("Scan wil be stoped after $seconds seconds!");
        Future.delayed(Duration(seconds: seconds)).asStream().listen((_) {
        Fimber.d("Stoped scan!");
        bleManager.stopPeripheralScan();
      });
    } else {
        Fimber.d("Stoped scan!");
        bleManager.stopPeripheralScan();
    }
  }

  void _updateStatus(PermissionStatus status) {
    if (status != permissionStatus) {
      setState(() {
        permissionStatus = status;
      });
    }
  }

  void _askForPermission () {
    PermissionHandler().requestPermissions([PermissionGroup.locationWhenInUse]).then(_onStatusRequested);
  }

  void _onStatusRequested(Map<PermissionGroup, PermissionStatus> statuses) {
    final status = statuses[PermissionGroup.locationWhenInUse];
    _updateStatus(status);
  }

  @override
  void dispose() {
    _stopScan(0);
    bleManager.destroyClient();
    Fimber.d("Called Disposed");
    super.dispose();
  }

  void _floatingButtonMethod() {
    Fimber.d("Floating Button Method!");
  }

  Future<void> _resetBluetooth() async {
    if (Platform.isAndroid) {
      if (bleManager != null) {
        bleManager.stopPeripheralScan();
        if(peripheral != null) {
          await peripheral.disconnectOrCancelConnection();
        }
        Fimber.d("Reseting bluetooth - Disabling!");
        bleManager.disableRadio(); // ANDROID-ONLY turns off BT. NOTE: doesn't check permissions
        Future.delayed(Duration(seconds: 5)).then((_) {
          Fimber.d("Reseting bluetooth - Enabling!");
          bleManager.enableRadio(); // ANDROID-ONLY turns on BT. NOTE: doesn't check permissions
        });
      } else {
        Fimber.d("BLE Manager not instantiated!");
      }
    } else if (Platform.isIOS) {
      Fimber.d("Reseting bluetooth on IOS devices in not supported!");
    } else {
      Fimber.d("Reseting bluetooth on other platform device in not supported!");
    }
  }

}
