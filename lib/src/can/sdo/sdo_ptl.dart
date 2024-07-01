
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_xio/src/can/sdo/sdo_def.dart';
import 'package:flutter_xio/src/can/sdo/sdo_io.dart';
import 'package:flutter_xio/src/utils/catcher.dart';

import '../blecan_def.dart';

class SdoPtl{

  SdoIo sdoIo;

  SdoPtl(this.sdoIo);

  static dynamic decodeResp(List<int> vs){

    int v = vs[0];
    
    int cs = SdoHeadCs.rslvHeadCs(v);


    print('cs: $cs');

    switch(cs){
      case SdoDownRespDirectMsg.scs:
        return SdoDownRespDirectMsg.load(vs);
      case SdoDownRespSegMsg.scs:
        return SdoDownRespSegMsg.load(vs);
      case SdoUpRespDirectMsg.scs:
        return SdoUpRespDirectMsg.load(vs);
      case SdoUpRespSegMsg.scs:
        return SdoUpRespSegMsg.load(vs);
      default:
        return null;
    }

  }

  static List<int> encodeUpReq(int mIndex,int sIndex){

    SdoMsg msg = SdoUpReqDirectMsg(mIndex,sIndex);

    return msg.dump;

  }



  Future<List<int>?> upload(int nodeId, int mIndex,int sIndex, {int retry = 3, int timeout = 1000}) async {

    SdoUpReqDirectMsg uqd = SdoUpReqDirectMsg(mIndex,sIndex);
    List<int>? rData = await sdoIo.call(nodeId, uqd.dump);
    if (rData == null) return null;

    print('rdata: $rData , ');

    SdoUpRespDirectMsg? urd = Catcher.call<SdoUpRespDirectMsg>(()=>SdoUpRespDirectMsg.load(rData));

    print('urd: $urd');
    print('urd: ${urd?.data} ');

    if (urd == null ) return null;

    // direct
    if (urd.e == 1 && urd.s == 1){
      return rData.sublist(4,8-urd.n);
    }else if(urd.e == 1){
      return rData.sublist(4,8);
    }

    // segment
    List<int> rSegData = [];
    int t = 1;

    while(true){
      t = 1-t;

      SdoUpReqSegMsg uqs = SdoUpReqSegMsg( t, [0,0,0,0,0,0,0]);

      List<int>? rData = await sdoIo.call(nodeId, uqs.dump);
      if (rData == null) return null;

      SdoUpRespSegMsg? uss = Catcher.call<SdoUpRespSegMsg>(()=>SdoUpRespSegMsg.load(rData));
      if (uss == null) return null;

      if (uss.t != t) continue;

      rSegData.addAll(uss.data);

      print('uss c: ${uss.c}');

      if (uss.c == 1){
        return rSegData;
      }

    }

  }

}