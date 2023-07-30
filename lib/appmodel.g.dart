// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appmodel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppState _$AppStateFromJson(Map<String, dynamic> json) => AppState()
  ..currentAccount = json['currentAccount'] as String? ?? ''
  ..testnet = json['testnet'] as bool? ?? false;

Map<String, dynamic> _$AppStateToJson(AppState instance) => <String, dynamic>{
      'currentAccount': instance.currentAccount,
      'testnet': instance.testnet,
    };
