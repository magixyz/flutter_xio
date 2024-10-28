
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

  BleIo(this.notifier,this.writer,this.connector){

    print('notifier: $notifier');
    print('writer: $writer');

     this.notifier.subscribe().listen((event) {

       print('notify: $event');

       for (Function listen in listens){
         listen(event);
       }
     });

  }

  Future<List<int>?> call(List<int> data,Function(List<int>? nData,List<int> rData) listen, {int retry = 3, int timeout = 3000}) async {

    print('call === : $data');

    return await lock.synchronized(() async {

      List<int> rData = [];

      var syncer = SyncerV1<List<int>?>(()async{

        if ( connector.deviceConnectionState != DeviceConnectionState.connected) return null;

        print('write data: $data');

        await writer.write(data,withResponse: false);

      },(List<int>? nData)async{
        return await listen(nData,rData);
      });

      listens.add(syncer.notify);

      var ret = await syncer.retry(timeout: timeout);

      listens.remove(syncer.notify);

      return ret;

    });

  }


  Future<bool> callWithoutRes(List<int> data) async {


    await writer.write(data,withResponse: true);

    return true;

  }

}