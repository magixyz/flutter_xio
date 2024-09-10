

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

    // print('upload, m index: $mIndex , s index: $sIndex');

    var ret = await sdoPtl.upload(nodeId, mIndex, sIndex);

    // print('upload, ret: $ret');


    return ret;
  }

  Future<bool> download(int nodeId, int mIndex,int sIndex, List<int> data, {int retry = 3, int timeout = 1000}) async {

    // print('download, m index: $mIndex , s index: $sIndex');

    var ret = await sdoPtl.download(nodeId, mIndex, sIndex,data);

    // print('download, ret: $ret');

    return ret;

  }

  Future<bool> blkDown(int nodeId, int mIndex,int sIndex, List<int> data, {int retry = 3, int timeout = 1000}) async {

    // print('blk down, m index: $mIndex , s index: $sIndex');

    var ret = await sdoPtl.blkDown(nodeId, mIndex, sIndex,data);

    // print('blk down, ret: $ret');

    return ret;

  }


  @override
  Future<List<int>?> call(int nodeId, List<int> data) async{

    List<int> sData = utf8.encode(BlecanReqMsg(SdoReqCanId(nodeId), data).dump());
    List<int> respHead = utf8.encode(SdoRespCanId(nodeId).dump());


    // print( '${DateTime.now()}: call start , delay test');

    // print('send data: ${utf8.decode(sData)}');


    List<int>? rData = await bleIo.call(sData, (List<int> nData,List<int> rData){

      // print('can ble io ndata: $nData');

      if( nData[0] != 116 || ! listEquals(nData.sublist(1,respHead.length + 1), respHead)) return null;


      rData.addAll(nData);


      // print('can ble io rdata: $rData');

      if (rData.contains(  '\r'.codeUnitAt(0))){
        // print('can ble io 111');

        return rData;
      }else{

        // print('can ble io 222');

        return null;
      }
    },timeout: 10000);

    // print( '${DateTime.now()}: call end , delay test');

    if (rData == null) return null;

    BlecanRespMsg rMsg = BlecanRespMsg.load(utf8.decode(rData));

    return rMsg.data;
  }

  @override
  Future<bool> callWithoutRes(int nodeId, List<int> data) async{

    List<int> sData = utf8.encode(BlecanReqMsg(SdoReqCanId(nodeId), data).dump());
    List<int> respHead = utf8.encode(SdoRespCanId(nodeId).dump());


    // print( '${DateTime.now()}: call start , delay test');

    // print('send data: ${utf8.decode(sData)}');


    bool ret = await bleIo.callWithoutRes(sData);

    return ret;
  }

}