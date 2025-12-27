import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class RouteMatch {
  final String tripId;
  final Map<String, dynamic> tripData;
  final double matchScore; // 0-100, higher is better match
  final String? pickupStop; // Which stop user can get on
  final String? dropoffStop; // Which stop user can get off
  final double? distanceToPickup; // km
  final double? distanceToDropoff; // km

  RouteMatch({
    required this.tripId,
    required this.tripData,
    required this.matchScore,
    this.pickupStop,
    this.dropoffStop,
    this.distanceToPickup,
    this.distanceToDropoff,
  });
}

class RouteMatchingService {
  // Default search radius in kilometers
  static const double defaultSearchRadius = 10.0; // 10 km
  static const double maxSearchRadius = 50.0; // 50 km max
  
  // Time window in hours (how flexible the time matching is)
  static const int defaultTimeWindowHours = 2; // ±2 hours

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Check if a point is within radius of another point
  static bool isWithinRadius(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double radiusKm,
  ) {
    return calculateDistance(lat1, lon1, lat2, lon2) <= radiusKm;
  }

  /// Find matching trips based on user's origin and destination
  static Future<List<RouteMatch>> findMatchingTrips({
    required double userFromLat,
    required double userFromLng,
    required double userToLat,
    required double userToLng,
    DateTime? preferredDate,
    double searchRadius = defaultSearchRadius,
    int timeWindowHours = defaultTimeWindowHours,
  }) async {
    final matches = <RouteMatch>[];

    try {
      // Attempt to limit the query by a bounding box around the user's origin
      final bbox = _boundingBox(userFromLat, userFromLng, searchRadius);

      Query query = FirebaseFirestore.instance.collection('trips');

      // If preferred date is provided, constrain to that day to reduce results
      if (preferredDate != null) {
        final start = DateTime(preferredDate.year, preferredDate.month, preferredDate.day);
        final end = start.add(const Duration(days: 1));
        query = query
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThan: Timestamp.fromDate(end));
      }

      // Apply bounding box on fromLatitude to reduce scanned docs
      query = query
          .where('fromLatitude', isGreaterThanOrEqualTo: bbox['minLat'])
          .where('fromLatitude', isLessThanOrEqualTo: bbox['maxLat'])
          .limit(500);

      final tripsSnapshot = await query.get();

      for (var tripDoc in tripsSnapshot.docs) {
        final tripData = tripDoc.data() as Map<String, dynamic>;
        final tripId = tripDoc.id;

        // Skip if no coordinates available
        if (!_hasCoordinates(tripData)) {
          continue;
        }

        // Check date match (if provided)
        if (preferredDate != null) {
          if (!_matchesDate(tripData, preferredDate, timeWindowHours)) {
            continue;
          }
        }

        // Find best pickup and dropoff points
        final match = _findBestMatch(
          tripData: tripData,
          tripId: tripId,
          userFromLat: userFromLat,
          userFromLng: userFromLng,
          userToLat: userToLat,
          userToLng: userToLng,
          searchRadius: searchRadius,
        );

        if (match != null) {
          matches.add(match);
        }
      }

      // Sort by match score (best matches first)
      matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      return matches;
    } catch (e) {
      print('Error finding matching trips: $e');
      return [];
    }
  }

  /// Find the best match for a trip
  static RouteMatch? _findBestMatch({
    required Map<String, dynamic> tripData,
    required String tripId,
    required double userFromLat,
    required double userFromLng,
    required double userToLat,
    required double userToLng,
    required double searchRadius,
  }) {
    // Get trip coordinates
    final tripFromLat = tripData['fromLatitude']?.toDouble();
    final tripFromLng = tripData['fromLongitude']?.toDouble();
    final tripToLat = tripData['toLatitude']?.toDouble();
    final tripToLng = tripData['toLongitude']?.toDouble();

    if (tripFromLat == null || tripFromLng == null ||
        tripToLat == null || tripToLng == null) {
      return null;
    }

    // Get stops
    final stops = tripData['stops'] as List? ?? [];
    final stopCoordinates = <Map<String, dynamic>>[];

    // Add origin as first "stop"
    stopCoordinates.add({
      'latitude': tripFromLat,
      'longitude': tripFromLng,
      'address': tripData['fromAddress'] ?? tripData['from'] ?? 'Origin',
      'isOrigin': true,
    });

    // Add actual stops
    for (var stop in stops) {
      if (stop['latitude'] != null && stop['longitude'] != null) {
        stopCoordinates.add({
          'latitude': stop['latitude']?.toDouble(),
          'longitude': stop['longitude']?.toDouble(),
          'address': stop['address'] ?? '',
          'isOrigin': false,
        });
      }
    }

    // Add destination as last "stop"
    stopCoordinates.add({
      'latitude': tripToLat,
      'longitude': tripToLng,
      'address': tripData['toAddress'] ?? tripData['to'] ?? 'Destination',
      'isDestination': true,
    });

    // Find best pickup point (closest to user's origin)
    double? minPickupDistance;
    int? pickupIndex;
    String? pickupStop;

    for (var i = 0; i < stopCoordinates.length; i++) {
      final stop = stopCoordinates[i];
      final distance = calculateDistance(
        userFromLat,
        userFromLng,
        stop['latitude'] as double,
        stop['longitude'] as double,
      );

      if (distance <= searchRadius) {
        if (minPickupDistance == null || distance < minPickupDistance) {
          minPickupDistance = distance;
          pickupIndex = i;
          pickupStop = stop['address'] as String;
        }
      }
    }

    // Find best dropoff point (closest to user's destination, must be after pickup)
    double? minDropoffDistance;
    int? dropoffIndex;
    String? dropoffStop;

    if (pickupIndex != null) {
      // Only check stops after the pickup point
      for (var i = pickupIndex + 1; i < stopCoordinates.length; i++) {
        final stop = stopCoordinates[i];
        final distance = calculateDistance(
          userToLat,
          userToLng,
          stop['latitude'] as double,
          stop['longitude'] as double,
        );

        if (distance <= searchRadius) {
          if (minDropoffDistance == null || distance < minDropoffDistance) {
            minDropoffDistance = distance;
            dropoffIndex = i;
            dropoffStop = stop['address'] as String;
          }
        }
      }
    }

    // If we found both pickup and dropoff, create a match
    if (pickupIndex != null && dropoffIndex != null) {
      // Calculate match score (0-100)
      // Higher score = better match (closer distances = higher score)
      final pickupScore = 100 - (minPickupDistance! / searchRadius * 50).clamp(0, 50);
      final dropoffScore = 100 - (minDropoffDistance! / searchRadius * 50).clamp(0, 50);
      final matchScore = (pickupScore + dropoffScore) / 2;

      return RouteMatch(
        tripId: tripId,
        tripData: tripData,
        matchScore: matchScore,
        pickupStop: pickupStop,
        dropoffStop: dropoffStop,
        distanceToPickup: minPickupDistance,
        distanceToDropoff: minDropoffDistance,
      );
    }

    return null;
  }

  /// Check if trip has coordinates
  static bool _hasCoordinates(Map<String, dynamic> tripData) {
    return tripData['fromLatitude'] != null &&
        tripData['fromLongitude'] != null &&
        tripData['toLatitude'] != null &&
        tripData['toLongitude'] != null;
  }

  /// Check if trip date matches user's preferred date (within time window)
  static bool _matchesDate(
    Map<String, dynamic> tripData,
    DateTime preferredDate,
    int timeWindowHours,
  ) {
    if (tripData['date'] == null) return false;

    DateTime tripDate;
    if (tripData['date'] is Timestamp) {
      tripDate = (tripData['date'] as Timestamp).toDate();
    } else {
      return false;
    }

    // Check if dates are on the same day
    if (tripDate.year != preferredDate.year ||
        tripDate.month != preferredDate.month ||
        tripDate.day != preferredDate.day) {
      return false;
    }

    // Check if time is within window
    final tripMinutes = tripDate.hour * 60 + tripDate.minute;
    final preferredMinutes = preferredDate.hour * 60 + preferredDate.minute;
    final timeDifference = (tripMinutes - preferredMinutes).abs();

    return timeDifference <= (timeWindowHours * 60);
  }

  /// Compute a simple latitude/longitude bounding box around a point.
  /// Returns a map with keys: minLat, maxLat, minLng, maxLng
  static Map<String, double> _boundingBox(double lat, double lng, double radiusKm) {
    // Approximate degrees per km
    const double kmPerDegLat = 110.574; // ~km per degree latitude
    final double deltaLat = radiusKm / kmPerDegLat;

    // Longitude degrees vary by latitude
    final double kmPerDegLng = 111.320 * (cos(_toRadians(lat)).abs());
    final double deltaLng = kmPerDegLng > 0 ? radiusKm / kmPerDegLng : radiusKm / 111.320;

    return {
      'minLat': lat - deltaLat,
      'maxLat': lat + deltaLat,
      'minLng': lng - deltaLng,
      'maxLng': lng + deltaLng,
    };
  }

  /// Stream-based matching for real-time updates
  static Stream<List<RouteMatch>> findMatchingTripsStream({
    required double userFromLat,
    required double userFromLng,
    required double userToLat,
    required double userToLng,
    DateTime? preferredDate,
    double searchRadius = defaultSearchRadius,
    int timeWindowHours = defaultTimeWindowHours,
  }) {
    return FirebaseFirestore.instance
        .collection('trips')
        .snapshots()
        .asyncMap((snapshot) async {
      final matches = <RouteMatch>[];

      for (var tripDoc in snapshot.docs) {
        final tripData = tripDoc.data();
        final tripId = tripDoc.id;

        if (!_hasCoordinates(tripData)) continue;

        if (preferredDate != null) {
          if (!_matchesDate(tripData, preferredDate, timeWindowHours)) {
            continue;
          }
        }

        final match = _findBestMatch(
          tripData: tripData,
          tripId: tripId,
          userFromLat: userFromLat,
          userFromLng: userFromLng,
          userToLat: userToLat,
          userToLng: userToLng,
          searchRadius: searchRadius,
        );

        if (match != null) {
          matches.add(match);
        }
      }

      matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      return matches;
    });
  }
}
