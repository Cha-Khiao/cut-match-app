import 'dart:async';
import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/user_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/screens/profiles/profile_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Future<List<User>>? _searchFuture;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _searchFuture = null;
        });
      }
    });
  }

  void _performSearch(String query) {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      setState(() {
        _searchFuture = ApiService.searchUsers(query, token);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // ✨ [UI Revamp] ปรับปรุง TextField ใน AppBar
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ค้นหาผู้ใช้...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppTheme.lightText),
          ),
          style: theme.textTheme.titleLarge, // ใช้สไตล์จาก Theme
          onChanged: _onSearchChanged,
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_searchFuture == null) {
      // ✨ [UI Revamp & i18n] ออกแบบหน้าเริ่มต้นใหม่
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 80, color: AppTheme.lightText),
            const SizedBox(height: 16),
            Text(
              'เริ่มพิมพ์เพื่อค้นหาผู้ใช้',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightText,
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<User>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // ✨ [UI Revamp & i18n] ออกแบบหน้าไม่พบผลลัพธ์ใหม่
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_search_outlined,
                  size: 80,
                  color: AppTheme.lightText,
                ),
                const SizedBox(height: 16),
                Text(
                  'ไม่พบผู้ใช้',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.lightText,
                  ),
                ),
              ],
            ),
          );
        }
        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.background,
                backgroundImage: user.profileImageUrl.isNotEmpty
                    ? NetworkImage(user.profileImageUrl)
                    : null,
                child: user.profileImageUrl.isEmpty
                    ? const Icon(Icons.person, color: AppTheme.lightText)
                    : null,
              ),
              title: Text(
                user.username,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                // ซ่อนคีย์บอร์ดก่อนเปลี่ยนหน้า
                FocusScope.of(context).unfocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: user.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}