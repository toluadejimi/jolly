import 'package:flutter/material.dart';

import 'product_list_screen.dart';
import 'settings_screen.dart';
import 'track_order_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Store'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_bag_outlined, size: 32),
              title: const Text('Browse Products'),
              subtitle: const Text('View all products'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_shipping_outlined, size: 32),
              title: const Text('Track Order'),
              subtitle: const Text('Enter your order number'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrackOrderScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
