import 'dart:typed_data';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:permission_handler/permission_handler.dart';

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
  String CHARACTERISTIC_MI_BAND_DEVICE_BATTERY_INFO = "00000006-0000-3512-2118-0009af100700";
  String myMiBand3 = "E3:22:C4:77:73:E8";
  String myMiBand4 = "E3:22:C4:77:73:E8";
  String transactionTagDiscovery = "discovery";

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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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


    bleManager.startPeripheralScan(allowDuplicates: false, callbackType: CallbackType.allMatches, scanMode: ScanMode.balanced, uuids: [
     // CHARACTERISTIC_MI_BAND_DEVICE_BATTERY_INFO.toUpperCase().toString(), // add here a specific char to be searched for
    ]).listen((scanResult) async {
      Fimber.d("Device: " + scanResult.peripheral.name.toString() + " Address: " + scanResult.peripheral.identifier.toUpperCase());
      if(scanResult.peripheral.identifier.toUpperCase() == myMiBand3) {
        Fimber.d("Device found: " + scanResult.peripheral.name.toString() + " Address: " + scanResult.peripheral.identifier.toUpperCase());
        _stopScan(0);
        //
        peripheral = scanResult.peripheral;
        await peripheral.connect();
        bool connected = await peripheral.isConnected();
        if(connected) {
          Fimber.d("Peripheral Connected...");
          // await peripheral.discoverAllServicesAndCharacteristics(transactionId: transactionTagDiscovery);
          // List<Service> services = await peripheral.services(); //getting all services
          // printServiceAndCharacteristic(services, CHARACTERISTIC_MI_BAND_DEVICE_BATTERY_INFO);
          peripheral.readCharacteristic("serviceUUID", "characteristicUUID").then((char) {
            char.read(transactionId: "bat").asStream().listen((values){
              Fimber.d("Battery Values: " + values.toString());
            });
          });

          Future.delayed(Duration(seconds: 25)).then((_) async {
           // bleManager.cancelTransaction(transactionTagDiscovery);
            _disconnect();
            Fimber.d("Peripheral Disconnected...");
          });

        } else {
          Fimber.d("Peripheral Not Connected!");
        }
        //
      }
    });

    // TODO: just simple scan
//  bleManager.startPeripheralScan().listen((device){
//    Fimber.d("Device: " + device.peripheral.identifier.toUpperCase().toString());
//  });

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
    Fimber.d("Disconnect Or Cancel Connection");
    await peripheral.disconnectOrCancelConnection();
  }


  void _stopScan(int seconds) {
    if (seconds > 0) {
        Future.delayed(Duration(seconds: seconds)).asStream().listen((_) {
        Fimber.d("Stoped scan after 10 seconds!");
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

}
