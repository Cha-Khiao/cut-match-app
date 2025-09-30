import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/screens/admin/hairstyle_form_screen.dart';
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
    // getHairstyles is a public endpoint and does not require a token.
    setState(() {
      _hairstylesFuture = ApiService.getHairstyles();
    });
  }

  Future<void> _deleteHairstyle(String id) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      await ApiService.deleteHairstyle(id, token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hairstyle deleted successfully')),
      );
      _loadHairstyles();
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
      appBar: AppBar(title: const Text('Manage Hairstyles')),
      body: FutureBuilder<List<Hairstyle>>(
        future: _hairstylesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('No hairstyles found.'));
          }
          final hairstyles = snapshot.data!;
          return ListView.builder(
            itemCount: hairstyles.length,
            itemBuilder: (context, index) {
              final hairstyle = hairstyles[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: hairstyle.imageUrls.isNotEmpty
                      ? NetworkImage(hairstyle.imageUrls.first)
                      : null,
                ),
                title: Text(hairstyle.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HairstyleFormScreen(hairstyle: hairstyle),
                        ),
                      ).then((_) => _loadHairstyles()),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteHairstyle(hairstyle.id),
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
        heroTag: 'add_hairstyle_fab',
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
