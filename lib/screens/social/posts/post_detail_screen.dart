import 'package:cut_match_app/models/comment_model.dart';
import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:cut_match_app/providers/post_detail_provider.dart';
import 'package:cut_match_app/screens/profiles/profile_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => PostDetailProvider(
        post: post,
        token: Provider.of<AuthProvider>(ctx, listen: false).token!,
        feedProvider: Provider.of<FeedProvider>(ctx, listen: false),
      ),
      child: const _PostDetailScreenView(),
    );
  }
}

class _PostDetailScreenView extends StatefulWidget {
  const _PostDetailScreenView();

  @override
  State<_PostDetailScreenView> createState() => _PostDetailScreenViewState();
}

class _PostDetailScreenViewState extends State<_PostDetailScreenView> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final provider = Provider.of<PostDetailProvider>(context, listen: false);

    final text = _commentController.text.trim();
    _commentController.clear();
    FocusScope.of(context).unfocus();

    try {
      await provider.createComment(text);
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(context, message: 'เกิดข้อผิดพลาด: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostDetailProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text("โพสต์ของ ${provider.post.author.username}")),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.fetchComments,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _PostContent(post: provider.post)),
                  const SliverToBoxAdapter(child: Divider(height: 1)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'ความคิดเห็น',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                  if (provider.isLoading)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),

                  if (provider.errorMessage != null)
                    SliverToBoxAdapter(
                      child: Center(child: Text(provider.errorMessage!)),
                    ),

                  if (!provider.isLoading && provider.comments.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('ยังไม่มีความคิดเห็น'),
                        ),
                      ),
                    ),

                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _CommentItem(comment: provider.comments[index]),
                      childCount: provider.comments.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _CommentInputField(
            controller: _commentController,
            onPost: _postComment,
          ),
        ],
      ),
    );
  }
}

class _PostContent extends StatelessWidget {
  final Post post;
  const _PostContent({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageController = PageController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.background,
                backgroundImage: post.author.profileImageUrl.isNotEmpty
                    ? NetworkImage(post.author.profileImageUrl)
                    : null,
                child: post.author.profileImageUrl.isEmpty
                    ? const Icon(Icons.person, color: AppTheme.lightText)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(post.author.username, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        if (post.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(post.text, style: theme.textTheme.bodyLarge),
          ),
        if (post.imageUrls.isNotEmpty)
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: post.imageUrls.length,
                  itemBuilder: (context, index) =>
                      Image.network(post.imageUrls[index], fit: BoxFit.cover),
                ),
                if (post.imageUrls.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SmoothPageIndicator(
                      controller: pageController,
                      count: post.imageUrls.length,
                      effect: const WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: AppTheme.primary,
                        dotColor: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;
  const _CommentItem({required this.comment});

  void _showCommentOptions(
    BuildContext context,
    PostDetailProvider provider,
    Comment c,
  ) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('แก้ไข'),
            onTap: () {
              Navigator.of(ctx).pop();
              _showEditDialog(context, provider, c);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text('ลบ', style: TextStyle(color: theme.colorScheme.error)),
            onTap: () {
              Navigator.of(ctx).pop();
              _deleteComment(context, provider, c.id);
            },
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(
    BuildContext context,
    PostDetailProvider provider,
    Comment parentComment,
  ) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ตอบกลับถึง ${parentComment.author.username}'),
        content: TextField(
          controller: replyController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'เขียนการตอบกลับ...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.trim().isEmpty) return;
              try {
                await provider.replyToComment(
                  parentComment.id,
                  replyController.text.trim(),
                );
                Navigator.of(ctx).pop();
              } catch (e) {
                if (ctx.mounted) {
                  NotificationHelper.showError(
                    ctx,
                    message: 'ตอบกลับไม่สำเร็จ: $e',
                  );
                }
              }
            },
            child: const Text('ตอบกลับ'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    PostDetailProvider provider,
    Comment commentToEdit,
  ) {
    final editController = TextEditingController(text: commentToEdit.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('แก้ไขความคิดเห็น'),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.trim().isEmpty) return;
              try {
                await provider.updateComment(
                  commentToEdit.id,
                  editController.text.trim(),
                );
                Navigator.of(ctx).pop();
              } catch (e) {
                if (ctx.mounted) {
                  NotificationHelper.showError(
                    ctx,
                    message: 'แก้ไขไม่สำเร็จ: $e',
                  );
                }
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(
    BuildContext context,
    PostDetailProvider provider,
    String commentId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบความคิดเห็น'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบความคิดเห็นนี้?'),
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

    if (confirm == true && context.mounted) {
      try {
        await provider.deleteComment(commentId);
      } catch (e) {
        if (context.mounted) {
          NotificationHelper.showError(context, message: 'ลบไม่สำเร็จ: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<PostDetailProvider>(context, listen: false);
    final isOwner = authProvider.user?.id == comment.author.id;
    final theme = Theme.of(context);

    Widget buildCommentContent({bool isReply = false}) {
      return Padding(
        padding: EdgeInsets.fromLTRB(isReply ? 56.0 : 16.0, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(userId: comment.author.id),
                    ),
                  ),
                  child: CircleAvatar(
                    radius: isReply ? 16 : 20,
                    backgroundImage: comment.author.profileImageUrl.isNotEmpty
                        ? NetworkImage(comment.author.profileImageUrl)
                        : null,
                    child: comment.author.profileImageUrl.isEmpty
                        ? Icon(Icons.person, size: isReply ? 16 : 20)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.author.username,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(comment.text, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppTheme.lightText,
                    ),
                    onPressed: () =>
                        _showCommentOptions(context, provider, comment),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 52.0),
              child: TextButton(
                onPressed: () => _showReplyDialog(context, provider, comment),
                child: const Text('ตอบกลับ'),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        buildCommentContent(),
        ...comment.replies.map((reply) => buildCommentContent(isReply: true)),
      ],
    );
  }
}

class _CommentInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPost;
  const _CommentInputField({required this.controller, required this.onPost});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        8,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'เพิ่มความคิดเห็น...',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.primary),
            onPressed: onPost,
          ),
        ],
      ),
    );
  }
}