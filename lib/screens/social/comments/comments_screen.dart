import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/comment_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  late Future<List<Comment>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      setState(() {
        _commentsFuture = ApiService.getComments(widget.postId, token);
      });
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _isPosting) return;

    setState(() => _isPosting = true);

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      await ApiService.createComment(
        widget.postId,
        _commentController.text.trim(),
        token!,
      );
      _commentController.clear();
      FocusScope.of(context).unfocus();
      _loadComments();
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(context, message: 'เกิดข้อผิดพลาด: $e');
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('ความคิดเห็น')),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadComments(),
              color: theme.colorScheme.primary,
              child: FutureBuilder<List<Comment>>(
                future: _commentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('เกิดข้อผิดพลาดในการโหลดความคิดเห็น'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.forum_outlined,
                              size: 80,
                              color: AppTheme.lightText,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ยังไม่มีความคิดเห็น',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'เป็นคนแรกที่แสดงความคิดเห็น!',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppTheme.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final comments = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.background,
                          backgroundImage:
                              comment.author.profileImageUrl.isNotEmpty
                              ? NetworkImage(comment.author.profileImageUrl)
                              : null,
                          child: comment.author.profileImageUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: AppTheme.lightText,
                                )
                              : null,
                        ),
                        title: Text(
                          comment.author.username,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          comment.text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.darkText,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          _buildCommentInputField(theme),
        ],
      ),
    );
  }

  Widget _buildCommentInputField(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        8,
        MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'เพิ่มความคิดเห็น...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: _isPosting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : Icon(Icons.send, color: theme.colorScheme.primary),
              onPressed: _postComment,
            ),
          ],
        ),
      ),
    );
  }
}