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

  /// Login with email/password to backend
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response['data'] ?? response;
    final accessToken = data['access_token'] ?? data['accessToken'];
    final refreshToken = data['refresh_token'] ?? data['refreshToken'];
    final user = data['user'];
    final userId = user['id'] ?? user['uid'] ?? user['userId'];
    final role = user?['role'] as String?;

    if (accessToken != null && refreshToken != null && userId != null) {
      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId.toString(),
        userRole: role,
      );
    }

    return data;
  }

  /// Register new user to backend
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String age,
    required String phone,
    required String role,
    String? carModel,
    String? carColor,
    String? carYear,
    String? licenseNumber,
  }) async {
    final registerData = {
      'email': email,
      'password': password,
      'name': name,
      'surname': surname,
      'age': age,
      'phone': phone,
      'role': role,
    };

    // Add optional driver fields
    if (role == 'driver') {
      if (carModel != null && carModel.isNotEmpty) {
        registerData['carModel'] = carModel;
      }
      if (carColor != null && carColor.isNotEmpty) {
        registerData['carColor'] = carColor;
      }
      if (carYear != null && carYear.isNotEmpty) {
        registerData['carYear'] = carYear;
      }
      if (licenseNumber != null && licenseNumber.isNotEmpty) {
        registerData['licenseNumber'] = licenseNumber;
      }
    }

    final response = await _client.post(
      '/api/auth/register',
      data: registerData,
    );

    final data = response['data'] ?? response;
    final accessToken = data['access_token'] ?? data['accessToken'];
    final refreshToken = data['refresh_token'] ?? data['refreshToken'];
    final user = data['user'];
    final userId = user['id'] ?? user['uid'] ?? user['userId'];
    final responseRole = user?['role'] as String?;

    if (accessToken != null && refreshToken != null && userId != null) {
      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId.toString(),
        userRole: responseRole ?? role,
      );
    }

    return data;
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    try {
      await _client.post('/api/auth/logout');
    } catch (e) {
      // Ignore logout errors, just clear local tokens
    } finally {
      await _tokenStorage.clearAll();
    }
  }

  /// Refresh access token
  Future<String?> refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _client.post(
        '/api/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response['data'] ?? response;
      final newAccessToken = data['access_token'] ?? data['accessToken'];

      if (newAccessToken != null) {
        final userId = await _tokenStorage.getUserId();
        await _tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: refreshToken,
          userId: userId ?? '',
        );
        return newAccessToken;
      }
    } catch (e) {
      await _tokenStorage.clearAll();
    }

    return null;
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.post(
      '/api/auth/password/reset',
      data: {'email': email},
    );
  }
}

