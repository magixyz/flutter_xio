
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../enum/register_type.dart';
import 'register_field_meta_v2.dart';




part 'register_cluster_meta_v2.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RegisterClusterMetaV2 {

  String? name;
  String key;

  int addr;
  int size;
  RegisterType registerType ;

  String? tag;



  List<RegisterClusterMetaV2>? childs;
  List<RegisterFieldMetaV2>? fields;

  RegisterClusterMetaV2(this.key, this.name, this.addr,this.size ,this.registerType,{this.fields,this.childs,this.tag});

  factory RegisterClusterMetaV2.fromJson(Map<String, dynamic> json) => _$RegisterClusterMetaV2FromJson(json);

  Map<String, dynamic> toJson() => _$RegisterClusterMetaV2ToJson(this);


}
