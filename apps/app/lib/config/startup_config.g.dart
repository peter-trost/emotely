// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startup_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StartupConfig _$StartupConfigFromJson(Map<String, dynamic> json) =>
    _StartupConfig(
      minAppVersion: json['min_app_version'] as String,
      storeUrl: json['store_url'] as String,
    );

Map<String, dynamic> _$StartupConfigToJson(_StartupConfig instance) =>
    <String, dynamic>{
      'min_app_version': instance.minAppVersion,
      'store_url': instance.storeUrl,
    };
