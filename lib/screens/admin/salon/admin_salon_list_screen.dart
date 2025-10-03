import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/salon_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/screens/admin/salon/admin_salon_form_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminSalonListScreen extends StatefulWidget {
  const AdminSalonListScreen({super.key});

  @override
  State<AdminSalonListScreen> createState() => _AdminSalonListScreenState();
}

class _AdminSalonListScreenState extends State<AdminSalonListScreen> {
  late Future<List<Salon>> _salonsFuture;

  @override
  void initState() {
    super.initState();
    _loadSalons();
  }

  void _loadSalons() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      setState(() {
        _salonsFuture = ApiService.getSalons(token);
      });
    } else {
      _salonsFuture = Future.value([]);
    }
  }

  Future<void> _confirmDelete(String id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบร้านตัดผมนี้?'),
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
      await _deleteSalon(id);
    }
  }

  Future<void> _deleteSalon(String id) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      await ApiService.deleteSalon(id, token);
      NotificationHelper.showSuccess(
        context,
        message: 'ลบร้านตัดผมเรียบร้อยแล้ว',
      );
      _loadSalons();
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
      appBar: AppBar(title: const Text('จัดการร้านตัดผม')),
      body: RefreshIndicator(
        onRefresh: () async => _loadSalons(),
        child: FutureBuilder<List<Salon>>(
          future: _salonsFuture,
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
                      Icons.store_mall_directory_outlined,
                      size: 80,
                      color: AppTheme.lightText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่พบข้อมูลร้านตัดผม',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ],
                ),
              );
            }
            final salons = snapshot.data!;
            return ListView.separated(
              itemCount: salons.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final salon = salons[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.background,
                    child: Icon(
                      Icons.storefront_outlined,
                      color: AppTheme.accent,
                    ),
                  ),
                  title: Text(salon.name, style: theme.textTheme.titleMedium),
                  subtitle: Text(
                    salon.address,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminSalonFormScreen(salon: salon),
                              ),
                            ).then((result) {
                              if (result == true) _loadSalons();
                            }),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () => _confirmDelete(salon.id),
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
        tooltip: 'เพิ่มร้านตัดผมใหม่',
        onPressed: () =>
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminSalonFormScreen()),
            ).then((result) {
              if (result == true) {
                _loadSalons();
              }
            }),
        child: const Icon(Icons.add),
      ),
    );
  }
}
