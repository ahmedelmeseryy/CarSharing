import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

void main() {
  test('calculateDistance between Paris and London approx 343 km', () {
    // Paris (approx): 48.8566 N, 2.3522 E
    // London (approx): 51.5074 N, -0.1278 W
    final dist = _calculateDistance(48.8566, 2.3522, 51.5074, -0.1278);
    // Expected ~343 km (approx)
    expect(dist, greaterThan(300));
    expect(dist, lessThan(400));
  });
}
