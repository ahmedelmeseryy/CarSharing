import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

/// Generic API response wrapper from all endpoints
/// Maps from Swagger: ApiResponse<T>
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final T? data;
  final ApiError? error;
  final String? message;
  final String? timestamp;

  ApiResponse({
    this.data,
    this.error,
    this.message,
    this.timestamp,
  });

  /// Check if response is successful
  bool get isSuccess => error == null && data != null;

  /// Get error message
  String get errorMessage => error?.message ?? message ?? 'Unknown error';

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}

/// API Error object
@JsonSerializable()
class ApiError {
  final String? code;
  final String message;
  final List<String>? details;

  ApiError({
    this.code,
    required this.message,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);
}
