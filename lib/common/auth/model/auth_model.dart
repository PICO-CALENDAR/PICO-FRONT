import 'package:json_annotation/json_annotation.dart';

part 'auth_model.g.dart';

abstract class AuthModelBase {}

class AuthModelError extends AuthModelBase {
  final String message;

  AuthModelError({
    required this.message,
  });
}

class AuthModelLoading extends AuthModelBase {}

@JsonSerializable()
class AuthModel extends AuthModelBase {
  final int id;
  final bool isRegistered;

  AuthModel({
    required this.id,
    required this.isRegistered,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) =>
      _$AuthModelFromJson(json);
}
