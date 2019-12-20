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
  String transactionTagDiscovery = "discovery";
  bool foundFirstTime = false;
  int lastScanTimeInMillis = 0;
  int minSecondsDiffBeforeNewScanStart = 3;

  String miBand3_ID = "E3:22:C4:77:73:E8";
  String _CHARACTERISTIC_MI_BAND_DEVICE_BATTERY_INFO = "00000006-0000-3512-2118-0009af100700";

  String nonin3230_ID = "00:1C:05:FF:4E:5B";
  String miBand4_ID = "E3:22:C4:77:73:E8";
  String _NONIN_3230_PLX_SPOT_CHECK_MEASUREMENT_CHARACTERISTIC = "00002a5e-0000-1000-8000-00805f9b34fb";
  String _NONIN_3230_PLX_SPOT_CHECK_MEASUREMENT_SERVICE = "00001822-0000-1000-8000-00805f9b34fb";
  //String _NONIN3230_BATTERY_LEVEL_CHARACTERISTIC = "00002a19-0000-1000-8000-00805f9b34fb";

  String scaleADUC351PBTCI_ID = "00:09:1F:82:88:C7";
  String _SCALE_ADUC351PBTCI_WEIGHT_SERVICE = "0000181d-0000-1000-8000-00805f9b34fb";
  String _SCALE_ADUC351PBTCI_WEIGHT_CHARACTERISTIC = "00002a9d-0000-1000-8000-00805f9b34fb";


  // TODO: BLE Error Codes: https://github.com/Polidea/react-native-ble-plx/blob/master/ios/BleClientManager/BleError.swift
  // TODO: https://api.flutter.dev/flutter/dart-core/BigInt/toUnsigned.html
  // TODO: https://stackoverflow.com/questions/57474056/how-to-convert-int-into-uint32-in-flutter
  // TODO: https://clickhouse-docs.readthedocs.io/en/latest/data_types/int_uint.html

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

    bleManager.observeBluetoothState().listen((btState) {
      Fimber.d("\n \n");
      Fimber.d("################");
      Fimber.d("Bluetooth state: " + btState.toString());
      Fimber.d("################");
      Fimber.d("\n \n");
    });

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
        if (scanResult.peripheral.identifier.toString() == nonin3230_ID && foundFirstTime == false) {
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
          Fimber.d("Connected: " + connected.toString());
          if (connected) {
            Fimber.d("Peripheral Connected...");
            await peripheral.discoverAllServicesAndCharacteristics(transactionId: transactionTagDiscovery);
           // List<Service> services = await peripheral.services(); // getting all services
            bleManager.cancelTransaction(transactionTagDiscovery);
          //  printServiceAndCharacteristic(services, null);
            // TODO: Start - Do Manipulating characteristics
           // services.forEach((service) {
             // service.characteristics().then((charList){
              //  charList.forEach((char) {
                 // Fimber.d("Char :: " + char.uuid.toString());
                 // if(char.uuid.toUpperCase() == _NONIN_3230_PLX_SPOT_CHECK_MEASUREMENT_CHARACTERISTIC.toUpperCase()) {
                     //   Fimber.d("Found Char :: " + char.uuid.toString());
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

//                      service.readCharacteristic(char.uuid.toString(), transactionId: "bat1").then((characteristicObj){
//                        bleManager.cancelTransaction("bat1");
//                        Fimber.d("Option 2: Complete  Info: " + characteristicObj.toString());
//                        Fimber.d("Option 2: Values: " + characteristicObj.value.toString());
//                        Fimber.d("Option 2: Battery procentage: " + characteristicObj.value.elementAt(1).toString() + "%");
//                      });

               //   }
             //   });

            //  });
         //   });
            // TODO: End
            peripheral.monitorCharacteristic(
                _NONIN_3230_PLX_SPOT_CHECK_MEASUREMENT_SERVICE,
                _NONIN_3230_PLX_SPOT_CHECK_MEASUREMENT_CHARACTERISTIC, transactionId: "monitor")
            // .map(convert) // TODO: convert data into heart rate and
                .listen((characteristic){
              bleManager.cancelTransaction("monitor");
              Fimber.d("Values:" + characteristic.value.toString());
            });
          }

          Future.delayed(Duration(seconds: 30)).then((_) async {
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
    // TODO: just testing stuff here!
    Fimber.d("Floating Button Method!");
    // From Flutter Ble: [31, 212, 243, 57, 0, 224, 7, 1, 6, 5, 9, 21, 0, 1, 0, 0, 0, 91, 228]
    // From Android Ble: [31, -54, -13, 71, 0, -32, 7, 1, 7, 4, 41, 2, 0, 1, 1, 0, 0, -121, -25]
    //Uint8List list1 = Uint8List(20);
//    List<int> list = List<int>();
//    list.add(31);
//    list.add(212);
//    list.add(243);
//    list.add(57);
//    list.add(0);
//    list.add(224);
//    list.add(7);
//    list.add(1);
//    list.add(6);
//    list.add(5);
//    list.add(9);
//    list.add(21);
//    list.add(0);
//    list.add(1);
//    list.add(0);
//    list.add(0);
//    list.add(0);
//    list.add(91);
//    list.add(228);

//    Uint8List bytes = Uint8List.fromList(list);
//    Fimber.d("List Values: " + list.toString());
//    for (var value in bytes) {
//      Fimber.d("Raw Value: " + value.toString());
//    }
//    Fimber.d("Flag: " + BigInt.from(list.elementAt(0)).toUnsigned(8).toString());
//    double ok = list.elementAt(1).toDouble()  + list.elementAt(2).toDouble();
//    Fimber.d("SpO2: " + ok.toString());


    Uint8List completeUInt8List = new Uint8List(19);
    completeUInt8List[0] = 31;
    completeUInt8List[1] = 212;
    completeUInt8List[2] = 243;
    completeUInt8List[3] = 57;
    completeUInt8List[4] = 0;
    completeUInt8List[5] = 224;
    completeUInt8List[6] = 7;
    completeUInt8List[7] = 1;
    completeUInt8List[8] = 6;
    completeUInt8List[9] = 5;
    completeUInt8List[10] = 9;
    completeUInt8List[11] = 21;
    completeUInt8List[12] = 0;
    completeUInt8List[13] = 1;
    completeUInt8List[14] = 0;
    completeUInt8List[15] = 0;
    completeUInt8List[16] = 0;
    completeUInt8List[17] = 91;
    completeUInt8List[18] = 228;
//    for (var value in completeUInt8List) {
//      Fimber.d("Value: " + value.toString());
//    }

    Fimber.d("Complete UInt8 Data List: " + completeUInt8List.toString());
    Uint8List flagUInt8List = completeUInt8List.sublist(0,1);
    //List<int> ok = List().fr


    for (var value in flagUInt8List) {
      Fimber.d("Value: " + value.toString());
    }

//    var what = completeUInt8List.elementAt(1) << 24 >> 24;
//    Fimber.d("What: " + what.toString());




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
