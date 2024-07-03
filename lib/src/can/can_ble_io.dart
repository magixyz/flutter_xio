

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_xio/src/can/blecan_ptl.dart';
import 'package:flutter_xio/src/can/sdo/sdo_def.dart';
import 'package:flutter_xio/src/can/sdo/sdo_ptl.dart';

import '../ble/ble_io.dart';
import 'blecan_def.dart';
import 'sdo/sdo_io.dart';

class CanBleIo extends SdoIo{

  late SdoPtl sdoPtl;
  BleIo bleIo;

  CanBleIo(this.bleIo){
    // SdoIo sdoIo = BlecanPtl(bleIo);
    sdoPtl = SdoPtl(this);
  }




  Future<List<int>?> upload(int nodeId, int mIndex,int sIndex, {int retry = 3, int timeout = 1000}) async {

    return sdoPtl.upload(nodeId, mIndex, sIndex);

  }

  Future<bool> download(int nodeId, int mIndex,int sIndex, List<int> data, {int retry = 3, int timeout = 1000}) async {

    return sdoPtl.download(nodeId, mIndex, sIndex,data);

  }


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