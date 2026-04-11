import 'dart:convert';
import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/core/storage/secure_storage.dart';

class AuthApiService {
  final DioClient _client;
  final TokenStorage _tokenStorage;

  AuthApiService({
    DioClient? client,
    TokenStorage? tokenStorage,
  })  : _client = client ?? DioClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  // ─── Login ────────────────────────────────────────────────────────────────

  /// POST /auth-service/api/auth/login
  /// Response: { data: { token, email, role } }
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth-service/api/auth/login',
      data: {'email': email, 'password': password},
    );

    final data = response['data'] ?? response;
    final token = data['token'] as String?;
    final role = (data['role'] as String?)?.toLowerCase();

    // Try to get userId from response body first, then fall back to JWT decoding
    final userId = data['userId']?.toString() ??
        data['id']?.toString() ??
        data['sub']?.toString() ??
        (token != null ? _extractUserIdFromToken(token) : null);

    if (token != null && userId != null && userId.isNotEmpty) {
      await _tokenStorage.saveTokens(
        accessToken: token,
        refreshToken: '',
        userId: userId,
        userRole: role,
      );
      await _tokenStorage.saveUserProfile(
        email: (data['email'] as String?) ?? email,
      );
    } else if (token != null) {
      // Token received but no userId found — store what we have
      // driverId will be unusable until a valid userId is available
      await _tokenStorage.saveTokens(
        accessToken: token,
        refreshToken: '',
        userId: '',
        userRole: role,
      );
      await _tokenStorage.saveUserProfile(
        email: (data['email'] as String?) ?? email,
      );
    }

    return data;
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  /// POST /auth-service/api/auth/signup
  /// Request: { firstName, lastName, email, password, userType, phoneNumber, age, licenseNumber }
  /// Response: { data: { token, email, role } }
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String age,
    required String phone,
    required String role, // app passes lowercase: 'driver', 'user', 'admin'
    String? carModel,
    String? carColor,
    String? carYear,
    String? licenseNumber,
  }) async {
    // Convert role to API's expected userType format (UPPERCASE)
    final userType = _toUserType(role);

    final registerData = <String, dynamic>{
      'firstName': name,
      'lastName': surname,
      'email': email,
      'password': password,
      'userType': userType,
      if (phone.isNotEmpty) 'phoneNumber': phone,
      if (age.isNotEmpty) 'age': int.tryParse(age) ?? 0,
      if (licenseNumber != null && licenseNumber.isNotEmpty)
        'licenseNumber': licenseNumber,
    };

    final response = await _client.post(
      '/auth-service/api/auth/signup',
      data: registerData,
    );

    final data = response['data'] ?? response;
    final token = data['token'] as String?;
    final responseRole = (data['role'] as String?)?.toLowerCase();

    // Try to get userId from response body first, then fall back to JWT decoding
    final userId = data['userId']?.toString() ??
        data['id']?.toString() ??
        data['sub']?.toString() ??
        (token != null ? _extractUserIdFromToken(token) : null);

    if (token != null) {
      await _tokenStorage.saveTokens(
        accessToken: token,
        refreshToken: '',
        userId: userId ?? '',
        userRole: responseRole ?? role,
      );
      await _tokenStorage.saveUserProfile(
        email: email,
        name: name,
        surname: surname,
        age: age,
        phone: phone,
        carModel: carModel,
        carColor: carColor,
        carYear: carYear,
      );
    }

    return data;
  }

  // ─── Change Password ──────────────────────────────────────────────────────

  /// PUT /auth-service/api/auth/change-password
  /// Requires valid JWT. Returns 401 if currentPassword is wrong.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.put(
      '/auth-service/api/auth/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────

  /// POST /auth-service/api/auth/reset-password
  /// Sends a reset token to the user's email.
  Future<void> resetPassword(String email) async {
    await _client.post(
      '/auth-service/api/auth/reset-password',
      data: {'email': email},
    );
  }

  /// POST /auth-service/api/auth/reset-password/confirm
  /// Resets the password using the token received by email.
  Future<void> confirmResetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _client.post(
      '/auth-service/api/auth/reset-password/confirm',
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  /// No logout endpoint exists on the server. Just clears local tokens.
  Future<void> logout() async {
    await _tokenStorage.clearAll();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Converts app role strings (lowercase) to API userType values (UPPERCASE).
  /// 'user' → 'PASSENGER', 'driver' → 'DRIVER', 'admin' → 'ADMIN'
  String _toUserType(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return 'DRIVER';
      case 'admin':
        return 'ADMIN';
      default: // 'user' or 'passenger'
        return 'PASSENGER';
    }
  }

  /// Decodes a JWT token and extracts the subject (user ID) from the payload.
  String? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      // JWT payload is base64url encoded — add padding if needed
      var payload = parts[1];
      payload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Url.decode(payload));
      final claims = json.decode(decoded) as Map<String, dynamic>;
      return claims['sub']?.toString() ??
          claims['userId']?.toString() ??
          claims['id']?.toString();
    } catch (_) {
      return null;
    }
  }
}
