

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_xio/src/ble/ble_io_v1.dart';
import 'package:flutter_xio/src/utils/steam_relay.dart';
import 'package:tuple/tuple.dart';

import '../ble/ble_io.dart';
import '../utils/syncer.dart';
import 'modbus_def.dart';
import 'modbus_ptl.dart';
import '../enum/register_type.dart';

class ModbusBleIoV3 {

  BleIoV1 bleIo;


  ModbusBleIoV3(this.bleIo);


  Future<RtuReadMultiHoldingResMsg?> readMultiHolding(
      RtuReadMultiHoldingReqMsg reqMsg) async {
    RtuReadMultiHoldingResMsg? rData = await bleIo.call<
        RtuReadMultiHoldingResMsg>(
        reqMsg.dump(), (List<int> nData, List<int> rData) {
      rData.addAll(nData);

      try {
        RtuReadMultiHoldingResMsg.load(rData, reqMsg);
      } catch (e) {
        print(e);
        return null;
      }
    });

    return rData;
  }
}