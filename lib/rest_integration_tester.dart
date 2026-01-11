import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/app_providers.dart';
import 'core/pages/api_debug_screen.dart';

/// Quick integration tester
/// Shows side-by-side: Firebase data vs REST API
class RestIntegrationTester extends ConsumerWidget {
  const RestIntegrationTester({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Firebase vs REST API'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Firebase (Current)', icon: Icon(Icons.storage)),
              Tab(text: 'REST API (New)', icon: Icon(Icons.cloud)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Firebase (current)
            _buildFirebaseTab(context),
            
            // Tab 2: REST API (new)
            _buildRestApiTab(context),
          ],
        ),
      ),
    );
  }

  /// Show Firebase data and how it's used
  Widget _buildFirebaseTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('📊 Current Setup'),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Data Source',
            content:
                'All data is currently stored in Firebase\n\n'
                'Services using Firebase:\n'
                '• ride_list_page.dart (TripSearchService)\n'
                '• trip_search_service.dart\n'
                '• route_matching_service.dart\n'
                '• places_service.dart\n'
                '• profile_page.dart (user data)',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: '⚠️ Issue',
            content:
                'Popular Rides carousel deleted files restored.\n'
                'Search logic works but uses local data.\n\n'
                'Next: Replace with REST backend',
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('📋 Migration Checklist'),
          const SizedBox(height: 16),
          _buildChecklistItem('✅', 'Core infrastructure created (DioClient, TokenStorage)'),
          _buildChecklistItem('✅', 'All models created (Trip, Points, etc.)'),
          _buildChecklistItem('✅', 'API services implemented (TripApiService, BookingApiService)'),
          _buildChecklistItem('✅', 'Repositories & Riverpod setup'),
          _buildChecklistItem('✅', 'Example screens created'),
          _buildChecklistItem('⏳', 'Integrate new backend into existing screens'),
          _buildChecklistItem('⏳', 'Update ride_list_page.dart to use searchMatchingRouteProvider'),
          _buildChecklistItem('⏳', 'Authenticate with backend'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'See REST API Tab →\n'
                    'Test endpoints there',
                  ),
                ),
              );
            },
            child: const Text('Learn About Migration →'),
          ),
        ],
      ),
    );
  }

  /// Show REST API testing
  Widget _buildRestApiTab(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔗 REST Backend Integration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Backend: http://34.30.27.79:8080',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Text(
                '✅ Ready to use! All endpoints implemented:\n'
                '• Trip search (6 endpoints)\n'
                '• Bookings (3 endpoints)\n'
                '• Full error handling\n'
                '• Secure JWT auth',
                style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('🧪 Test Endpoints'),
                const SizedBox(height: 16),
                _buildQuickTestButton(
                  context,
                  'Full API Testing Console',
                  'Test all 9 endpoints with real data',
                  Colors.blue,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ApiDebugScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('📖 How to Integrate'),
                const SizedBox(height: 16),
                _buildStepCard(
                  '1. Enable Riverpod',
                  'Wrap your app with ProviderScope in main.dart\n✅ Already done!',
                ),
                _buildStepCard(
                  '2. Update ride_list_page.dart',
                  'Replace TripSearchService with:\n\n'
                  'final trips = ref.watch(searchMatchingRouteProvider((\n'
                  '  sourceLat: source.lat,\n'
                  '  sourceLon: source.lon,\n'
                  '  sourceRadiusKm: 5,\n'
                  '  destLat: dest.lat,\n'
                  '  destLon: dest.lon,\n'
                  '  destRadiusKm: 5,\n'
                  '  requestedSeats: 1,\n'
                  ')));',
                ),
                _buildStepCard(
                  '3. Copy Example Screen',
                  'Use trip_search_example.dart as reference.\n\n'
                  'Location:\n'
                  'lib/features/trip/presentation/pages/trip_search_example.dart',
                ),
                _buildStepCard(
                  '4. Test with Debug Console',
                  'Use the "Full API Testing Console" button above to verify all endpoints work with your backend.',
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('📚 Documentation'),
                const SizedBox(height: 16),
                _buildDocLink('Quick Start (5 min)', 'QUICKSTART_REST_INTEGRATION.md'),
                _buildDocLink('Complete Guide (30 min)', 'REST_BACKEND_INTEGRATION.md'),
                _buildDocLink('Architecture Diagrams', 'ARCHITECTURE_DIAGRAMS.md'),
                _buildDocLink('Troubleshooting', 'TROUBLESHOOTING.md'),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTestButton(
    BuildContext context,
    String title,
    String description,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Open Console',
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                    Icon(Icons.arrow_forward, color: color, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocLink(String title, String file) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.description, size: 18, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  file,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14),
        ],
      ),
    );
  }
}
