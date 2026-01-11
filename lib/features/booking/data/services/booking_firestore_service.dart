import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';

/// Firestore-based booking service
/// Used as temporary backend while REST API is being implemented
class BookingFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cancel a booking (passenger leaves a trip)
  Future<void> cancelBooking(CancelBookingRequest request) async {
    try {
      final tripRef = _firestore.collection('trips').doc(request.bookingId);
      final tripDoc = await tripRef.get();

      if (!tripDoc.exists) {
        throw Exception('Booking not found');
      }

      final data = tripDoc.data() as Map<String, dynamic>;
      final joinedRiders = List<String>.from(data['joinedRidersId'] ?? []);
      final availableSeats = (data['availableSeat'] ?? 0) as int;

      // Remove passenger from trip
      joinedRiders.removeWhere((id) => id == request.passengerId);

      await tripRef.update({
        'joinedRidersId': joinedRiders,
        'availableSeat': availableSeats + 1,
      });
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Get upcoming bookings for a passenger
  Future<List<Map<String, dynamic>>> getUpcomingBookingsForPassenger(
    String passengerId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .where('joinedRidersId', arrayContains: passengerId)
          .where('status', isEqualTo: 'active')
          .orderBy('tripStartDateTime', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => {
                'bookingId': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to get bookings: $e');
    }
  }

  /// Stream upcoming bookings for a passenger (real-time)
  Stream<List<Map<String, dynamic>>> watchUpcomingBookingsForPassenger(
    String passengerId,
  ) {
    return _firestore
        .collection('trips')
        .where('joinedRidersId', arrayContains: passengerId)
        .where('status', isEqualTo: 'active')
        .orderBy('tripStartDateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'bookingId': doc.id,
                  ...doc.data(),
                })
            .toList());
  }
}
