import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xio/flutter_xio.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'device_widget.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();

  FlutterReactiveBle ble = FlutterReactiveBle();
  BleLogger bleLogger = BleLogger(ble: ble);

  BleDeviceConnector connector = BleDeviceConnector(ble:ble , logMessage: bleLogger.addToLog);
  BleScanner scanner = BleScanner(ble: ble, logMessage: bleLogger.addToLog);

  BleStatusMonitor monitor = BleStatusMonitor(ble);


  runApp(MultiProvider(providers: [
    Provider.value(value: connector),
    Provider.value(value: scanner),
    StreamProvider<BleScannerState?>(
      create: (_) => scanner.state,
      initialData: const BleScannerState(
        discoveredDevices: [],
        scanIsInProgress: false,
      ),
    ),
    StreamProvider<BleStatus?>(
      create: (_) => monitor.state,
      initialData: BleStatus.unknown,
    ),
    StreamProvider<DeviceConnectionState?>(
      create: (_) => connector.state,
      initialData: DeviceConnectionState.disconnected,
    ),
  ],
    child: const MyApp(),

  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ble Test',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ble Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {


  late BleScanner scanner = Provider.of<BleScanner>(context,listen: false);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Future.delayed(Duration.zero,()async{

      if (Platform.isAndroid){
        if ( (await DeviceInfoPlugin().androidInfo).version.sdkInt <= 30){

          await Permission.location.request();
        }else{

          await [Permission.bluetoothScan,Permission.bluetoothConnect].request();

        }
      }


    });

  }


  @override
  Widget build(BuildContext context) {

    return Consumer2<BleStatus,BleScannerState>(builder: (_,bleStatus,bleScannerState,__){

      if (bleStatus != BleStatus.ready){
        return Scaffold(body: Center(child: Text('ble not ready!')));
      }

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: ListView(
          children: bleScannerState.discoveredDevices.where((e) => e.name != null && e.name.isNotEmpty ).map(
                  (e)=>ListTile(title: Text(e.name),
                    subtitle: Text(e.id),
                    onTap: ()async{
                      await scanner.stopScan();
                      Navigator.push(context, MaterialPageRoute(builder: (context) => DeviceWidget(e)));
                    },
                  )).toList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: (){
            scanner.startScan(seconds: 5);
          },
          tooltip: 'Scan Ble',
          child: const Icon(Icons.bluetooth_searching_outlined),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      );

    });


  }
}
