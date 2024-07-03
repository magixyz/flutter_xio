
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

  // static List<int> encodeUpReq(int mIndex,int sIndex){
  //
  //   SdoMsg msg = SdoUpReqDirectMsg(mIndex,sIndex);
  //
  //   return msg.dump;
  //
  // }



  Future<List<int>?> upload(int nodeId, int mIndex,int sIndex, {int retry = 3, int timeout = 1000}) async {

    SdoUpReqDirectMsg uqd = SdoUpReqDirectMsg(mIndex,sIndex,[]);
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


  Future<bool> download(int nodeId, int mIndex,int sIndex, List<int> data, {int retry = 3, int timeout = 1000}) async {

    if (data.length <= 4){
      SdoDownReqDirectMsg dqd = SdoDownReqDirectMsg(4-data.length,1,1,mIndex,sIndex,data);
      List<int>? rData = await sdoIo.call(nodeId, dqd.dump);
      if (rData == null) return false;
      SdoDownRespDirectMsg? dsd = Catcher.call<SdoDownRespDirectMsg>(()=>SdoDownRespDirectMsg.load(rData));
      if (dsd == null) return false;

      return true;

    }else{
      ByteData bd = ByteData(4);
      bd.setUint32(0 ,data.length ,Endian.little);
      List<int> dd = bd.buffer.asUint8List();


      SdoDownReqDirectMsg dqd = SdoDownReqDirectMsg(0,0,1,mIndex,sIndex,dd);
      List<int>? rData = await sdoIo.call(nodeId, dqd.dump);
      if (rData == null) return false;
      SdoDownRespDirectMsg? dsd = Catcher.call<SdoDownRespDirectMsg>(()=>SdoDownRespDirectMsg.load(rData));
      if (dsd == null ) return false;

      // segment
      int sSegDataIndex = 0;
      int t = 1;

      while(true){
        t = 1-t;


        if (sSegDataIndex >= data.length) return true;
        int len = data.length - sSegDataIndex;
        int c = 1;
        if (len > 7){
          len = 7;
          c = 0;
        }

        List<int> sData = data.sublist(sSegDataIndex, sSegDataIndex + len);

        print('seg send index: $sSegDataIndex , data: ${sData} , data: ${data} , len:$len');
        SdoDownReqSegMsg dqs = SdoDownReqSegMsg( t, 7 - len , c, sData);

        List<int>? rData = await sdoIo.call(nodeId, dqs.dump);
        if (rData == null) return false;

        SdoDownRespSegMsg? dss = Catcher.call<SdoDownRespSegMsg>(()=>SdoDownRespSegMsg.load(rData));
        if (dss == null) return false;

        if (dss.t != t) continue;

        sSegDataIndex += len;

      }
    }





  }

}