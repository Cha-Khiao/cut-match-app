import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/widgets/hairstyle_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Hairstyle>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  void _fetchFavorites() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    setState(() {
      if (token != null) {
        _favoritesFuture = ApiService.getFavorites(token);
      } else {
        _favoritesFuture = Future.value([]);
      }
    });
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 80,
              color: AppTheme.lightText,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีรายการโปรด',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ไปที่แกลเลอรีแล้วกด ❤️ ที่ทรงผมที่คุณชอบได้เลย!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('ทรงผมที่ถูกใจ')),
      body: FutureBuilder<List<Hairstyle>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final favoriteHairstyles = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _fetchFavorites(),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final filteredList = favoriteHairstyles
                    .where((h) => authProvider.isFavorite(h.id))
                    .toList();

                if (filteredList.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    return HairstyleCard(hairstyle: filteredList[index]);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}