import 'dart:async';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/providers/hairstyle_provider.dart';
import 'package:cut_match_app/providers/notification_provider.dart';
import 'package:cut_match_app/screens/social/notifications/notification_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/widgets/custom_textfield.dart';
import 'package:cut_match_app/widgets/hairstyle_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HairstyleListScreen extends StatefulWidget {
  const HairstyleListScreen({super.key});
  @override
  State<HairstyleListScreen> createState() => _HairstyleListScreenState();
}

class _HairstyleListScreenState extends State<HairstyleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedGender;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HairstyleProvider>(context, listen: false).fetchHairstyles();
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<HairstyleProvider>(
        context,
        listen: false,
      ).fetchHairstyles(search: query, gender: _selectedGender);
    });
  }

  void _onFilterChanged(String gender) {
    setState(() => _selectedGender = (gender == 'All') ? null : gender);
    Provider.of<HairstyleProvider>(context, listen: false).fetchHairstyles(
      search: _searchController.text.trim(),
      gender: _selectedGender,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hairstyle Gallery'),
        centerTitle: false,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, child) {
              return Badge(
                label: Text('${notifProvider.unreadCount}'),
                isLabelVisible: notifProvider.hasUnreadNotifications,
                backgroundColor: theme.colorScheme.error,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  ),
                  tooltip: 'การแจ้งเตือน',
                ),
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              if (auth.isAdmin) {
                return IconButton(
                  icon: Icon(Icons.admin_panel_settings),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/admin_hub').then(
                        (_) => Provider.of<HairstyleProvider>(
                          context,
                          listen: false,
                        ).fetchHairstyles(),
                      ),
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
                CustomTextField(
                  controller: _searchController,
                  hintText: 'ค้นหาทรงผม...',
                  icon: Icons.search,
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['ทั้งหมด', 'ชาย', 'หญิง', 'Unisex'].map((
                      gender,
                    ) {
                      final isSelected =
                          _selectedGender == gender ||
                          (gender == 'ทั้งหมด' && _selectedGender == null);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(gender),
                          selected: isSelected,
                          onSelected: (selected) => _onFilterChanged(
                            gender == 'ทั้งหมด' ? 'All' : gender,
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
            child: Consumer<HairstyleProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.errorMessage != null) {
                  return Center(
                    child: Text('เกิดข้อผิดพลาด: ${provider.errorMessage}'),
                  );
                }
                if (provider.hairstyles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 80,
                          color: AppTheme.lightText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่พบทรงผมที่ค้นหา',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppTheme.lightText,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => provider.fetchHairstyles(
                    gender: _selectedGender,
                    search: _searchController.text.trim(),
                  ),
                  color: theme.colorScheme.primary,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: provider.hairstyles.length,
                    itemBuilder: (context, index) {
                      return HairstyleCard(
                        hairstyle: provider.hairstyles[index],
                      );
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
