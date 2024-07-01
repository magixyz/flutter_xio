
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_xio/flutter_xio.dart';

import 'blecan_def.dart';
import 'sdo/sdo_io.dart';

class BlecanPtl extends SdoIo{

  BleIo bleIo;

  BlecanPtl(this.bleIo);


  @override
  Future<List<int>?> call(int nodeId, List<int> data) async{

    List<int> sData = utf8.encode(BlecanReqMsg(SdoReqCanId(nodeId), data).dump());
    List<int> respHead = utf8.encode(SdoRespCanId(nodeId).dump());

    List<int>? rData = await bleIo.call(sData, (List<int> nData,List<int> rData){

      print('can ble io ndata: $nData');

      if( ! listEquals(nData.sublist(1,respHead.length + 1), respHead)) return null;


      rData.addAll(nData);


      print('can ble io rdata: $rData');

      if (rData.contains(  '\r'.codeUnitAt(0))){
        print('can ble io 111');

        return rData;
      }else{

        print('can ble io 222');

        return null;
      }
    });

    if (rData == null) return null;

    BlecanRespMsg rMsg = BlecanRespMsg.load(utf8.decode(rData));

    return rMsg.data;
  }



}