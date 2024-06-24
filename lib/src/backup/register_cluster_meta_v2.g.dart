// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_cluster_meta_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterClusterMetaV2 _$RegisterClusterMetaV2FromJson(
        Map<String, dynamic> json) =>
    RegisterClusterMetaV2(
      json['key'] as String,
      json['name'] as String?,
      (json['addr'] as num).toInt(),
      (json['size'] as num).toInt(),
      $enumDecode(_$RegisterTypeEnumMap, json['register_type']),
      fields: (json['fields'] as List<dynamic>?)
          ?.map((e) => RegisterFieldMetaV2.fromJson(e as Map<String, dynamic>))
          .toList(),
      childs: (json['childs'] as List<dynamic>?)
          ?.map(
              (e) => RegisterClusterMetaV2.fromJson(e as Map<String, dynamic>))
          .toList(),
      tag: json['tag'] as String?,
    );

Map<String, dynamic> _$RegisterClusterMetaV2ToJson(
        RegisterClusterMetaV2 instance) =>
    <String, dynamic>{
      'name': instance.name,
      'key': instance.key,
      'addr': instance.addr,
      'size': instance.size,
      'register_type': _$RegisterTypeEnumMap[instance.registerType]!,
      'tag': instance.tag,
      'childs': instance.childs,
      'fields': instance.fields,
    };

const _$RegisterTypeEnumMap = {
  RegisterType.input: 'input',
  RegisterType.holding: 'holding',
};
