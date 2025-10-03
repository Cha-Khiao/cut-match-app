import 'package:cut_match_app/screens/admin/hairstyles/admin_hairstyle_list_screen.dart';
import 'package:cut_match_app/screens/admin/salon/admin_salon_list_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:flutter/material.dart';

class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('แผงควบคุมแอดมิน')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              child: Icon(Icons.content_cut),
            ),
            title: Text('จัดการทรงผม', style: theme.textTheme.titleMedium),
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
            leading: const CircleAvatar(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              child: Icon(Icons.storefront_outlined),
            ),
            title: Text('จัดการร้านตัดผม', style: theme.textTheme.titleMedium),
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
