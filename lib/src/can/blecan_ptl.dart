
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class BlecanPtl {

  static Uint16List byte2register(Uint8List byte){

    int len = byte.length ~/ 2;

    Uint16List todata = Uint16List( len);

    for (int i=0; i< len; i++){
      todata[i] =  byte[i*2 + 1] << 8 | byte[i*2];
    }

    return todata;
  }
  static Uint8List register2byte(Uint16List r){

    int len = r.length ;

    Uint8List todata = Uint8List( len*2);

    for (int i=0; i< len; i++){
      todata[i*2] =  r[i] & 0xff;
      todata[i*2+1] =  r[i] >> 8 ;
    }

    return todata;
  }

}