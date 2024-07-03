
import 'package:flutter_xio/src/utils/hex_util.dart';

class SdoHeadCs{
  static int rslvHeadCs(int v){

    print('cs v1: $v');

    int cs = (v>>5) & 0x07;


    print('cs v2: $cs');

    return cs;
  }
}
//
// class SdoIndex{
//   late int mIndex;
//   late int sIndex;
//
//   SdoIndex(this.mIndex,this.sIndex);
//
//   SdoIndex.load(List<int> index){
//
//     mIndex = index[0] + (index[1]<<8);
//     sIndex = index[2];
//   }
//
//   List<int> get dump{
//     List<int> vs = [];
//     vs.add(mIndex & 0xff);
//     vs.add(mIndex >> 8) ;
//     vs.add(sIndex);
//
//     return vs;
//   }
// }

abstract class SdoMsg{

  late int cs;
  late List<int> data ;

  int get dumpHead;
  List<int> get dumpData;
  List<int> get dump;

  SdoMsg( this.data, {required this.cs });

  SdoMsg.load(List<int> vs){
    
    print('sdo data: ${HexUtil.byte2hex(vs)}');
    print('sdo head: ${vs[0].toRadixString(2)}');

    cs = (vs[0] >> 5);
  }

}


abstract class SdoDirectMsg extends SdoMsg{
  // late SdoIndex index;

  late int mIndex;
  late int sIndex;


  SdoDirectMsg( this.mIndex,this.sIndex, super.data, {required super.cs});

  SdoDirectMsg.load(List<int> vs):super.load(vs){
    mIndex = vs[1] + (vs[2]<<8);
    sIndex = vs[3];
  }

  List<int> get dumpIndex{
    List<int> vs = [];
    vs.add(mIndex & 0xff);
    vs.add(mIndex >> 8) ;
    vs.add(sIndex);

    return vs;
  }

  @override
  List<int> get dump{
    List<int> vs = [];

    vs.add(dumpHead);
    vs.addAll(dumpIndex);
    vs.addAll(dumpData);

    return vs;
  }

  @override
  List<int> get dumpData{
    List<int> ret = [];
    ret.addAll(data);
    while(ret.length < 4) ret.add(0);

    return ret;
  }
}

abstract class SdoSegMsg extends SdoMsg{

  // late List<int> seg;

  SdoSegMsg( super.data, {required super.cs} );

  SdoSegMsg.load(List<int> vs):super.load(vs);


  @override
  List<int> get dump{
    List<int> vs = [];

    vs.add(dumpHead);
    vs.addAll(dumpData);

    return vs;
  }

  @override
  List<int> get dumpData{
    List<int> ret = [];
    ret.addAll(data);
    while(ret.length < 7) ret.add(0);

    return ret;
  }
}


class SdoDownReqDirectMsg extends SdoDirectMsg{
  // [7,6,5] 1：下载启动请求
  static const int ccs = 1;
  // [4] 不使用，始终为0
  late int x = 0;

  // [3,2] 有效仅当 e = 1,s = 1,否则为 0。如果有效的话，它表示 d 中不带数据的字节数。字节[8-n，7]不包含数据。
  late int n ;
  // [1]
  // 传输类型
  // 0: 正常传输
  // 1: 快速传输
  late int e ;
  // [0]
  // 大小说明
  // 0: 数据集大小不指明
  // 1: 数据集大小明确指出
  late int s ;


  SdoDownReqDirectMsg(this.n,this.e,this.s,super.mIndex,super.sIndex,super.data,{super.cs=ccs });

  SdoDownReqDirectMsg.load(List<int> vs):super.load(vs){

    if (vs.length != 8) throw Exception('data length should be 8 !');

    int v = vs[0];

    n = (v >> 2) & 0x03;
    e = (v >> 1) & 0x01;
    s = v & 0x01;

  }

  @override
  int get dumpHead{
    int v = 0;
    v |= ccs << 5;
    v |= x << 4;
    v |= n << 2;
    v |= e << 1;
    v |= s;

    return v;
  }




}

class SdoDownRespDirectMsg extends SdoDirectMsg{
  static const int scs = 3;
  int x = 0;

  SdoDownRespDirectMsg(super.mIndex,super.sIndex,super.data,{super.cs=scs});
  
  SdoDownRespDirectMsg.load(List<int> vs):super.load(vs){

    if (scs != cs) throw Exception('cs error, $scs != $cs ');

    data = [];
  }
  
  @override
  int get dumpHead{
    int v = 0;
    v |= scs << 5;

    return v;
  }


}


class SdoDownReqSegMsg extends SdoSegMsg{
  // [7,6,5] 1：下载启动请求
  static const int ccs = 0;

