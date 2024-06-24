// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_group_meta_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterGroupMetaV2 _$RegisterGroupMetaV2FromJson(Map<String, dynamic> json) =>
    RegisterGroupMetaV2(
      json['key'] as String,
      json['name'] as String?,
      (json['clusters'] as List<dynamic>)
          .map((e) => RegisterClusterMetaV2.fromJson(e as Map<String, dynamic>))
          .toList(),
      tag: json['tag'] as String?,
    );

Map<String, dynamic> _$RegisterGroupMetaV2ToJson(
        RegisterGroupMetaV2 instance) =>
    <String, dynamic>{
      'name': instance.name,
      'key': instance.key,
      'tag': instance.tag,
      'clusters': instance.clusters,
    };
