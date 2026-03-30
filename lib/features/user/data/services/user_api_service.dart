import 'package:carsharing/core/network/dio_client.dart';

/// Service for the user-service API
/// Endpoints: GET /user-service/api/users/{userId}
///            GET /user-service/api/vehicles/{userId}
class UserApiService {
  final DioClient _dioClient;

  UserApiService(this._dioClient);

  /// GET /user-service/api/users/{userId}
  /// Returns user profile map or null if not found.
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final response = await _dioClient.get<dynamic>(
      '/user-service/api/users/$userId',
    );
    if (response is Map<String, dynamic>) {
      return response['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  /// GET /user-service/api/vehicles/{userId}
  /// Returns list of vehicle maps [{value, text, seatingCapacity}] or [].
  Future<List<Map<String, dynamic>>> getVehiclesByUserId(String userId) async {
    try {
      final response = await _dioClient.get<dynamic>(
        '/user-service/api/vehicles/$userId',
      );
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
