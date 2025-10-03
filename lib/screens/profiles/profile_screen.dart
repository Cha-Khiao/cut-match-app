import 'dart:io';
import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/models/user_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:cut_match_app/providers/profile_provider.dart';
import 'package:cut_match_app/screens/photos/photo_viewer_screen.dart';
import 'package:cut_match_app/screens/social/posts/post_detail_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:cut_match_app/widgets/hairstyle_card.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final targetUserId = userId ?? authProvider.user!.id;

    return ChangeNotifierProvider(
      create: (_) =>
          ProfileProvider(userId: targetUserId, token: authProvider.token),
      child: const _ProfileScreenView(),
    );
  }
}

class _ProfileScreenView extends StatelessWidget {
  const _ProfileScreenView();

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              authProvider.logout().then(
                (_) => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/welcome', (route) => false),
              );
            },
            child: Text(
              'ออกจากระบบ',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isMyProfile = profileProvider.userId == authProvider.user?.id;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          profileProvider.isLoading
              ? (isMyProfile ? 'My Profile' : 'Profile')
              : profileProvider.user?.username ?? '...',
        ),
        actions: [
          if (isMyProfile)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.pushNamed(
                    context,
                    '/edit_profile',
                  ).then((_) => profileProvider.fetchProfileData());
                } else if (value == 'about') {
                  Navigator.pushNamed(context, '/about');
                } else if (value == 'logout') {
                  _confirmLogout(context, authProvider);
                }
              },
              itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('แก้ไขโปรไฟล์'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'about',
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('เกี่ยวกับแอปพลิเคชัน'),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: theme.colorScheme.error),
                    title: Text(
                      'ออกจากระบบ',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileProvider.errorMessage != null
          ? Center(
              child: Text('เกิดข้อผิดพลาด: ${profileProvider.errorMessage}'),
            )
          : _buildProfileBody(
              context,
              profileProvider,
              authProvider,
              isMyProfile,
            ),
    );
  }

  Widget _buildProfileBody(
    BuildContext context,
    ProfileProvider profileProvider,
    AuthProvider authProvider,
    bool isMyProfile,
  ) {
    return DefaultTabController(
      length: isMyProfile ? 3 : 1,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              user: profileProvider.user!,
              authProvider: authProvider,
              isMyProfile: isMyProfile,
              onProfileUpdate: profileProvider.fetchProfileData,
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverTabBarDelegate(
              TabBar(
                tabs: [
                  const Tab(icon: Icon(Icons.grid_on_outlined), text: 'โพสต์'),
                  if (isMyProfile)
                    const Tab(
                      icon: Icon(Icons.favorite_outline),
                      text: 'ถูกใจ',
                    ),
                  if (isMyProfile)
                    const Tab(
                      icon: Icon(Icons.bookmark_border_outlined),
                      text: 'บันทึกไว้',
                    ),
                ],
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.lightText,
              ),
            ),
            pinned: true,
          ),
        ],
        body: TabBarView(
          children: [
            _PostsGrid(posts: profileProvider.posts),
            if (isMyProfile)
              _FavoriteHairstylesGrid(authProvider: authProvider),
            if (isMyProfile) _SavedLooksGrid(looks: authProvider.savedLooks),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;
  final AuthProvider authProvider;
  final bool isMyProfile;
  final VoidCallback onProfileUpdate;

  const _ProfileHeader({
    required this.user,
    required this.authProvider,
    required this.isMyProfile,
    required this.onProfileUpdate,
  });

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null && context.mounted) {
      final success = await authProvider.updateProfile(
        imageFile: File(image.path),
        feedProvider: feedProvider,
      );
      if (success) {
        onProfileUpdate();
      } else if (context.mounted) {
        NotificationHelper.showError(
          context,
          message: authProvider.errorMessage ?? 'อัปเดตโปรไฟล์ไม่สำเร็จ',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: AppTheme.background,
                    backgroundImage: user.profileImageUrl.isNotEmpty
                        ? NetworkImage(user.profileImageUrl)
                        : null,
                    child: user.profileImageUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 45,
                            color: AppTheme.lightText,
                          )
                        : null,
                  ),
                  if (isMyProfile)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _pickAndUploadImage(context),
                        child: const CircleAvatar(
                          radius: 15,
                          backgroundColor: AppTheme.primary,
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(context, 'โพสต์', user.postCount ?? 0),
                    _buildStatColumn(
                      context,
                      'ผู้ติดตาม',
                      user.followerCount ?? 0,
                    ),
                    _buildStatColumn(
                      context,
                      'กำลังติดตาม',
                      user.followingCount ?? 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(user.username, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildActionButtons(context),
          if (user.salonName.isNotEmpty && user.salonMapUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _buildSalonCard(context, user.salonName, user.salonMapUrl),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, int count) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (isMyProfile) {
      return const SizedBox.shrink();
    } else {
      final isFollowing = authProvider.isFollowing(user.id);
      return SizedBox(
        width: double.infinity,
        child: isFollowing
            ? OutlinedButton(
                onPressed: () => authProvider
                    .toggleFollow(user.id)
                    .then((_) => onProfileUpdate()),
                child: const Text('กำลังติดตาม'),
              )
            : ElevatedButton(
                onPressed: () => authProvider
                    .toggleFollow(user.id)
                    .then((_) => onProfileUpdate()),
                child: const Text('ติดตาม'),
              ),
      );
    }
  }

  Widget _buildSalonCard(
    BuildContext context,
    String salonName,
    String salonMapUrl,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppTheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: const Icon(Icons.storefront_outlined, color: AppTheme.primary),
        title: Text(
          salonName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('ดูตำแหน่งบนแผนที่'),
        trailing: const Icon(Icons.open_in_new),
        onTap: () async {
          final Uri url = Uri.parse(salonMapUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else if (context.mounted) {
            NotificationHelper.showError(
              context,
              message: 'ไม่สามารถเปิดแผนที่ได้',
            );
          }
        },
      ),
    );
  }
}

class _PostsGrid extends StatelessWidget {
  final List<Post> posts;
  const _PostsGrid({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: Text('ยังไม่มีโพสต์'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        if (post.imageUrls.isEmpty) {
          return Container(color: Colors.grey.shade300);
        }
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          ),
          child: Image.network(post.imageUrls.first, fit: BoxFit.cover),
        );
      },
    );
  }
}

class _FavoriteHairstylesGrid extends StatelessWidget {
  final AuthProvider authProvider;
  const _FavoriteHairstylesGrid({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Hairstyle>>(
      future: ApiService.getFavorites(authProvider.token!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ยังไม่มีทรงผมที่ถูกใจ'));
        }
        final favoriteHairstyles = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: favoriteHairstyles.length,
          itemBuilder: (context, index) {
            return HairstyleCard(hairstyle: favoriteHairstyles[index]);
          },
        );
      },
    );
  }
}

class _SavedLooksGrid extends StatelessWidget {
  final List<String> looks;
  const _SavedLooksGrid({required this.looks});

  @override
  Widget build(BuildContext context) {
    if (looks.isEmpty) {
      return const Center(child: Text('ยังไม่มีรูปภาพที่บันทึกไว้'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: looks.length,
      itemBuilder: (context, index) {
        final imageUrl = looks[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PhotoViewerScreen(imageUrl: imageUrl),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}