  // [4] 翻转位，第一个分段置0
  late int t ;

  // [3,1] Seg-data中不包含分段数据的字节数。字节[8-n，7]不包含数据。
  late int n ;

  // [0]
  // 是否还有要下载的分段
  // 0: 更多的分段需要被下载
  // 1: 没有更多的分段需要被下载
  late int c ;

  SdoDownReqSegMsg(this.t,this.n,this.c ,super.data,{super.cs=ccs});

  SdoDownReqSegMsg.load(List<int> vs):super.load(vs.sublist(1,8)){
    int v = vs[0];
    
    t = (v >> 4) & 0x01;
    n = (v >> 1) & 0x07;
    c = v & 0x01;

  }

  @override
  int get dumpHead{
    int v = 0;
    v |= ccs << 5;
    v |= t << 4;
    v |= n << 1;
    v |= c;

    return v;
  }


}

class SdoDownRespSegMsg extends SdoSegMsg {
  static const int scs = 1;

  // [4]
  late int t ;

  // [3,2,1,0]
  late int x = 0;

  SdoDownRespSegMsg( this.t , super.data, {super.cs=scs});

  SdoDownRespSegMsg.load(List<int> vs):super.load(vs){
    int v = vs[0];
    t = (v >> 4) & 0x01;
  }

  @override
  int get dumpHead{
    int v = 0;
    v |= scs << 5;
    v |= t << 4;

    return v;
  }


}


class SdoUpReqDirectMsg extends SdoDirectMsg {
 static const int ccs = 2;
 int x = 0;


 SdoUpReqDirectMsg( super.mIndex,super.sIndex,super.data, {super.cs= ccs});

 SdoUpReqDirectMsg.load(List<int> vs):super.load(vs){
   data = [];
 }

 @override
 int get dumpHead{
   int v = 0;
   v |= ccs << 5;

   return v;
 }

}

class SdoUpRespDirectMsg extends SdoDirectMsg {
// [7,6,5] 1：上传启动响应
  static const int scs = 2;
  // [4] 不使用，始终为0
  int x = 0;

  // [3,2] 有效仅当 e = 1,s = 1,否则为 0。如果有效的话，它表示 d 中不带数据的字节数。字节[8-n，7]不包含数据。
  late int n ;
  // [1]
  // 传输类型
  // 0: 正常传输
  // 1: 快速传输
  late int e ;
  // [0]
  // 大小说明
  // 0: 数据集大小不指明
  // 1: 数据集大小明确指出
  late int s ;

  SdoUpRespDirectMsg( this.n,this.e,this.s ,super.mIndex,super.sIndex,super.data, {super.cs= scs});

  SdoUpRespDirectMsg.load(List<int> vs):super.load(vs ){
    int v = vs[0];

    if (scs != cs) throw Exception('cs error, $scs != $cs ');
    
    n = (v >> 2) & 0x03;
    e = (v >> 1) & 0x01;
    s = v & 0x01;


    data = vs.sublist(4, 8- n);
  }

  @override
  int get dumpHead{
    int v = 0;
    v |= scs << 5;
    v |= x << 4;
    v |= n << 2;
    v |= e << 1;
    v |= s;

    return v;
  }


}


class SdoUpReqSegMsg extends SdoSegMsg {
  static const int scs = 3;

  // [4]
  late int t ;

  // [3,2,1,0]
  late int x = 0;

  SdoUpReqSegMsg(this.t, super.data,{super.cs= scs});

  SdoUpReqSegMsg.load(List<int> vs):super.load(vs){
    int v = vs[0];

    t = (v >> 4) & 0x01;

  }

  @override
  int get dumpHead{
    int v = 0;
    v |= scs << 5;
    v |= t << 4;

    return v;
  }

}


class SdoUpRespSegMsg extends SdoSegMsg {
  // [7,6,5]
  static const int scs = 0;

  // [4] 翻转位，第一个分段置0
  late int t ;

  // [3,1] Seg-data中不包含分段数据的字节数。字节[8-n，7]不包含数据。
  late int n ;

  // [0]
  // 是否还有要下载的分段
  // 0: 更多的分段需要被下载
  // 1: 没有更多的分段需要被下载
  late int c ;

  SdoUpRespSegMsg(this.t,this.n,this.c, super.data, {super.cs=scs});

  SdoUpRespSegMsg.load(List<int> vs):super.load(vs){
    int v = vs[0];
    t = (v >> 4) & 0x01;
    n = (v >> 1) & 0x07;
    c = v & 0x01;

    data = vs.sublist(1, 8- n);
  }

  @override
  int get dumpHead{
    int v = 0;
    v |= scs << 5;
    v |= t << 4;
    v |= n << 1;
    v |= c;

    return v;
  }

}