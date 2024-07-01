

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

class CanBleIo{

  late SdoPtl sdoPtl;

  CanBleIo(BleIo bleIo){
    SdoIo sdoIo = BlecanPtl(bleIo);
    sdoPtl = SdoPtl(sdoIo);
  }




  Future<List<int>?> upload(int nodeId, int mIndex,int sIndex, {int retry = 3, int timeout = 1000}) async {

    return sdoPtl.upload(nodeId, mIndex, sIndex);

  }

  Future<List<int>?> _upSeg(int mIndex,int sIndex, {int retry = 3, int timeout = 1000}) async {

    SdoMsg head = SdoUpReqDirectMsg(mIndex,sIndex);

    // return await bleIo.call(sData, (List<int> rData){
    //
    // });

  }


}