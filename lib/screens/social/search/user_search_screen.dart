import 'dart:async';
import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/user_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/screens/profiles/profile_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User>? _searchResults;
  Timer? _debounce;
  bool _isLoading = false;
  String? _errorMessage;

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
          _searchResults = null;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      try {
        final results = await ApiService.searchUsers(query, token);
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('ค้นหาผู้ใช้')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomTextField(
              controller: _searchController,
              hintText: 'พิมพ์ชื่อผู้ใช้เพื่อค้นหา...',
              icon: Icons.search,
              onChanged: _onSearchChanged,
              autofocus: true,
            ),
          ),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text('เกิดข้อผิดพลาด: $_errorMessage'));
    }
    if (_searchResults == null) {
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
    if (_searchResults!.isEmpty) {
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

    final users = _searchResults!;
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
            FocusScope.of(context).unfocus();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)),
            );
          },
        );
      },
    );
  }
}