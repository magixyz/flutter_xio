// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_field_meta_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterFieldMetaV2 _$RegisterFieldMetaV2FromJson(Map<String, dynamic> json) =>
    RegisterFieldMetaV2(
      json['key'] as String,
      $enumDecode(_$FieldTypeEnumMap, json['type']),
      json['name'] as String?,
      (json['offset'] as num).toInt(),
      (json['size'] as num).toInt(),
      tag: json['tag'] as String?,
      selection: json['selection'] as List<dynamic>?,
    )
      ..readValue = json['read_value']
      ..writeValue = json['write_value'];

Map<String, dynamic> _$RegisterFieldMetaV2ToJson(
        RegisterFieldMetaV2 instance) =>
    <String, dynamic>{
      'type': _$FieldTypeEnumMap[instance.type]!,
      'name': instance.name,
      'key': instance.key,
      'offset': instance.offset,
      'size': instance.size,
      'tag': instance.tag,
      'selection': instance.selection,
      'read_value': instance.readValue,
      'write_value': instance.writeValue,
    };

const _$FieldTypeEnumMap = {
  FieldType.float: 'float',
  FieldType.short: 'short',
  FieldType.ushort: 'ushort',
  FieldType.int: 'int',
  FieldType.uint: 'uint',
  FieldType.ulong: 'ulong',
  FieldType.byte: 'byte',
  FieldType.bit: 'bit',
  FieldType.bits: 'bits',
  FieldType.string: 'string',
  FieldType.hex: 'hex',
};
