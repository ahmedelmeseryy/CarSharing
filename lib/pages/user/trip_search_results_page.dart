import 'package:carsharing/pages/user/trip_details_page.dart';
import 'package:carsharing/services/route_matching_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripSearchResultsPage extends StatelessWidget {
  final List<RouteMatch> matches;
  final String searchFrom;
  final String searchTo;

  const TripSearchResultsPage({
    super.key,
    required this.matches,
    required this.searchFrom,
    required this.searchTo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Search Results'),
            Text(
              '$searchFrom → $searchTo',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: matches.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No matching trips found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try adjusting your search criteria',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Found ${matches.length} matching trip${matches.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      return _buildMatchCard(context, matches[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMatchCard(BuildContext context, RouteMatch match) {
    final tripData = match.tripData;
    final tripId = match.tripId;

    String formattedDate = 'N/A';
    if (tripData['date'] is Timestamp) {
      formattedDate = DateFormat.yMd().add_jm().format(
        (tripData['date'] as Timestamp).toDate(),
      );
    }

    final price = tripData['price']?.toStringAsFixed(2) ?? 'N/A';
    final seats = tripData['seats']?.toString() ?? 'N/A';
    final matchPercentage = match.matchScore.round();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: match.matchScore > 70
              ? Colors.green
              : match.matchScore > 50
                  ? Colors.orange
                  : Colors.grey,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripDetailsPage(tripId: tripId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match score badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: match.matchScore > 70
                          ? Colors.green.shade100
                          : match.matchScore > 50
                              ? Colors.orange.shade100
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$matchPercentage% Match',
                      style: TextStyle(
                        color: match.matchScore > 70
                            ? Colors.green.shade900
                            : match.matchScore > 50
                                ? Colors.orange.shade900
                                : Colors.grey.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '€$price',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Route info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tripData['fromAddress'] ?? tripData['from'] ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (match.pickupStop != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 4),
                            child: Text(
                              'Pickup: ${match.pickupStop}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          if (match.distanceToPickup != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Text(
                                '${match.distanceToPickup!.toStringAsFixed(1)} km away',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tripData['toAddress'] ?? tripData['to'] ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (match.dropoffStop != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 4),
                            child: Text(
                              'Dropoff: ${match.dropoffStop}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          if (match.distanceToDropoff != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Text(
                                '${match.distanceToDropoff!.toStringAsFixed(1)} km away',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Trip details
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.event_seat, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '$seats seats',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    tripData['driverName'] ?? 'Unknown Driver',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
