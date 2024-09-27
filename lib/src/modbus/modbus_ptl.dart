// Modbus协议
// https://zhuanlan.zhihu.com/p/145546574

import 'dart:typed_data';
import 'package:flutter_xio/src/modbus/modbus_def.dart';
import 'package:tuple/tuple.dart';

class ModbusPtl{

  // static Uint8List modbusWriteMultiRegister(int slave, int start, Uint16List value){
  //   return rtu0x10(slave, start, value);
  // }


  static Uint8List rtu0x10(int slave, int start, Uint16List value){

    assert(slave >= 0 && slave <= 247);

    var pdu = pdu0x10(start, value);

    Uint8List data = Uint8List(pdu.length + 1 + 2);

    data[0] = slave;

    for(int i=0; i< pdu.length; i++) {
      data[1+i] = pdu[i];
    }

    crc16(data);

    return data;
  }

  // 功能码0x10,写多个寄存器
  static Uint8List pdu0x10(int start, Uint16List value){
    var size = value.length;

    assert(start >= 0 && start <= 0xffff );
    assert(size >= 1 && size <= 0x0078);
    assert(value.length == size);

    // 功能码 + 起始地址 + 寄存器数量 + 字节数 + 寄存器值
    Uint8List data = Uint8List(1 + 2 + 2 + 1 + size*2);
    data[0] = 0x10;
    data[1] = 0xff & (start>>8);
    data[2] = 0xff & start;
    data[3] = 0xff & (size>>8);
    data[4] = 0xff & size;
    data[5] = 0xff & (size*2);

    for(int i=0; i< value.length; i++) {
      data[6 + i*2] = 0xff & (value[i]>>8);
      data[6 + i*2 + 1] = 0xff & value[i];
    }

    return data;

  }


  static Tuple4<int,int,int,int>? r_modbus_write(Uint8List msg){

    assert(msg.length == 8);

    var tmpdata = msg.sublist(0);

    var crc = msg[msg.length-2]<<8 | msg[msg.length-1];

    if (crc16(tmpdata) == crc ){
      return Tuple4(msg[0],msg[1], byte2int(msg[3], msg[2]),byte2int(msg[5], msg[4]) );
    }else{
      print('crc failed.');
      return null;
    }
  }

  static Tuple3<int,int,Uint16List>? r_modbus_read(Uint8List msg){

    var todata = msg.sublist(3,msg.length-2);
    var tmpdata = msg.sublist(0);


    var crcH = msg[msg.length-2];
    var crcL = msg[msg.length-1];

    int crc = crc16(tmpdata);

    if ((0xff & (crc>>8)) == crcH && (0xff & crc) == crcL ){
      return Tuple3(msg[0],msg[1], byte2register(todata));
    }else{
      print('crc failed： $crc');
      return null;
    }
 }

  static Uint8List readInputRegister(int slave,int addr,int size){
    Uint8List data = Uint8List(4);

    data[0] = 0xff & addr>>8 ;
    data[1] = 0xff & addr;
    data[2] = 0xff & size>>8;
    data[3] = 0xff & size;

    return modbus(slave, 0x04, data);

  }
  static Uint8List readHoldingRegister(int slave, int addr,int size){
    Uint8List data = Uint8List(4);

    data[0] = 0xff & addr>>8 ;
    data[1] = 0xff & addr;
    data[2] = 0xff & size>>8;
    data[3] = 0xff & size;

    return modbus(slave, 0x03, data);

  }


  // static Uint8List readZeroRegister(int slave){
  //   Uint8List data = Uint8List(4);
  //
  //   data[0] = 0x00;
  //   data[1] = 0x00;
  //   data[2] = 0x00;
  //   data[3] = 0x0a;
  //
  //   return modbus(slave, 0x03, data);
  // }



  static Uint8List writeRegister(int slave, int addr,Uint16List data){

    var size = data.length;

    Uint8List todata = Uint8List(data.length*2 + 5);

    todata[0] = 0xff & addr>>8 ;
    todata[1] = 0xff & addr;
    todata[2] = 0xff & size>>8;
    todata[3] = 0xff & size;
    todata[4] = data.length *2;

    for(var i=0; i<data.length; i++) {
      todata[5 + i*2] = 0xff & (data[i] >> 8) ;
      todata[5 + i*2 + 1] = 0xff & data[i] ;
    }

    return modbus(slave, 0x10, todata);

  }

