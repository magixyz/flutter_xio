
import 'dart:typed_data';

import 'package:flutter_xio/src/register/can_args.dart';

import '../enum/register_type.dart';
import 'register_field.dart';




class RegisterCluster {

  static RegisterCluster instance(String key, Map<String,dynamic> json){


    String? name = json['name'];
    int addr = json['addr'];
    int size = json['size'];

    RegisterType type = RegisterType.values.byName(json['register']);

    CanArgs? canArgs = json['can'] == null?null:CanArgs.load(json['can']);

    Map<String,RegisterField> fields = {};


    for (final e  in json['fields'].entries){
      RegisterField rf = RegisterField.instance(e.key, e.value);
      fields[e.key] = rf;
    }


    String? tag = json['tag'];

    return RegisterCluster(key, name, addr, size, type, fields,tag: tag,canArgs: canArgs);
  }


  String? name;
  String key;

  int addr;
  int size;
  RegisterType registerType ;

  CanArgs? canArgs;

  String? tag;

  Uint16List? readData;
  Uint16List? writeData;

  Map<String,RegisterField> fields;

  RegisterCluster(this.key, this.name, this.addr,this.size ,this.registerType,this.fields,{this.tag,this.canArgs});


  read(Uint16List data){

    if (data == null) {
      readData = null;
      return;
    }

      for(RegisterField field in fields.values){
        field.read(data.sublist(field.offset,field.offset + field.size));
      }
      readData = data;

  }

  Uint16List write(){
    if (readData == null) throw Exception('Must read data from device before write data');

    var data = readData!.sublist(0);

    for(RegisterField field in fields.values){
      var d = data.sublist(field.offset,field.offset + field.size);
      field.write(d);
      data.setRange(field.offset, field.offset + field.size, d);
    }
    writeData = data;

    return data;
  }


}
