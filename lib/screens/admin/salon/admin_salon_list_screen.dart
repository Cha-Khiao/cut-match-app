import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/salon_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/screens/admin/salon/admin_salon_form_screen.dart';
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
    }
  }

  Future<void> _deleteSalon(String id) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      await ApiService.deleteSalon(id, token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salon deleted successfully')),
      );
      _loadSalons();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Salons')),
      body: FutureBuilder<List<Salon>>(
        future: _salonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('No salons found.'));
          }
          final salons = snapshot.data!;
          return ListView.builder(
            itemCount: salons.length,
            itemBuilder: (context, index) {
              final salon = salons[index];
              return ListTile(
                leading: const Icon(Icons.storefront),
                title: Text(salon.name),
                subtitle: Text(salon.address),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminSalonFormScreen(salon: salon),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _loadSalons();
                            }
                          }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSalon(salon.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        // --- ✨ แก้ไขตรงนี้ ✨ ---
        heroTag: 'add_salon_fab',
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
