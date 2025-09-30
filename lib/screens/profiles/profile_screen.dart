import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/screens/post_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>>? _profileFuture;
  Future<List<Post>>? _postsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfileData();
    });
  }

  void _fetchProfileData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final targetUserId = widget.userId ?? authProvider.user?.id;

    if (targetUserId != null && mounted) {
      setState(() {
        _profileFuture = ApiService.getUserPublicProfile(targetUserId);
        _postsFuture = ApiService.getUserPosts(
          targetUserId,
          authProvider.token!,
        );
      });
    }
  }

  Future<void> _pickAndUploadImage(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    // Add image picker logic here if needed
  }

  void _showPostOptions(BuildContext context, Post post) {
    // Add post options logic here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final isMyProfile =
                widget.userId == null ||
                widget.userId == context.watch<AuthProvider>().user?.id;
            if (snapshot.hasData) {
              return Text(snapshot.data!['username'] ?? 'Profile');
            }
            return Text(isMyProfile ? 'My Profile' : 'Profile');
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('Failed to load profile: ${snapshot.error}'),
            );
          }

          final profileData = snapshot.data!;
          final authProvider = context.watch<AuthProvider>();
          final isMyProfile =
              widget.userId == null || widget.userId == authProvider.user?.id;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: _buildProfileHeaderSection(
                  context,
                  authProvider,
                  profileData,
                  isMyProfile,
                ),
              ),
            ],
            body: _buildPostsGrid(isMyProfile),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeaderSection(
    BuildContext context,
    AuthProvider authProvider,
    Map<String, dynamic> profileData,
    bool isMyProfile,
  ) {
    final targetUserId = profileData['_id'] as String;

    // ✅ ป้องกัน type error ที่อาจเกิดจากการ cast ผิดชนิด
    final salonNameRaw = profileData['salonName'];
    final salonMapUrlRaw = profileData['salonMapUrl'];

    final salonName = salonNameRaw is String ? salonNameRaw : '';
    final salonMapUrl = salonMapUrlRaw is String ? salonMapUrlRaw : '';

    final isFollowing = authProvider.isFollowing(targetUserId);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildProfileHeader(context, authProvider, profileData, isMyProfile),
          const SizedBox(height: 16),
          Text(
            profileData['username'] ?? 'No Name',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatRow(profileData),
          const SizedBox(height: 16),
          _buildActionButtons(
            context,
            authProvider,
            isMyProfile,
            isFollowing,
            targetUserId,
          ),
          const SizedBox(height: 16),
          if (salonMapUrl.isNotEmpty)
            _buildSalonCard(context, salonName, salonMapUrl),
          if (isMyProfile) _buildMyProfileMenu(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AuthProvider authProvider,
    Map<String, dynamic> profileData,
    bool isMyProfile,
  ) {
    final imageUrl = profileData['profileImageUrl'] as String?;
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                ? NetworkImage(imageUrl)
                : null,
            child: (imageUrl == null || imageUrl.isEmpty)
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          if (isMyProfile)
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => _pickAndUploadImage(context, authProvider),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(Map<String, dynamic> profileData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn('Posts', profileData['postCount'] ?? 0),
        _buildStatColumn('Followers', profileData['followerCount'] ?? 0),
        _buildStatColumn('Following', profileData['followingCount'] ?? 0),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AuthProvider authProvider,
    bool isMyProfile,
    bool isFollowing,
    String targetUserId,
  ) {
    if (isMyProfile) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/edit_profile',
              ).then((_) => _fetchProfileData()),
              child: const Text('Edit Profile'),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => authProvider.logout().then(
              (_) => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/welcome', (route) => false),
            ),
            child: const Text('Logout'),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => authProvider
              .toggleFollow(targetUserId)
              .then((_) => _fetchProfileData()),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey : Colors.blueAccent,
          ),
          child: Text(isFollowing ? 'Unfollow' : 'Follow'),
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
      child: ListTile(
        leading: const Icon(Icons.location_on, color: Colors.red),
        title: Text(salonName),
        subtitle: const Text('Tap to view on map'),
        trailing: const Icon(Icons.open_in_new),
        onTap: () async {
          final Uri url = Uri.parse(salonMapUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not launch map')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildMyProfileMenu(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        ListTile(
          leading: const Icon(Icons.favorite),
          title: const Text('My Favorites'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/favorites'),
        ),
        ListTile(
          leading: const Icon(Icons.style),
          title: const Text('My Saved Looks'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/saved_looks'),
        ),
      ],
    );
  }

  Widget _buildPostsGrid(bool isMyProfile) {
    return FutureBuilder<List<Post>>(
      future: _postsFuture,
      builder: (context, postSnapshot) {
        if (postSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!postSnapshot.hasData || postSnapshot.data!.isEmpty) {
          return const Center(child: Text('No posts yet.'));
        }
        final posts = postSnapshot.data!;
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
              onLongPress: () {
                if (isMyProfile) {
                  _showPostOptions(context, post);
                }
              },
              child: Image.network(post.imageUrls.first, fit: BoxFit.cover),
            );
          },
        );
      },
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
