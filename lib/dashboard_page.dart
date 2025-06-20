import 'package:flutter/material.dart';
import 'ride_list_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSearchCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Featured Rides'),
          const SizedBox(height: 16),
          _buildFeaturedRide(context, 'Berlin', 'München', 'assets/berlin.jpg'),
          const SizedBox(height: 16),
          _buildFeaturedRide(context, 'Hamburg', 'Köln', 'assets/hamburg.jpg'),
          const SizedBox(height: 16),
          _buildFeaturedRide(context, 'Frankfurt', 'Stuttgart', 'assets/frankfurt.jpg'),
        ],
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Where are you going?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for a destination...',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RideListPage(searchQuery: value),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RideListPage(searchQuery: _searchController.text),
                    ),
                  );
                },
                child: const Text('Search Rides'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildFeaturedRide(BuildContext context, String from, String to, String imagePath) {
    // NOTE: This assumes you have images in an assets/ folder.
    // You'll need to create this folder and add the images.
    // Also, update pubspec.yaml to include 'assets/'.
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Image.asset(
          //   imagePath,
          //   height: 150,
          //   width: double.infinity,
          //   fit: BoxFit.cover,
          //   errorBuilder: (context, error, stackTrace) => Container(
          //     height: 150,
          //     color: Colors.grey[300],
          //     child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
          //   ),
          // ),
          Container( // Placeholder for image
             height: 150,
             color: Colors.grey[300],
             child: Icon(Icons.image, color: Colors.grey[600], size: 50),
          ),
          ListTile(
            title: Text('$from to $to', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Available now - Starting from €25'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RideListPage(searchQuery: to),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 