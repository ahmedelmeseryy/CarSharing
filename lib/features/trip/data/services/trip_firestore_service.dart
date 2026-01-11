import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/trip.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';

/// Firestore-based trip service
/// Used as temporary backend while REST API is being implemented
class TripFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new trip offer in Firestore
  Future<String> offerTrip(OfferRideRequest request) async {
    try {
      final docRef = await _firestore.collection('trips').add({
        'driverId': request.driverId,
        'vehicleNumber': request.vehicleNumber,
        'sourceAddress': {
          'lat': request.sourceAddress.latitude,
          'lon': request.sourceAddress.longitude,
          'address': request.sourceAddress.placeAddress,
        },
        'destinationAddress': {
          'lat': request.destinationAddress.latitude,
          'lon': request.destinationAddress.longitude,
          'address': request.destinationAddress.placeAddress,
        },
        'tripStartDateTime': request.tripStartDateTime,
        'offeredSeat': request.offeredSeat,
        'availableSeat': request.offeredSeat,
        'joinedRidersId': [],
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create trip: $e');
    }
  }

  /// Cancel a trip
  Future<void> cancelTrip(CancelTripRequest request) async {
    try {
      await _firestore.collection('trips').doc(request.tripId).delete();
    } catch (e) {
      throw Exception('Failed to cancel trip: $e');
    }
  }

  /// Get upcoming trips for a driver
  Future<List<Trip>> getUpcomingTripsForDriver(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'active')
          .orderBy('tripStartDateTime', descending: false)
          .get();

      return snapshot.docs.map((doc) => _tripFromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get driver trips: $e');
    }
  }

  /// Search trips by source location
  Future<List<Trip>> searchNearSource({
    required double sourceLat,
    required double sourceLon,
    double? radiusKm,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'active')
          .get();

      final trips = snapshot.docs
          .map((doc) => _tripFromDocument(doc))
          .where((trip) {
            final distance = _calculateDistance(
              sourceLat,
              sourceLon,
              trip.sourceAddress!.latitude,
              trip.sourceAddress!.longitude,
            );
            return distance <= (radiusKm ?? 50);
          })
          .toList();

      return trips;
    } catch (e) {
      throw Exception('Failed to search trips near source: $e');
    }
  }

  /// Search trips by destination location
  Future<List<Trip>> searchNearDestination({
    required double destLat,
    required double destLon,
    double? radiusKm,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'active')
          .get();

      final trips = snapshot.docs
          .map((doc) => _tripFromDocument(doc))
          .where((trip) {
            final distance = _calculateDistance(
              destLat,
              destLon,
              trip.destinationAddress!.latitude,
              trip.destinationAddress!.longitude,
            );
            return distance <= (radiusKm ?? 50);
          })
          .toList();

      return trips;
    } catch (e) {
      throw Exception('Failed to search trips near destination: $e');
    }
  }

  /// Search trips matching both source and destination
  Future<List<Trip>> searchMatchingRoute({
    required double sourceLat,
    required double sourceLon,
    required double sourceRadiusKm,
    required double destLat,
    required double destLon,
    required double destRadiusKm,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'active')
          .get();

      final trips = snapshot.docs
          .map((doc) => _tripFromDocument(doc))
          .where((trip) {
            final sourceDistance = _calculateDistance(
              sourceLat,
              sourceLon,
              trip.sourceAddress!.latitude,
              trip.sourceAddress!.longitude,
            );
            final destDistance = _calculateDistance(
              destLat,
              destLon,
              trip.destinationAddress!.latitude,
              trip.destinationAddress!.longitude,
            );
            return sourceDistance <= sourceRadiusKm &&
                destDistance <= destRadiusKm;
          })
          .toList();

      return trips;
    } catch (e) {
      throw Exception('Failed to search matching routes: $e');
    }
  }

  /// Join a trip as a passenger
  Future<void> joinTrip(JoinTripRequest request) async {
    try {
      final tripRef = _firestore.collection('trips').doc(request.tripId);
      final tripDoc = await tripRef.get();

      if (!tripDoc.exists) {
        throw Exception('Trip not found');
      }

      final data = tripDoc.data() as Map<String, dynamic>;
      final joinedRiders = List<String>.from(data['joinedRidersId'] ?? []);
      final availableSeats = (data['availableSeat'] ?? 0) as int;

      if (availableSeats <= 0) {
        throw Exception('No available seats');
      }

      if (!joinedRiders.contains(request.passengerId)) {
        joinedRiders.add(request.passengerId);
      }

      await tripRef.update({
        'joinedRidersId': joinedRiders,
        'availableSeat': availableSeats - 1,
      });
    } catch (e) {
      throw Exception('Failed to join trip: $e');
    }
  }

  /// Stream upcoming bookings for a passenger
  Stream<List<Trip>> getUpcomingBookingsForPassenger(String passengerId) {
    return _firestore
        .collection('trips')
        .where('joinedRidersId', arrayContains: passengerId)
        .where('status', isEqualTo: 'active')
        .orderBy('tripStartDateTime', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _tripFromDocument(doc)).toList());
  }

  /// Convert Firestore document to Trip model
  Trip _tripFromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final sourceData = data['sourceAddress'] as Map<String, dynamic>?;
    final destData = data['destinationAddress'] as Map<String, dynamic>?;

    return Trip(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      vehicleNumber: data['vehicleNumber'] ?? '',
      sourceAddress: sourceData != null
          ? Points(
              latitude: (sourceData['lat'] as num?)?.toDouble() ?? 0,
              longitude: (sourceData['lon'] as num?)?.toDouble() ?? 0,
              placeAddress: sourceData['address'] ?? '',
            )
          : null,
      destinationAddress: destData != null
          ? Points(
              latitude: (destData['lat'] as num?)?.toDouble() ?? 0,
              longitude: (destData['lon'] as num?)?.toDouble() ?? 0,
              placeAddress: destData['address'] ?? '',
            )
          : null,
      tripStartDateTime: (data['tripStartDateTime'] as Timestamp?)?.toDate(),
      offeredSeat: (data['offeredSeat'] as num?)?.toInt() ?? 0,
      joinedRidersId: List<String>.from(data['joinedRidersId'] ?? []),
    );
  }

  /// Calculate distance between two points (in km)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) *
            cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
