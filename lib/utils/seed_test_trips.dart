import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utility class to seed the database with test trips
/// Run this once to populate the database with sample trips for testing
class SeedTestTrips {
  static Future<void> addTestTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User must be logged in to add test trips');
      return;
    }

    // Get user data for driver name
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data();
    final driverName = userData != null
        ? '${userData['name'] ?? ''} ${userData['surname'] ?? ''}'.trim()
        : 'Test Driver';

    final testTrips = [
      // Trip 1: Berlin to Munich (with stop in Nuremberg)
      {
        'from': 'Berlin',
        'to': 'Munich',
        'fromAddress': 'Hauptbahnhof, Berlin, Germany',
        'toAddress': 'Marienplatz, Munich, Germany',
        'fromLatitude': 52.5256,
        'fromLongitude': 13.3695,
        'toLatitude': 48.1374,
        'toLongitude': 11.5755,
        'stops': [
          {
            'address': 'Nuremberg Central Station, Nuremberg, Germany',
            'order': 1,
            'latitude': 49.4452,
            'longitude': 11.0817,
          }
        ],
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3)).copyWith(hour: 14, minute: 30)),
        'seats': 4,
        'price': 35.50,
        'driverId': user.uid,
        'driverName': driverName.isNotEmpty ? driverName : 'Test Driver',
        'estimatedDurationMinutes': 240,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Trip 2: Hamburg to Cologne (with stops)
      {
        'from': 'Hamburg',
        'to': 'Cologne',
        'fromAddress': 'Hamburg Hauptbahnhof, Hamburg, Germany',
        'toAddress': 'Cologne Central Station, Cologne, Germany',
        'fromLatitude': 53.5511,
        'fromLongitude': 10.0067,
        'toLatitude': 50.9375,
        'toLongitude': 6.9603,
        'stops': [
          {
            'address': 'Bremen Central Station, Bremen, Germany',
            'order': 1,
            'latitude': 53.0793,
            'longitude': 8.8017,
          },
          {
            'address': 'Dortmund Central Station, Dortmund, Germany',
            'order': 2,
            'latitude': 51.5136,
            'longitude': 7.4653,
          }
        ],
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5)).copyWith(hour: 9, minute: 0)),
        'seats': 3,
        'price': 28.00,
        'driverId': user.uid,
        'driverName': driverName.isNotEmpty ? driverName : 'Test Driver',
        'estimatedDurationMinutes': 300,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Trip 3: Frankfurt to Stuttgart (direct, no stops)
      {
        'from': 'Frankfurt',
        'to': 'Stuttgart',
        'fromAddress': 'Frankfurt Central Station, Frankfurt, Germany',
        'toAddress': 'Stuttgart Hauptbahnhof, Stuttgart, Germany',
        'fromLatitude': 50.1109,
        'fromLongitude': 8.6821,
        'toLatitude': 48.7833,
        'toLongitude': 9.1833,
        'stops': [],
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7)).copyWith(hour: 16, minute: 45)),
        'seats': 2,
        'price': 25.00,
        'driverId': user.uid,
        'driverName': driverName.isNotEmpty ? driverName : 'Test Driver',
        'estimatedDurationMinutes': 120,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Trip 4: Berlin to Dresden (with multiple stops)
      {
        'from': 'Berlin',
        'to': 'Dresden',
        'fromAddress': 'Alexanderplatz, Berlin, Germany',
        'toAddress': 'Dresden Hauptbahnhof, Dresden, Germany',
        'fromLatitude': 52.5219,
        'fromLongitude': 13.4132,
        'toLatitude': 51.0493,
        'toLongitude': 13.7381,
        'stops': [
          {
            'address': 'Cottbus Central Station, Cottbus, Germany',
            'order': 1,
            'latitude': 51.7563,
            'longitude': 14.3329,
          }
        ],
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2)).copyWith(hour: 11, minute: 15)),
        'seats': 5,
        'price': 22.50,
        'driverId': user.uid,
        'driverName': driverName.isNotEmpty ? driverName : 'Test Driver',
        'estimatedDurationMinutes': 180,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Trip 5: Munich to Salzburg (cross-border, with stop)
      {
        'from': 'Munich',
        'to': 'Salzburg',
        'fromAddress': 'Munich Central Station, Munich, Germany',
        'toAddress': 'Salzburg Hauptbahnhof, Salzburg, Austria',
        'fromLatitude': 48.1408,
        'fromLongitude': 11.5595,
        'toLatitude': 47.8095,
        'toLongitude': 13.0550,
        'stops': [
          {
            'address': 'Rosenheim Station, Rosenheim, Germany',
            'order': 1,
            'latitude': 47.8564,
            'longitude': 12.1306,
          }
        ],
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 4)).copyWith(hour: 13, minute: 0)),
        'seats': 3,
        'price': 30.00,
        'driverId': user.uid,
        'driverName': driverName.isNotEmpty ? driverName : 'Test Driver',
        'estimatedDurationMinutes': 150,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Trip 6: Cologne to Düsseldorf (short trip)
      {
        'from': 'Cologne',
        'to': 'Düsseldorf',
        'fromAddress': 'Cologne Central Station, Cologne, Germany',
        'toAddress': 'Düsseldorf Hauptbahnhof, Düsseldorf, Germany',
        'fromLatitude': 50.9375,
        'fromLongitude': 6.9603,
        'toLatitude': 51.2203,
        'toLongitude': 6.7949,
        'stops': [],
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1)).copyWith(hour: 10, minute: 30)),
        'seats': 4,
        'price': 15.00,
        'driverId': user.uid,
        'driverName': driverName.isNotEmpty ? driverName : 'Test Driver',
        'estimatedDurationMinutes': 60,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Trip 7: Hamburg to Berlin (with stop in Lübeck)
      {
        'from': 'Hamburg',
        'to': 'Berlin',
        'fromAddress': 'Hamburg Airport, Hamburg, Germany',
        'toAddress': 'Berlin Tegel Airport, Berlin, Germany',
        'fromLatitude': 53.6304,
        'fromLongitude': 9.9882,
        'toLatitude': 52.5597,
        'toLongitude': 13.2877,
        'stops': [
          {
            'address': 'Lübeck Central Station, Lübeck, Germany',
            'order': 1,
            'latitude': 53.8655,
            'longitude': 10.6866,
          }
        ],
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 6)).copyWith(hour: 8, minute: 0)),
        'seats': 2,
        'price': 40.00,
        'driverId': user.uid,
        'driverName': driverName.isNotEmpty ? driverName : 'Test Driver',
        'estimatedDurationMinutes': 210,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Trip 8: Stuttgart to Frankfurt (with multiple stops)
      {
        'from': 'Stuttgart',
        'to': 'Frankfurt',
        'fromAddress': 'Stuttgart Airport, Stuttgart, Germany',
        'toAddress': 'Frankfurt Airport, Frankfurt, Germany',
        'fromLatitude': 48.6899,
        'fromLongitude': 9.2219,
        'toLatitude': 50.0379,
        'toLongitude': 8.5622,
        'stops': [
          {
            'address': 'Heidelberg Central Station, Heidelberg, Germany',
            'order': 1,
            'latitude': 49.4037,
            'longitude': 8.6757,
          },
          {
            'address': 'Mannheim Central Station, Mannheim, Germany',
            'order': 2,
            'latitude': 49.4774,
            'longitude': 8.4699,
          }
        ],
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 8)).copyWith(hour: 15, minute: 30)),
        'seats': 4,
        'price': 32.00,
        'driverId': user.uid,
        'driverName': driverName.isNotEmpty ? driverName : 'Test Driver',
        'estimatedDurationMinutes': 180,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Trip 9: Today's trip for immediate testing
      {
        'from': 'Berlin',
        'to': 'Potsdam',
        'fromAddress': 'Potsdamer Platz, Berlin, Germany',
        'toAddress': 'Potsdam Central Station, Potsdam, Germany',
        'fromLatitude': 52.5096,
        'fromLongitude': 13.3766,
        'toLatitude': 52.3906,
        'toLongitude': 13.0645,
        'stops': [],
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 2)).copyWith(minute: 0)),
        'seats': 3,
        'price': 12.00,
        'driverId': user.uid,
        'driverName': driverName.isNotEmpty ? driverName : 'Test Driver',
        'estimatedDurationMinutes': 45,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Trip 10: Long distance trip - Berlin to Vienna (with multiple stops)
      {
        'from': 'Berlin',
        'to': 'Vienna',
        'fromAddress': 'Berlin Central Station, Berlin, Germany',
        'toAddress': 'Vienna Hauptbahnhof, Vienna, Austria',
        'fromLatitude': 52.5256,
        'fromLongitude': 13.3695,
        'toLatitude': 48.1850,
        'toLongitude': 16.3782,
        'stops': [
          {
            'address': 'Leipzig Central Station, Leipzig, Germany',
            'order': 1,
            'latitude': 51.3453,
            'longitude': 12.3824,
          },
          {
            'address': 'Dresden Central Station, Dresden, Germany',
            'order': 2,
            'latitude': 51.0493,
            'longitude': 13.7381,
          },
          {
            'address': 'Prague Central Station, Prague, Czech Republic',
            'order': 3,
            'latitude': 50.0833,
            'longitude': 14.4167,
          }
        ],
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 10)).copyWith(hour: 7, minute: 0)),
        'seats': 4,
        'price': 55.00,
        'driverId': user.uid,
        'driverName': driverName.isNotEmpty ? driverName : 'Test Driver',
        'estimatedDurationMinutes': 480,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    try {
      final batch = FirebaseFirestore.instance.batch();
      int successCount = 0;

      for (var trip in testTrips) {
        final tripRef = FirebaseFirestore.instance.collection('trips').doc();
        batch.set(tripRef, trip);
        successCount++;
      }

      await batch.commit();
      print('✅ Successfully added $successCount test trips to the database');
      return;
    } catch (e) {
      print('❌ Error adding test trips: $e');
      rethrow;
    }
  }

  /// Add a single test trip (for testing specific scenarios)
  static Future<String> addSingleTestTrip({
    required String fromAddress,
    required String toAddress,
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    List<Map<String, dynamic>>? stops,
    DateTime? date,
    int seats = 4,
    double price = 30.0,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data();
    final driverName = userData != null
        ? '${userData['name'] ?? ''} ${userData['surname'] ?? ''}'.trim()
        : 'Test Driver';

    final tripData = {
      'from': fromAddress.split(',')[0], // Extract city name
      'to': toAddress.split(',')[0],
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'fromLatitude': fromLat,
      'fromLongitude': fromLng,
      'toLatitude': toLat,
      'toLongitude': toLng,
      'stops': stops ?? [],
      'date': Timestamp.fromDate(date ?? DateTime.now().add(const Duration(days: 1))),
      'seats': seats,
      'price': price,
      'driverId': user.uid,
      'driverName': driverName.isNotEmpty ? driverName : 'Test Driver',
      'estimatedDurationMinutes': 120,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('trips')
          .add(tripData);
      print('✅ Added test trip: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding test trip: $e');
      rethrow;
    }
  }

  /// Clear all test trips (use with caution!)
  static Future<void> clearAllTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    try {
      final tripsSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('driverId', isEqualTo: user.uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in tripsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Cleared ${tripsSnapshot.docs.length} trips');
    } catch (e) {
      print('❌ Error clearing trips: $e');
      rethrow;
    }
  }
}
