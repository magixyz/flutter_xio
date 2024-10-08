
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

     this.notifier.subscribe().listen((event) {

       print('notify: $event');

       if (event[0] == 116) {
         if (!utf8.decode(event).startsWith(RegExp(r't[1234]868'))) {
           // print('notify: ' + utf8.decode(event));
         }
       }else{
         // print('notify: ' + HexUtil.byte2hex(event));
       }

       // if (utf8.decode(event).startsWith(RegExp(r't[1234]868'))){
       //   return;
       // }
       //
       // print('flitered notify: ' + utf8.decode(event));

       for (Function listen in listens){
         listen(event);
       }
     });

  }

  Future<List<int>?> call(List<int> data,Function(List<int>? nData,List<int> rData) listen, {int retry = 3, int timeout = 3000}) async {

    return await lock.synchronized(() async {

      List<int> rData = [];

      var syncer = SyncerV1<List<int>?>(()async{

        if ( connector.deviceConnectionState != DeviceConnectionState.connected) return null;

        print('write data: $data');

        await writer.write(data,withResponse: false);

      },(List<int>? nData)async{
        return await listen(nData,rData);
      });


      print('will retry 1');

      listens.add(syncer.notify);

      var ret = await syncer.retry(timeout: timeout);

      listens.remove(syncer.notify);

      print('will retry 2');


      return ret;

    });

  }


  Future<bool> callWithoutRes(List<int> data) async {


    await writer.write(data,withResponse: true);

    return true;

  }

}