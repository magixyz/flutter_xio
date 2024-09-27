import 'dart:convert';
import 'dart:typed_data';

import 'package:crclib/catalog.dart';
import 'src/modbus/modbus_ptl.dart';

void main(){
  // print(Crc16().convert(utf8.encode('123456'))) ;

  Uint8List list = Uint8List.fromList([1, 4, 80, 101, 90, 114, 99, 97, 101, 32, 116, 111, 67, 44, 46, 116, 76, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 33, 0, 6, 0, 35, 0, 6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 155]);
  Uint8List list2 = Uint8List.fromList([1, 4, 80, 101, 90, 114, 99, 97, 101, 32, 116, 111, 67, 44, 46, 116, 76, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 155]);

  var crc1 = ModbusPtl.crc16(list);
  var crc2 = ModbusPtl.crc16(list2);

  print(crc1&0xff);
  print(crc1>>8 );
  print(crc2&0xff);
  print(crc2>>8 );


}
