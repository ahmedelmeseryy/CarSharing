import 'package:flutter/material.dart';

class TripCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const TripCard({
    super.key,
    required this.ride,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  String _safe(Map<String, dynamic> r, String key) {
    final v = r[key];
    if (v == null) return '';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final start = _safe(ride, 'start');
    final end = _safe(ride, 'end');
    final date = _safe(ride, 'date');
    final time = _safe(ride, 'time');
    final driver = _safe(ride, 'driver');
    final price = _safe(ride, 'price');
    final seats = _safe(ride, 'seats');

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Left icon / avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.shade50,
                child: Icon(Icons.directions_car, size: 28, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$start → $end',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_month, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '$date ${time.isNotEmpty ? '• $time' : ''}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 12),
                        if (seats.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${seats} seats',
                              style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Driver: $driver', style: TextStyle(color: Colors.grey[800])),
                        const SizedBox(width: 8),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            price.isNotEmpty ? '€$price' : '—',
                            style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Actions
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : Colors.grey),
                    onPressed: onFavoriteToggle,
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
