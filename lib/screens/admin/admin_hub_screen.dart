import 'package:cut_match_app/screens/admin/admin_hairstyle_list_screen.dart';
import 'package:cut_match_app/screens/admin/admin_salon_list_screen.dart';
import 'package:flutter/material.dart';

class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.content_cut),
            title: const Text('Manage Hairstyles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminHairstyleListScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Manage Salons'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSalonListScreen()),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
