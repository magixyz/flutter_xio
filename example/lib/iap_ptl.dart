
import 'dart:typed_data';

class IapPtl{




  static Uint8List iap(int type,int subtype, int sn , Uint8List data ){
    assert(data.length <= 16);

    var todata = Uint8List(20);
    todata[0] = type;
    todata[1] = (subtype & 0x0f) + ((data.length-1) << 4) ;
    todata[2] = sn;
    for (int i=0; i<data.length;i++) {
      todata[3+i] = data[i];
    }

    crc8(todata);

    return todata;
  }


  // static Uint8List iap2modbus(int addr,int func, Uint8List data){
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
  //   return modbus(addr, func, todata);
  //
  // }

  static int crc8(Uint8List data){
    var ret = 0;
    for (int i=0; i< data.length-1; i++){
      ret += data[i];
    }
    ret = ret & 0xff;

    data[data.length-1] = ret;

    return ret;
  }

  static int crc16(Uint8List data){
    var ret = 0;
    for (int i=0; i< data.length-1; i++){
      ret += data[i];
    }
    ret = ret & 0xffff;

    data[data.length-2] = ret & 0xff;
    data[data.length-1] = (ret >> 8) & 0xff;

    return ret;
  }

  static Uint16List iapByte2register(Uint8List byte){
    assert(byte.length % 2 == 0);
    int len = byte.length ~/ 2;

    Uint16List todata = Uint16List( len);

    for (int i=0; i< len; i++){
      todata[i] =  byte[i*2] | (byte[i*2+1]<< 8);
    }

    return todata;
  }

  static int byte2int(l,h){
    return l | (h<<8);
  }

  static Uint8List int2bytes(int value,int size){
    Uint8List data = Uint8List(size);

    for (int i=0; i< size; i++){
      data[i] = 0xff & (value >> (8*i));
    }

    return data;
  }

  static int bytes2int(Uint8List bytes){
    int ret = 0;
    for (int i=0; i< bytes.length; i++){
      var b = bytes[i];
      ret |= (b<<(8*i));
    }

    return ret;
  }

}
