

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_xio/src/can/blecan_ptl.dart';
import 'package:flutter_xio/src/can/sdo/sdo_def.dart';
import 'package:flutter_xio/src/can/sdo/sdo_ptl.dart';

import '../ble/ble_io.dart';
import 'blecan_def.dart';
import 'sdo/sdo_io.dart';
import 'package:synchronized/synchronized.dart';

class CanBleIo extends SdoIo{

  static final _responseFrame = RegExp(r'^t([0-9a-fA-F]{3})8[0-9a-fA-F]{16}$');

  // BLE notifications are stream chunks: a header, payload, or CR can arrive
  // separately, and one notification can contain acknowledgements/other nodes.
  // Retain at most one unfinished standard 8-byte SDO frame (21 ASCII bytes).
  static List<int>? _receiveFrame(
      List<int>? chunk, List<int> buffer, int responseId) {
    if (chunk == null) {
      buffer.clear();
      return null;
    }
    for (final byte in chunk) {
      if (byte == 0x74) { // 't' cannot occur inside a hexadecimal payload.
        buffer.clear();
        buffer.add(byte);
      } else if (byte == 0x0d) {
        final frame = List<int>.of(buffer);
        buffer.clear();
        if (frame.length != 21) continue;
        final match = _responseFrame.firstMatch(String.fromCharCodes(frame));
        if (match != null && int.parse(match[1]!, radix: 16) == responseId) {
          return [...frame, byte];
        }
      } else if (buffer.isNotEmpty) {
        buffer.add(byte);
        if (buffer.length > 21) buffer.clear();
      }
    }
    return null;
  }

  late SdoPtl sdoPtl;
  BleIo bleIo;


  Lock lock = new Lock();

  CanBleIo(this.bleIo){
    // SdoIo sdoIo = BlecanPtl(bleIo);
    sdoPtl = SdoPtl(this);

  }




  Future<List<int>?> upload(int nodeId, int mIndex,int sIndex, {int retry = 3, int timeout = 1000}) async {

    return await lock.synchronized(() async {
      print('upload, m index: $mIndex , s index: $sIndex');

      try {
        var ret = await sdoPtl.upload(nodeId, mIndex, sIndex);

        print('upload, ret: $ret');


        return ret;

      }catch (e){
        print(e);

        return null;
      }

    });


  }

  Future<bool> download(int nodeId, int mIndex,int sIndex, List<int> data, {int retry = 3, int timeout = 1000}) async {

    return await lock.synchronized(() async {
      // print('download, m index: $mIndex , s index: $sIndex');

      var ret = await sdoPtl.download(nodeId, mIndex, sIndex,data);

      // print('download, ret: $ret');

      return ret;
    });


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
    final responseId = SdoRespCanId(nodeId).canId;

    // print( '${DateTime.now()}: call start , delay test');

    print('can ble io sdata: ${utf8.decode(sData)}');


    final rData = await bleIo.call(
      sData,
      (List<int>? chunk, List<int> buffer) =>
          _receiveFrame(chunk, buffer, responseId),
      retry: 1,
      timeout: 3000,
    );

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

    print('send data without res: ${utf8.decode(sData)}');


    bool ret = await bleIo.callWithoutRes(sData);

    return ret;
  }

}