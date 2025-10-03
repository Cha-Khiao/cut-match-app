import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/screens/admin/hairstyles/hairstyle_form_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminHairstyleListScreen extends StatefulWidget {
  const AdminHairstyleListScreen({super.key});

  @override
  State<AdminHairstyleListScreen> createState() =>
      _AdminHairstyleListScreenState();
}

class _AdminHairstyleListScreenState extends State<AdminHairstyleListScreen> {
  late Future<List<Hairstyle>> _hairstylesFuture;

  @override
  void initState() {
    super.initState();
    _loadHairstyles();
  }

  void _loadHairstyles() {
    setState(() {
      _hairstylesFuture = ApiService.getHairstyles();
    });
  }

  Future<void> _confirmDelete(String id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบทรงผมนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'ลบ',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteHairstyle(id);
    }
  }

  Future<void> _deleteHairstyle(String id) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      await ApiService.deleteHairstyle(id, token);
      NotificationHelper.showSuccess(context, message: 'ลบทรงผมเรียบร้อยแล้ว');
      _loadHairstyles();
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(context, message: 'ลบไม่สำเร็จ: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('จัดการทรงผม')),
      body: RefreshIndicator(
        onRefresh: () async => _loadHairstyles(),
        child: FutureBuilder<List<Hairstyle>>(
          future: _hairstylesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sentiment_dissatisfied_outlined,
                      size: 80,
                      color: AppTheme.lightText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่พบข้อมูลทรงผม',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ],
                ),
              );
            }
            final hairstyles = snapshot.data!;
            return ListView.separated(
              itemCount: hairstyles.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final hairstyle = hairstyles[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppTheme.background,
                    backgroundImage: hairstyle.imageUrls.isNotEmpty
                        ? NetworkImage(hairstyle.imageUrls.first)
                        : null,
                    child: hairstyle.imageUrls.isEmpty
                        ? const Icon(Icons.image_not_supported)
                        : null,
                  ),
                  title: Text(
                    hairstyle.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HairstyleFormScreen(hairstyle: hairstyle),
                          ),
                        ).then((_) => _loadHairstyles()),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () => _confirmDelete(hairstyle.id),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'เพิ่มทรงผมใหม่',
        onPressed: () =>
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HairstyleFormScreen()),
            ).then((result) {
              if (result == true) {
                _loadHairstyles();
              }
            }),
        child: const Icon(Icons.add),
      ),
    );
  }
}
