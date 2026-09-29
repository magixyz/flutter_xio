import 'dart:async';

import 'dart:convert';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_xio/flutter_xio.dart';
import 'package:flutter_xio/src/utils/syncer_v1.dart';
import 'package:synchronized/synchronized.dart';

import '../utils/syncer.dart';
import 'ble_device_connector.dart';

class BleIo{
  Characteristic notifier;
  Characteristic writer;
  BleDeviceConnector connector;

  List<Function> listens = [];

  Lock lock = new Lock();
  StreamSubscription<List<int>>? _notifications;
  Future<void>? _disposeFuture;
  bool _disposed = false;

  /// Wait for native notification cleanup while the peripheral is connected.
  Future<void> dispose() {
    _disposed = true;
    return _disposeFuture ??= lock.synchronized(() async {
      final notifications = _notifications;
      _notifications = null;
      listens.clear();
      await notifications?.cancel();
    });
  }

  BleIo(this.notifier,this.writer,this.connector){

    print('notifier: $notifier');
    print('writer: $writer');

     _notifications = this.notifier.subscribe().listen((event) {

       // print('notify: $event');

       // print('sync listens: ${listens.length}');

       for (Function listen in listens){
         listen(event);
       }
     });

  }

  Future<List<int>?> call(List<int> data,Function(List<int>? nData,List<int> rData) listen, {int retry = 3, int timeout = 3000}) async {

    return await lock.synchronized(() async {
      if (_disposed) return null;

      print( 'sync send data >>>>>>>>>>>>>>>: $data' );

      List<int> rData = [];

      var syncer = SyncerV1<List<int>?>(()async{

        if ( connector.deviceConnectionState != DeviceConnectionState.connected) return null;

        await writer.write(data,withResponse: false);

      },(List<int>? nData)async{
        return await listen(nData,rData);
      });

      listens.add(syncer.notify);

      try {
        final ret = await syncer.retry(retry: retry, timeout: timeout);
        print('sync recv data <<<<<<<<<<<<<<<<: $ret');
        return ret;
      } finally {
        listens.remove(syncer.notify);
      }

    });

  }


  Future<bool> callWithoutRes(List<int> data) async {


    return lock.synchronized(() async {
      if (_disposed) return false;
      await writer.write(data, withResponse: true);
      return true;
    });

  }

}