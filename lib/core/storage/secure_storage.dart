import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper for secure token storage
class TokenStorage {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserRole = 'user_role';
  static const _keyUserEmail = 'user_email';
  static const _keyUserName = 'user_name';
  static const _keyUserSurname = 'user_surname';
  static const _keyUserAge = 'user_age';
  static const _keyUserPhone = 'user_phone';
  static const _keyUserCarModel = 'user_car_model';
  static const _keyUserCarColor = 'user_car_color';
  static const _keyUserCarYear = 'user_car_year';

  final _storage = const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    String? userRole,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      _storage.write(key: _keyUserId, value: userId),
      if (userRole != null) _storage.write(key: _keyUserRole, value: userRole),
    ]);
  }

  Future<void> saveUserProfile({
    String? email,
    String? name,
    String? surname,
    String? age,
    String? phone,
    String? carModel,
    String? carColor,
    String? carYear,
  }) async {
    await Future.wait([
      if (email != null) _storage.write(key: _keyUserEmail, value: email),
      if (name != null) _storage.write(key: _keyUserName, value: name),
      if (surname != null) _storage.write(key: _keyUserSurname, value: surname),
      if (age != null) _storage.write(key: _keyUserAge, value: age),
      if (phone != null) _storage.write(key: _keyUserPhone, value: phone),
      if (carModel != null) _storage.write(key: _keyUserCarModel, value: carModel),
      if (carColor != null) _storage.write(key: _keyUserCarColor, value: carColor),
      if (carYear != null) _storage.write(key: _keyUserCarYear, value: carYear),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);
  Future<String?> getUserId() => _storage.read(key: _keyUserId);
  Future<String?> getUserRole() => _storage.read(key: _keyUserRole);
  Future<String?> getUserEmail() => _storage.read(key: _keyUserEmail);
  Future<String?> getUserName() => _storage.read(key: _keyUserName);
  Future<String?> getUserSurname() => _storage.read(key: _keyUserSurname);
  Future<String?> getUserAge() => _storage.read(key: _keyUserAge);
  Future<String?> getUserPhone() => _storage.read(key: _keyUserPhone);
  Future<String?> getUserCarModel() => _storage.read(key: _keyUserCarModel);
  Future<String?> getUserCarColor() => _storage.read(key: _keyUserCarColor);
  Future<String?> getUserCarYear() => _storage.read(key: _keyUserCarYear);

  Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyUserRole),
      _storage.delete(key: _keyUserEmail),
      _storage.delete(key: _keyUserName),
      _storage.delete(key: _keyUserSurname),
      _storage.delete(key: _keyUserAge),
      _storage.delete(key: _keyUserPhone),
      _storage.delete(key: _keyUserCarModel),
      _storage.delete(key: _keyUserCarColor),
      _storage.delete(key: _keyUserCarYear),
    ]);
  }

  /// Clear only the authentication tokens (access + refresh).
  /// Does NOT remove user identity data (userId, role, profile).
  /// Use this on 401 so the userId is preserved for re-login flows.
  Future<void> clearAuthTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
    ]);
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
