
import 'dart:typed_data';

import 'register_cluster_meta_v2.dart';
import 'package:json_annotation/json_annotation.dart';

import '../enum/register_type.dart';
import '../register/register_field.dart';



part 'register_group_meta_v2.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RegisterGroupMetaV2 {

  String? name;
  String key;

  String? tag;

  List<RegisterClusterMetaV2> clusters;

  RegisterGroupMetaV2(this.key, this.name,  this.clusters,{this.tag});


  factory RegisterGroupMetaV2.fromJson(Map<String, dynamic> json) => _$RegisterGroupMetaV2FromJson(json);

  Map<String, dynamic> toJson() => _$RegisterGroupMetaV2ToJson(this);

}
