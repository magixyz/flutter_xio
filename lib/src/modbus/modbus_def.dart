
abstract class RtuMsg{
  late int slave;
  late int func;
  late int crc;

  RtuMsg(this.slave,this.crc,{required this.func});
  RtuMsg.load(List<int> vs){
    slave = vs[0];
    func = vs[1];

  }

  List<int> dump();
}

abstract class RtuReqMsg extends RtuMsg{
  late int addr;

  RtuReqMsg(this.addr, super.slave, super.crc,{required super.func});

}

abstract class RtuResMsg extends RtuMsg{

  bool verify(List<int> vs);


  RtuResMsg.load(List<int> vs):super.load(vs){
    if (!verify(vs)) throw Exception('verify error when load response!');
  }

}

abstract class RtuReadMultiReqMsg extends RtuReqMsg{

  late int size;

  RtuReadMultiReqMsg(this.size, super.addr, super.slave, super.crc, {required super.func});
}

abstract class RtuReadMultiResMsg extends RtuResMsg{

  late RtuReadMultiReqMsg reqMsg;

  RtuReadMultiResMsg.load(List<int> vs, this.reqMsg):super.load(vs);

  @override
  bool verify(List<int> vs){
    if (reqMsg.size *2 + 5 != vs.length) return false;
    if (reqMsg.slave != vs[0]) return false;
    if (reqMsg.func != vs[1]) return false;

    return true;
  }
}


abstract class RtuWriteMultiReqMsg extends RtuReqMsg{

  late int size;

  RtuWriteMultiReqMsg(this.size , super.addr, super.slave, super.crc, {required super.func});
}

abstract class RtuWriteMultiResMsg extends RtuResMsg{

  late RtuWriteMultiReqMsg reqMsg;

  RtuWriteMultiResMsg.load(List<int> vs, this.reqMsg):super.load(vs);

  @override
  bool verify(List<int> vs){
    if ( 5 != vs.length) return false;
    if (reqMsg.slave != vs[0]) return false;
    if (reqMsg.func != vs[1]) return false;

    return true;
  }
}



class RtuReadMultiHoldingReqMsg extends RtuReadMultiReqMsg{
  static const int FUNC = 0x03;

  RtuReadMultiHoldingReqMsg(super.size, super.addr , super.slave, super.crc , {super.func=FUNC});

  @override
  List<int> dump() {
    List<int> vs = [];

    vs.add(slave);
    vs.add(func);

    return vs;
  }


}
class RtuReadMultiHoldingResMsg extends RtuReadMultiResMsg{
  static const int FUNC = 0x03;

  late List<int> data;

  RtuReadMultiHoldingResMsg.load(super.vs, super.reqMsg):super.load();

  @override
  List<int> dump() {
    // TODO: implement dump
    throw UnimplementedError();
  }
}


class RtuReadMultiInputReqMsg extends RtuReadMultiReqMsg{
  static const int FUNC = 0x04;

  RtuReadMultiInputReqMsg(super.size, super.addr , super.slave, super.crc , {super.func=FUNC});

  @override
  List<int> dump() {
    // TODO: implement dump
    throw UnimplementedError();
  }

}

class RtuReadMultiInputResMsg extends RtuReadMultiResMsg{
  static const int FUNC = 0x04;

  late List<int> data;


  RtuReadMultiInputResMsg.load(super.vs,super.reqMsg):super.load();

  @override
  List<int> dump() {
    // TODO: implement dump
    throw UnimplementedError();
  }

}

class RtuWriteMultiHoldingReqMsg extends RtuWriteMultiReqMsg{
  static const int FUNC = 0x10;

  late List<int> data;

  RtuWriteMultiHoldingReqMsg(super.size, super.addr , super.slave, super.crc , {super.func=FUNC});

  @override
  List<int> dump() {
    // TODO: implement dump
    throw UnimplementedError();
  }
}

class RtuWriteMultiHoldingResMsg extends RtuWriteMultiResMsg{
  static const int FUNC = 0x10;


  RtuWriteMultiHoldingResMsg.load(super.vs,super.r):super.load(){

  }

  @override
  List<int> dump() {
    // TODO: implement dump
    throw UnimplementedError();
  }
}
