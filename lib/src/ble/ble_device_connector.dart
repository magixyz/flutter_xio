import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'reactive_state.dart';

class BleDeviceConnector extends ReactiveState<DeviceConnectionState> {


  final FlutterReactiveBle _ble;
  final void Function(String message) _logMessage;


  @override
  Stream<DeviceConnectionState> get state => _deviceConnectionController.stream;
  final _deviceConnectionController = StreamController<DeviceConnectionState>();


  String? deviceId;
  DeviceConnectionState? deviceConnectionState;
  // ignore: cancel_subscriptions
  StreamSubscription<ConnectionStateUpdate>? _connection;

  Completer<DeviceConnectionState>? _completer ;

  BleDeviceConnector({
    required FlutterReactiveBle ble,
    required Function(String message) logMessage,
  })  : _ble = ble,
        _logMessage = logMessage{

    _ble.connectedDeviceStream.listen((event) {

      print('mark: ble state 1: ${event.connectionState}');

      if (event.deviceId == this.deviceId){
        deviceConnectionState = event.connectionState;
        _deviceConnectionController.add(event.connectionState);


        print('mark: ble state : ${event.connectionState}');
        if(_completer!= null && !_completer!.isCompleted){


          print('mark: ble completer : ${event.connectionState}');
          _completer!.complete(event.connectionState);
        }
      }

      print('mark: connect state 1: $deviceConnectionState');
    });

  }

  Future<bool> connect(String deviceId,{Duration? timeout=const Duration(seconds: 2)}) async {

    print('mark: ble connect start');

    if (this.deviceId != null){
      if ( deviceId != this.deviceId  ) {
        await reset();
      } else{
        if (this.deviceConnectionState != null && this.deviceConnectionState != DeviceConnectionState.disconnected){
          return false;
        }
      }
    }

    this.deviceId = deviceId;

    print('connect timeout: $timeout');

    _connection = _ble.connectToDevice(id: deviceId, connectionTimeout: timeout?? Duration(seconds: 10)).listen(
      (update) {
        print(
            'ConnectionState for device $deviceId : ${update.connectionState}');

      },
      onError: (Object e) =>
          print('Connecting to device $deviceId resulted in error $e'),
    );

    print('mark: connect 2');

    var mturet = await _ble.requestMtu(deviceId: deviceId, mtu: 512);

    print('mark: connect 3: $mturet');

    while(! [DeviceConnectionState.connected,DeviceConnectionState.disconnected].contains( deviceConnectionState ) ){

      print('mark: connect 4');
      _completer = Completer<DeviceConnectionState>();
      await _completer!.future;

    }

    if (deviceConnectionState == DeviceConnectionState.connected){
      print('request high performance ...');
      await _ble.requestConnectionPriority(deviceId: deviceId, priority: ConnectionPriority.highPerformance);
      print('response high performance ...');
    }

    print('mark: ble connect end: $deviceConnectionState');

    return deviceConnectionState == DeviceConnectionState.connected;

  }

  Future<bool> disconnect() async {


    print('disconnect step 0');

    if (deviceConnectionState == null || deviceConnectionState != DeviceConnectionState.connected ) return false;

    print('disconnect step 1');

    try {
      _logMessage('disconnecting to device: $deviceId');
      await _connection?.cancel();
      _connection = null;


      print('disconnect step 2: ${deviceConnectionState}');

    } on Exception catch (e, _) {


      print('disconnect step 3');
      _logMessage("Error disconnecting from a device: $e");
    } finally {
      // Since [_connection] subscription is terminated, the "disconnected" state cannot be received and propagated
      // _deviceConnectionController.add(
      //   ConnectionStateUpdate(
      //     deviceId: deviceId,
      //     connectionState: DeviceConnectionState.disconnected,
      //     failure: null,
      //   ),
      // );


      print('disconnect step 4: ${deviceConnectionState}');

    }


    print('disconnect step 5: ${deviceConnectionState}');

    while(! [DeviceConnectionState.connected,DeviceConnectionState.disconnected].contains( deviceConnectionState ) ){

      print('disconnect step 6: ${deviceConnectionState}');
      _completer = Completer<DeviceConnectionState>();
      await _completer!.future;


      print('disconnect step 7: ${deviceConnectionState}');
    };


    print('disconnect step 8: ${deviceConnectionState}');

    return deviceConnectionState == DeviceConnectionState.disconnected;

  }


  Future<List<Characteristic?>?> discovery(Uuid serviceUuid,List<Uuid> characteristicUuids) async{

    if (deviceId == null) return null;


    var value = await discoverServices(deviceId!);

    if (value == null){
      print('discovery error!!');
      disconnect();

      return null;
    }


    print('discover service:');
    print(value);

    for (var e in value) {
      print('service1: ${e.id.toString()}');

      if (e.id == serviceUuid) {
        List<Characteristic?> cs = [];

        for (Uuid cUuid in characteristicUuids) {

          print('hit characteristic: $cUuid' );

          Characteristic? target;

          for (var c in e.characteristics) {
            if (cUuid == c.id) {
              target = c;
            }
          }

          cs.add(target);
        }


        return cs;
      }
    }

  }


  Future<List<Service>?> discoverServices(String deviceId) async {
    try {
      _logMessage('Start discovering services for: $deviceId');
      await _ble.discoverAllServices(deviceId);
      final result =  _ble.getDiscoveredServices(deviceId);

      _logMessage('Discovering services finished');
      return result;
    } on Exception catch (e) {
      _logMessage('Error occured when discovering services: $e');
      return null;
    }
  }

  Future<int?> rssi() async{

    if (deviceConnectionState != DeviceConnectionState.connected) return null;

    if (deviceId != null) {
      return await _ble.readRssi(deviceId!);
    }
  }

  reset() async{

    try {
      await _connection?.cancel();
    }catch(e){
      print('error when disconnect old connect: $e');
    }

    deviceId = null;
    deviceConnectionState = null;
    _connection = null;

  }

  Future<void> dispose() async {
    await _deviceConnectionController.close();
  }
}
