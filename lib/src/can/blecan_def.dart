
import 'package:flutter_xio/src/utils/hex_util.dart';

import 'sdo/sdo_ptl.dart';

abstract class CanId{
  late int _nodeId;

  int get baseId;
  int get nodeId=>_nodeId;
  int get canId=>baseId + _nodeId;

  CanId(this._nodeId);
  CanId.load(String vs){
    if (vs.length != 3) throw Exception();
    _nodeId = int.parse(vs,radix: 16) - baseId ;
  }

  String dump(){
    String ret = canId.toRadixString(16);
    return ret;
  }

}


class SdoReqCanId extends CanId{
  static const int REQ_ID = 0x600;

  SdoReqCanId(super.nodeId);

  SdoReqCanId.load(super.vs):super.load();

  @override
  int get baseId=>REQ_ID;
}

class SdoRespCanId extends CanId{
  static const int RESP_ID = 0x580;


  SdoRespCanId(super.nodeId);
  SdoRespCanId.load(super.vs) : super.load();


  @override
  int get baseId=>RESP_ID;

}


abstract class BlecanMsg {

  late CanId canId;
  late List<int> data;

  BlecanMsg(this.canId, this.data);

  BlecanMsg.load();

  String dump(){
    String ret = '';
    ret += 't';
    ret += canId.dump();
    ret += '8';
    ret += data.map((e) => e.toRadixString(16).padLeft(2, "0")).join();
    ret += '\r';

    return ret;
  }


}

class BlecanReqMsg extends BlecanMsg {

  BlecanReqMsg(super.canId, super.data) ;

}


class BlecanRespMsg extends BlecanMsg {

  BlecanRespMsg.load(String vs) : super.load(){
    canId = SdoRespCanId.load(vs.substring(1,4));
    data =  HexUtil.hex2byte(vs.substring(5,5+16));
  }

}
//
// class BlecanSdoUpRespMsg{
//   BlecanRespHead blecanRespHead;
//   SdoUpRespDirectMsg sdoUpRespMsg;
//
//   BlecanSdoUpRespMsg(this.blecanRespHead,this.sdoUpRespMsg);
//
//   factory BlecanSdoUpRespMsg.fromData(List<int> vs){
//
//     BlecanRespHead blecanRespHead = BlecanRespHead.fromBytes(vs);
//     SdoUpRespDirectMsg sdoUpRespHead = SdoUpRespDirectMsg.fromData(vs.sublist(5));
//
//     return BlecanSdoUpRespMsg(blecanRespHead, sdoUpRespHead);
//   }
//
//
// }