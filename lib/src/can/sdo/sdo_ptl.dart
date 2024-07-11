
import 'dart:convert';
import 'dart:typed_data';

import 'package:crclib/catalog.dart';
import 'package:flutter_xio/src/can/sdo/sdo_def.dart';
import 'package:flutter_xio/src/can/sdo/sdo_io.dart';
import 'package:flutter_xio/src/utils/catcher.dart';

import '../blecan_def.dart';

class SdoPtl{

  SdoIo sdoIo;

  SdoPtl(this.sdoIo);


  Future<List<int>?> upload(int nodeId, int mIndex,int sIndex, {int retry = 3, int timeout = 1000}) async {

    print( '${DateTime.now()}: upload start , delay test');

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


        print( '${DateTime.now()}: upload end , delay test');

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



  Future<bool> blkDown(int nodeId, int mIndex,int sIndex, List<int> data, {int retry = 3, int timeout = 1000}) async {

    var crc = Crc16Acorn().convert(data);


    print('blk down data: $data');
    // var ccc = [
    //   Crc16A().convert(utf8.encode('123456789')),
    //   Crc16Acorn().convert(utf8.encode('123456789')),
    //   Crc16Arc().convert(utf8.encode('123456789')),
    //   Crc16AugCcitt().convert(utf8.encode('123456789')),
    //   Crc16Autosar().convert(utf8.encode('123456789')),
    //   Crc16B().convert(utf8.encode('123456789')),
    //   Crc16Buypass().convert(utf8.encode('123456789')),
    //   Crc16Ccitt().convert(utf8.encode('123456789')),
    //   Crc16CcittFalse().convert(utf8.encode('123456789')),
    //   Crc16CcittTrue().convert(utf8.encode('123456789')),
    //   Crc16Cdma2000().convert(utf8.encode('123456789')),
    //   Crc16CcittTrue().convert(utf8.encode('123456789')),
    //   Crc16CcittTrue().convert(utf8.encode('123456789'))
    // ];
    // print('crc: $crc, ${ccc }');

      ByteData bd = ByteData(4);
      bd.setUint32(0 ,data.length ,Endian.little);
      List<int> dd = bd.buffer.asUint8List();


      SdoBlkDownStartReqMsg bdsq = SdoBlkDownStartReqMsg(data.length, mIndex, sIndex);
      List<int>? rData = await sdoIo.call(nodeId, bdsq.buffer);
      if (rData == null) return false;
      SdoBlkDownStartResMsg? bdss = Catcher.call<SdoBlkDownStartResMsg>(()=>SdoBlkDownStartResMsg(Uint8List.fromList(rData!)));
      if (bdss == null ) return false;

      print('blk start: ${bdss.blksize}');

      int blksize = bdss.blksize;
      int index = 0;
      int padding = 0;

      while( index  < data.length ){

        int c = index + 7 >= data.length ? 1:0 ;

        int seqno = (index~/7 )  % blksize + 1 ;

        List<int> sData = data.sublist(index,data.length-index < 7? data.length: index + 7);

        if (sData.length< 7) {
          padding = 7- sData.length;

          List<int> l = Uint8List(7);
          l.setAll(0, sData);
          sData = l;
        }

        SdoBlkDownIngReqMsg bdiq = SdoBlkDownIngReqMsg( c,  seqno , sData);

        if (seqno == blksize ||  c == 1){
          rData = await sdoIo.call(nodeId, bdiq.buffer);
          if (rData == null) return false;

          SdoBlkDownIngResMsg? bdis = Catcher.call<SdoBlkDownIngResMsg>(()=>SdoBlkDownIngResMsg(Uint8List.fromList(rData!)));
          if (bdis == null) return false;

          print('seqno,ack:$seqno,  ${bdis.ackseq}');

          if (bdis.ackseq != seqno){
            throw Exception('send failed,ack failed.');
            continue;
            // print('send failed,ack failed.');
          }
        }else{
          await sdoIo.callWithoutRes(nodeId, bdiq.buffer);
        }

        index += 7;

      }

      print('padding: $padding');

      SdoBlkDownEndReqMsg bddq = SdoBlkDownEndReqMsg(padding ,crc.toBigInt().toInt());
      rData = await sdoIo.call(nodeId, bddq.buffer);
      if (rData == null) return false;
      SdoBlkDownEndResMsg? bdes = Catcher.call<SdoBlkDownEndResMsg>(()=>SdoBlkDownEndResMsg(Uint8List.fromList(rData!)));

      print('blk end: ${bdes?.ss}');


      return bdes?.ss == 1;

  }
}