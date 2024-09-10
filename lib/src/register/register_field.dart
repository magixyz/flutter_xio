

import 'dart:convert';
import 'dart:typed_data';

import '../enum/byte_loc.dart';

enum FieldType{
  float,short,ushort,int,uint,ulong,byte,bit,bits,string,hex
}

abstract class RegisterField {

  factory RegisterField.instance(String key, Map<String,dynamic> json){

    FieldType type = FieldType.values.byName(json['type']);

    String? name = json['name'];
    int offset = json['offset'];
    int size = json['size'];

    String? tag = json['tag'];
    List? selection = json['selection'];

    switch(type){
      case FieldType.float:
        return FloatField(key, type,name,offset,size,tag: tag,selection: selection);
      case FieldType.short:
        return ShortField(key, type,name,offset,size,tag: tag,selection: selection);
      case FieldType.ushort:
        return UshortField(key, type,name,offset,size,tag: tag,selection: selection);
      case FieldType.int:
        return IntField(key, type,name,offset,size,tag: tag,selection: selection);
      case FieldType.uint:
        return UintField(key, type,name,offset,size,tag: tag,selection: selection);
      case FieldType.ulong:
        return UlongField(key, type,name,offset,size,tag: tag,selection: selection);
      case FieldType.byte:
        ByteLoc bytePos = ByteLoc.values.byName(json['byte_pos']);
        return ByteField(key, type,name,offset,size,bytePos,tag: tag,selection: selection);
      case FieldType.bits:
        List<dynamic> bitsRange = json['bits_range'];
        return BitsField(key, type,name,offset,size, bitsRange ,tag: tag,selection: selection);
      case FieldType.bit:
        int bitPos = json['bit_pos'];
        return BitField(key, type,name,offset,size, bitPos,tag: tag,selection: selection);
      case FieldType.string:
        return StringField(key, type,name,offset,size,tag: tag,selection: selection);
      case FieldType.hex:
        return HexField(key, type,name,offset,size,tag: tag,selection: selection);
      default:
        throw Exception("Register type error in json config.");
    }
  }

  FieldType type;

  String? name;
  String key;

  int offset;
  int size;

  String? tag;
  List? selection;

  dynamic readValue;
  dynamic writeValue;

  RegisterField(this.key, this.type, this.name, this.offset,this.size,{this.tag, this.selection});

  read(Uint16List data){
    if (size != data.length) throw Exception('Data length[${data.length}] not match with size[$size]');

    print('uint16list: ${data}');

    ByteData tmp = _Uint16List2ByteData(data);

    print('ByteData: ${tmp.buffer.asInt8List()}');

    _read(tmp);
  }
  _read(ByteData tmp);

  write(Uint16List data){
    if (size != data.length) throw Exception('Data length should match with size');

    var tmp = _Uint16List2ByteData(data);

    _write(tmp);

    _ByteData2Uint16List(data,tmp);
  }

  _write(ByteData tmp);

  _Uint16List2ByteData(Uint16List data){

    var tmp = ByteData(data.length*2);
    for (int i=0;i< data.length; i++) tmp.setUint16(i*2, data[i],Endian.little);

    return tmp;
  }
  _ByteData2Uint16List(Uint16List data,ByteData tmp){

    if (data.length*2 != tmp.lengthInBytes) throw Exception('Uint16List length should match with ByteData length');

    for (int i=0; i< data.length; i++) data[i] = tmp.getUint16(i*2,Endian.little);
  }
}

class FloatField extends RegisterField{

  FloatField(String key, FieldType type, String? name, int addr,int size,
      {String? tag, List? selection})
      :super(key,type,name,addr,size){
    if (2 != size) throw Exception("The float type's size should be 2 in the json.");
  }

  @override
  _read(ByteData tmp) {
    readValue = tmp.getFloat32(0,Endian.little);
  }

  @override
  _write(ByteData tmp) {
    tmp.setFloat32(0, writeValue,Endian.little);
  }
}


class ShortField extends RegisterField{
  ShortField(String key, FieldType type, String? name, int addr,int size,
      {String? tag, List? selection})
      :super(key,type,name,addr,size){
    if (1 != size) throw Exception("The short type's size should be 1 in the json.");
  }

  @override
  _read(ByteData tmp) {
    readValue = tmp.getInt16(0,Endian.little);
  }

  @override
  _write(ByteData tmp) {
    tmp.setInt16(0, writeValue,Endian.little);
  }
}


class UshortField extends RegisterField{
  UshortField(String key, FieldType type, String? name, int addr,int size,
      {String? tag, List? selection})
      :super(key,type,name,addr,size){
    if (1 != size) throw Exception("The short type's size should be 1 in the json.");
  }

  @override
  _read(ByteData tmp) {
    readValue = tmp.getUint16(0,Endian.little);
  }

  @override
  _write(ByteData tmp) {
    tmp.setUint16(0, writeValue,Endian.little);
  }
}


