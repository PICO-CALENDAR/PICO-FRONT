// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthModel _$AuthModelFromJson(Map<String, dynamic> json) => AuthModel(
      id: (json['id'] as num?)?.toInt(),
      isRegistered: json['isRegistered'] as bool,
      isLoggedIn: json['isLoggedIn'] as bool,
    );

Map<String, dynamic> _$AuthModelToJson(AuthModel instance) => <String, dynamic>{
      'id': instance.id,
      'isRegistered': instance.isRegistered,
      'isLoggedIn': instance.isLoggedIn,
    };
