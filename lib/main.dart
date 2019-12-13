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

  @override
  void setState(fn) {
    super.setState(fn);
    _askForPermission();
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
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
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _startScan() {
   // bleManager.enableRadio(); //ANDROID-ONLY turns on BT. NOTE: doesn't check permissions
   // bleManager.disableRadio(); //ANDROID-ONLY turns off BT. NOTE: doesn't check permissions
   // BluetoothState currentState = await bleManager.bluetoothState();

    String CHARACTERISTIC_MI_BAND_DEVICE_BATTERY_INFO = "00000006-0000-3512-2118-0009af100700";
    String miBand3 = "E3:22:C4:77:73:E8";

    bleManager.startPeripheralScan(allowDuplicates: false, callbackType: CallbackType.allMatches, scanMode: ScanMode.balanced, uuids: [
    //  CHARACTERISTIC_MI_BAND_DEVICE_BATTERY_INFO,
    ]).listen((scanResult) async {
      Fimber.d("Device: " + scanResult.peripheral.name.toString() + " Address: " + scanResult.peripheral.identifier.toUpperCase());
      if(scanResult.peripheral.identifier.toUpperCase() == miBand3) {
        Fimber.d("Device found: " + scanResult.peripheral.name.toString() + " Address: " + scanResult.peripheral.identifier.toUpperCase());
        _stopScan(0);
        //
        Peripheral peripheral = scanResult.peripheral;
        await peripheral.connect();
        bool connected = await peripheral.isConnected();
        if(connected) {
          Fimber.d("Peripheral Connected...");
          Future.delayed(Duration(seconds: 5)).then((_) async {
            await peripheral.disconnectOrCancelConnection();
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