  // static Uint8List callRegister(int slave, Uint16List data){
  //
  //
  //   return writeRegister(slave, 0, data);
  //
  // }

  // static Uint8List callRegisterWithAddress(int slave, int address, Uint16List data){
  //
  //
  //   return writeRegister(slave, address, data);
  //
  // }

  // static Uint8List saveRegister(int slave){
  //
  //   Uint16List saveRegs = Uint16List.fromList([0x11,0x02,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]);
  //   // Uint8List data = register2byte(SAVE_REGS);
  //
  //   return writeRegister(slave, 0, saveRegs);
  //
  // }


  // static Uint8List upgradeStartByAddr(int slave, Uint8List addr ){
  //   assert(addr.length == 4);
  //
  //   return iap2modbus(slave,0x10,iap(0x70,0x00,0x00,addr)) ;
  // }



  // static Uint8List iap(int type,int subtype, int sn , Uint8List data ){
  //   assert(data.length <= 16);
  //
  //   var todata = Uint8List(20);
  //   todata[0] = type;
  //   todata[1] = (subtype & 0x0f) + ((data.length-1) << 4) ;
  //   todata[2] = sn;
  //   for (int i=0; i<data.length;i++) {
  //     todata[3+i] = data[i];
  //   }
  //
  //   crc8(todata);
  //
  //   return todata;
  // }


  // static Uint8List iap2modbus(int slave,int func, Uint8List data){
  //
  //   assert(data.length == 20);
  //
  //   var todata = Uint8List(25);
  //
  //   todata[0] = 0;
  //   todata[1] = 0;
  //   todata[2] = 0;
  //   todata[3] = 0x0a;
  //   todata[4] = 0x14;
  //
  //   for(var i=0; i<data.length; i++){
  //     var b = data[i];
  //     if (i%2 == 0){
  //       todata[6+i] = b;
  //     }else{
  //       todata[4+i] = b;
  //     }
  //   }
  //
  //   return modbus(slave, func, todata);
  //
  // }

  static Uint8List modbus(int slave, int func , Uint8List data){

    var todata = Uint8List(4 + data.length);

    todata[0] = slave;
    todata[1] = func;

    for(var i=0; i<data.length; i++) {
      todata[2+i] = data[i];
    }

    crc16(todata);

    return todata;
  }

  static int crc8(Uint8List data){
    var ret = 0;
    for (int i=0; i< data.length-1; i++){
      ret += data[i];
    }
    ret = ret & 0xff;

    data[data.length-1] = ret;

    return ret;
  }

  //校验
  static int crc16(Uint8List data) {

    int crctemp;
    int crc = 0x0000ffff;

    for (int i = 0;i < data.length - 2 ; i++) {

      crc ^= data[i] & 0xff;
      for (int j = 0;j < 8;j++) {
        if ((crc & 0x01) != 0) {
          crc >>= 1;
          crc ^= 0x0000a001;
        }else {
          crc >>= 1;
        }
      }
    }

    crctemp = crc;
    crc = ((crctemp << 8) | (crc>>8))&0x0000ffff;

    data[data.length-2] = crc >> 8 & 0x00ff ;
    data[data.length-1] = crc & 0x00ff ;

    return crc;
  }

  static Uint8List register2byte(Uint16List reg){
    Uint8List todata = Uint8List(reg.length *2);

    for (int i=0; i< reg.length; i++){
      todata[i*2] = (reg[i] >> 8) & 0xff ;
      todata[i*2+1] = reg[i] & 0xff ;
    }

    return todata;
  }
  static Uint16List byte2register(Uint8List byte){
    // if (byte.length % 2 != 0) return Uint16List(0);

    // assert(byte.length % 2 == 0);
    int len = byte.length ~/ 2;

    Uint16List todata = Uint16List( len);

    for (int i=0; i< len; i++){
      todata[i] =  byte[i*2] << 8 | byte[i*2+1];
    }

    return todata;
  }

  static int byte2int(l,h){
    return l | (h<<8);
  }

}
