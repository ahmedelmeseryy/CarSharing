import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/core/storage/secure_storage.dart';

/// Service for the user-service API
class UserApiService {
  final DioClient _dioClient;

  UserApiService(this._dioClient);

  static const _adminHeaders = {'X-User-Role': 'ADMIN'};

  // ─── Regular endpoints ────────────────────────────────────────────────────

  /// GET /user-service/api/users/{userId}
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
  Future<List<Map<String, dynamic>>> getVehiclesByUserId(String userId) async {
    try {
      final response = await _dioClient.get<dynamic>(
        '/user-service/api/vehicles/$userId',
      );
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// DELETE /user-service/api/admin/vehicles/{id}
  Future<void> deleteVehicle(String vehicleId) async {
    final email = await TokenStorage().getUserEmail() ?? '';
    await _dioClient.delete<dynamic>(
      '/user-service/api/admin/vehicles/$vehicleId',
      headers: {..._adminHeaders, 'X-User-Email': email},
    );
  }

  /// POST /user-service/api/vehicles/register
  Future<Map<String, dynamic>?> registerVehicle({
    required String userId,
    required String vehicleName,
    required String vehicleNumber,
    required String vehicleType,
    required String vehicleColor,
    required String seatingCapacity,
  }) async {
    final response = await _dioClient.post<dynamic>(
      '/user-service/api/vehicles/register',
      data: {
        'userId': userId,
        'vehicleName': vehicleName,
        'vehicleNumber': vehicleNumber,
        'vehicleType': vehicleType,
        'vehicleColor': vehicleColor,
        'seatingCapacity': seatingCapacity,
      },
    );
    if (response is Map<String, dynamic>) {
      return response['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  // ─── Admin endpoints ──────────────────────────────────────────────────────

  /// GET /user-service/api/admin/drivers?status=...&page=0&size=20
  /// status: PENDING | ACTIVE | REJECTED | null (all)
  Future<Map<String, dynamic>> adminListDrivers({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dioClient.get<dynamic>(
      '/user-service/api/admin/drivers',
      queryParameters: {
        'page': page,
        'size': size,
        if (status != null) 'status': status,
      },
      headers: _adminHeaders,
    );
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
    }
    return {'content': [], 'totalElements': 0, 'totalPages': 0};
  }

  /// GET /user-service/api/admin/passengers?page=0&size=20
  Future<Map<String, dynamic>> adminListPassengers({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dioClient.get<dynamic>(
      '/user-service/api/admin/passengers',
      queryParameters: {'page': page, 'size': size},
      headers: _adminHeaders,
    );
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
    }
    return {'content': [], 'totalElements': 0, 'totalPages': 0};
  }

  /// POST /user-service/api/admin/drivers/{id}/approve
  Future<void> adminApproveDriver(String driverId) async {
    final email = await TokenStorage().getUserEmail() ?? '';
    await _dioClient.post<dynamic>(
      '/user-service/api/admin/drivers/$driverId/approve',
      headers: {..._adminHeaders, 'X-User-Email': email},
    );
  }

  /// POST /user-service/api/admin/drivers/{id}/reject
  Future<void> adminRejectDriver(String driverId) async {
    final email = await TokenStorage().getUserEmail() ?? '';
    await _dioClient.post<dynamic>(
      '/user-service/api/admin/drivers/$driverId/reject',
      headers: {..._adminHeaders, 'X-User-Email': email},
    );
  }

  /// DELETE /user-service/api/admin/drivers/{id}
  Future<void> adminDeleteDriver(String driverId) async {
    final email = await TokenStorage().getUserEmail() ?? '';
    await _dioClient.delete<dynamic>(
      '/user-service/api/admin/drivers/$driverId',
      headers: {..._adminHeaders, 'X-User-Email': email},
    );
  }

  /// DELETE /user-service/api/admin/passengers/{id}
  Future<void> adminDeletePassenger(String passengerId) async {
    final email = await TokenStorage().getUserEmail() ?? '';
    await _dioClient.delete<dynamic>(
      '/user-service/api/admin/passengers/$passengerId',
      headers: {..._adminHeaders, 'X-User-Email': email},
    );
  }
}