class IntField extends RegisterField{
  IntField(String key, FieldType type, String? name, int addr,int size,
      {String? tag, List? selection})
      :super(key,type,name,addr,size){
    if (2 != size) throw Exception("The int type's size should be 2 in the json.but is:$size");
  }

  @override
  _read(ByteData tmp) {
    readValue = tmp.getInt32(0,Endian.little);
  }

  @override
  _write(ByteData tmp) {
    tmp.setInt32(0, writeValue,Endian.little);
  }
}

class UintField extends RegisterField{
  UintField(String key, FieldType type, String? name, int addr,int size,
      {String? tag, List? selection})
      :super(key,type,name,addr,size){
    if (2 != size) throw Exception("The uint type's size should be 2 in the json.");
  }

  @override
  _read(ByteData tmp) {
    readValue = tmp.getUint32(0,Endian.little);
  }

  @override
  _write(ByteData tmp) {
    tmp.setUint32(0, writeValue,Endian.little);
  }
}


class UlongField extends RegisterField{
  UlongField(String key, FieldType type, String? name, int addr,int size,
      {String? tag, List? selection})
      :super(key,type,name,addr,size){
    if (4 != size) throw Exception("The int type's size should be 4 in the json.");
  }

  @override
  _read(ByteData tmp) {

    readValue = tmp.getUint64(0,Endian.little);

  }

  @override
  _write(ByteData tmp) {
    tmp.setUint64(0, writeValue,Endian.little);
  }
}

class ByteField extends RegisterField{

  ByteLoc bytePos;

  ByteField(String key, FieldType type, String? name, int addr,int size,this.bytePos,
      {String? tag, List? selection})
      :super(key,type,name,addr,size){
    if (1 != size) throw Exception('Data length should match with size');

  }

  @override
  _read(ByteData tmp) {

    if (ByteLoc.low == bytePos){
      readValue = tmp.getUint8(0);
    }else if(ByteLoc.high == bytePos){
      readValue = tmp.getUint8(1);
    }else{
      throw Exception('Enum iteration error');
    }
  }

  @override
  _write(ByteData tmp) {

    if (ByteLoc.low == bytePos) {
      tmp.setUint8(0, writeValue);
    } else if (ByteLoc.high == bytePos) {
      tmp.setUint8(1, writeValue);
    } else {
      throw Exception('Enum iteration error');
    }
  }
}

class BitField extends RegisterField{

  int bitPos;
  late int mask;


  BitField(String key, FieldType type, String? name, int addr,int size,this.bitPos,
      {String? tag, List? selection})
      :super(key,type,name,addr,size){
    mask = 1 << bitPos;
  }

  @override
  _read(ByteData tmp) {
    readValue = (tmp.getUint16(0) & mask) >> bitPos;
  }

  @override
  _write(ByteData tmp) {
    int v = tmp.getUint16(0);

    if (writeValue){
      v |= mask;
    }else{
      v &= ~mask;
    }

    tmp.setUint16(0, v);
  }
}

class BitsField extends RegisterField{

  List<dynamic> bitsRange;

  late int mask;

  BitsField(String key, FieldType type, String? name, int addr,int size,this.bitsRange,
      {String? tag, List? selection})
      :super(key,type,name,addr,size){
    mask = ((1 << (bitsRange[1]-bitsRange[0])) - 1) << bitsRange[0];
  }

  @override
  _read(ByteData tmp) {
    readValue = (tmp.getUint16(0) & mask) >> bitsRange[0];
  }

  @override
  _write(ByteData tmp) {
    int v = tmp.getUint16(0);

    v &= ~mask;
    v |= (writeValue << bitsRange[0]) & mask;

    tmp.setUint16(0, v);
  }

}

class StringField extends RegisterField{
  StringField(String key, FieldType type, String? name, int addr,int size,
      {String? tag, List? selection})
      :super(key,type,name,addr,size);

  @override
  _read(ByteData tmp) {
    // for (int i=0; i< tmp.lengthInBytes/2; i++) tmp.setUint16(i*2, tmp.getUint16(i*2,Endian.little));

    readValue = String.fromCharCodes(tmp.buffer.asInt8List()).replaceAll(String.fromCharCode(0) , '');
  }

  @override
  _write(ByteData tmp) {
    List<int> list = utf8.encode(writeValue);
    for (int i=0; i< list.length; i++) tmp.setUint8(i, list[i]);
  }
}

class HexField extends RegisterField{
  HexField(String key, FieldType type, String? name, int addr,int size,
      {String? tag, List? selection})
      :super(key,type,name,addr,size);

  @override
  _read(ByteData tmp) {
    readValue = tmp.buffer.asUint8List().map((e) => e.toRadixString(16).padLeft(2, "0")).join();
  }

  @override
  _write(ByteData tmp) {

    String v = writeValue;
    
    if (v.length % 2 != 0 ) throw Exception('Hex string format error');
    if (v.length/2 > tmp.lengthInBytes) throw Exception('Hex string length exceed size');

    for (int i=0; i< v.length/2; i++){
      int value = int.parse(v.substring(i*2,i+2),radix: 16);
      tmp.setInt8(i, value);
    }

  }
}
