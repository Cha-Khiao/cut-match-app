import 'dart:async';
import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/providers/notification_provider.dart'; // <-- 1. เพิ่ม Import
import 'package:cut_match_app/screens/notification_screen.dart'; // <-- 2. เพิ่ม Import
import 'package:cut_match_app/widgets/hairstyle_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Hairstyle>>? _hairstylesFuture;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedGender;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchHairstyles();
  }

  void _fetchHairstyles() {
    setState(() {
      _hairstylesFuture = ApiService.getHairstyles(
        gender: _selectedGender,
        search: _searchController.text.trim(),
      );
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchHairstyles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Hairstyle Gallery',
          style: TextStyle(color: Colors.black),
        ),
        // --- ✨ 3. แก้ไขส่วน actions ✨ ---
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, child) {
              return Badge(
                label: Text('${notifProvider.unreadCount}'),
                isLabelVisible: notifProvider.unreadCount > 0,
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                  tooltip: 'Notifications',
                ),
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              if (auth.isAdmin) {
                return IconButton(
                  icon: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.blue,
                  ),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/admin_hub',
                  ).then((_) => _fetchHairstyles()),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search hairstyles...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', 'ชาย', 'หญิง', 'Unisex'].map((gender) {
                      final isSelected =
                          _selectedGender == gender ||
                          (gender == 'All' && _selectedGender == null);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(gender),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(
                              () => _selectedGender = (gender == 'All')
                                  ? null
                                  : gender,
                            );
                            _fetchHairstyles();
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: Colors.black,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Hairstyle>>(
              future: _hairstylesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hairstyles found.'));
                }
                final hairstyles = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async => _fetchHairstyles(),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: hairstyles.length,
                    itemBuilder: (context, index) {
                      return HairstyleCard(hairstyle: hairstyles[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
