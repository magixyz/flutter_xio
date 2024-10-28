

import 'dart:async';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';

import '../ble/ble_io.dart';
import '../enum/register_type.dart';

class RpcBleIo {

  BleIo bleIo;

  RpcBleIo(this.bleIo);

  Future<List<int>?> call(List<int> data,{int retry = 3, int timeout = 1000}) async {
    List<int> sData = [];
    sData.addAll(data);

    // while(sData.length < 20) sData.add(0);

    print('rpc ble send data: $sData');

    List<int>? rData = await bleIo.call(
        sData, (List<int>? nData, List<int> rData) {

      print('rpc ble recv data: $nData');

      if (nData == null){
        rData.clear();
        return null;
      }

      rData.addAll(nData);

      return rData;
    },timeout: timeout);

    return rData;
  }


}