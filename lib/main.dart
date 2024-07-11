import 'dart:convert';

import 'package:crclib/catalog.dart';

void main(){
  print(Crc16().convert(utf8.encode('123456'))) ;
}
