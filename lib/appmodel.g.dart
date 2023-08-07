// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appmodel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppState _$AppStateFromJson(Map<String, dynamic> json) => AppState()
  .._accounts = (json['accounts'] as List<dynamic>)
      .map((e) => Account.fromJson(e as Map<String, dynamic>))
      .toList()
  ..currentAccountAddress = json['currentAccountAddress'] as String? ?? ''
  ..testnet = json['testnet'] as bool? ?? false;

Map<String, dynamic> _$AppStateToJson(AppState instance) => <String, dynamic>{
      'accounts': instance._accounts,
      'currentAccountAddress': instance.currentAccountAddress,
      'testnet': instance.testnet,
    };

Account _$AccountFromJson(Map<String, dynamic> json) => Account()
  ..friendlyName = json['friendlyName'] as String
  ..address = json['address'] as String
  ..secret = json['secret'] as String
  ..testnet = json['testnet'] as bool;

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
      'friendlyName': instance.friendlyName,
      'address': instance.address,
      'secret': instance.secret,
      'testnet': instance.testnet,
    };
