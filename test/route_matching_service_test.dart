import 'package:carsharing/services/route_matching_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculateDistance between Paris and London approx 343 km', () {
    // Paris (approx): 48.8566 N, 2.3522 E
    // London (approx): 51.5074 N, -0.1278 W
    final dist = RouteMatchingService.calculateDistance(48.8566, 2.3522, 51.5074, -0.1278);
    // Expected ~343 km (approx)
    expect(dist, greaterThan(300));
    expect(dist, lessThan(400));
  });
}
