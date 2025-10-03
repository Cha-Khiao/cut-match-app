import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/comment_model.dart';
import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:cut_match_app/screens/profiles/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<List<Comment>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadComments() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      setState(() {
        _commentsFuture = ApiService.getComments(widget.post.id, token);
      });
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _isPosting) return;
    setState(() => _isPosting = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      await ApiService.createComment(
        widget.post.id,
        _commentController.text.trim(),
        token!,
      );
      Provider.of<FeedProvider>(
        context,
        listen: false,
      ).incrementCommentCount(widget.post.id);
      _commentController.clear();
      FocusScope.of(context).unfocus();
      _loadComments();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _showReplyDialog(Comment parentComment) {
    final replyController = TextEditingController();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    bool isDialogPosting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Reply to ${parentComment.author.username}'),
            content: TextField(
              controller: replyController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Your reply...'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isDialogPosting
                    ? null
                    : () async {
                        if (replyController.text.trim().isEmpty) return;
                        // --- ✨ แก้ไขส่วนนี้ ✨ ---
                        setDialogState(() {
                          isDialogPosting = true;
                        });
                        try {
                          await ApiService.replyToComment(
                            parentComment.id,
                            replyController.text.trim(),
                            token!,
                          );
                          if (mounted) Navigator.of(ctx).pop();
                          _loadComments();
                        } catch (e) {
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to reply: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                        } finally {
                          if (mounted)
                            setDialogState(() {
                              isDialogPosting = false;
                            });
                        }
                      },
                child: isDialogPosting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Reply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(Comment commentToEdit) {
    final editController = TextEditingController(text: commentToEdit.text);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (editController.text.trim().isEmpty) return;
              try {
                await ApiService.updateComment(
                  commentToEdit.id,
                  editController.text.trim(),
                  token!,
                );
                Navigator.of(ctx).pop();
                _loadComments();
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Failed to edit: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      try {
        await ApiService.deleteComment(commentId, token!);
        Provider.of<FeedProvider>(
          context,
          listen: false,
        ).decrementCommentCount(widget.post.id);
        _loadComments();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  void _showCommentOptions(Comment comment) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.of(ctx).pop();
              _showEditDialog(comment);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(ctx).pop();
              _deleteComment(comment.id);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.post.author.username}'s Post")),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Comment>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading comments: ${snapshot.error}'),
                  );
                }
                final comments = snapshot.data ?? [];

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildPostContent()),
                    const SliverToBoxAdapter(child: Divider(height: 1)),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (comments.isEmpty)
                      const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No comments yet.'),
                          ),
                        ),
                      ),

                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildCommentItem(comments[index]),
                        childCount: comments.length,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, {bool isReply = false}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.user?.id == comment.author.id;

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 56.0 : 16.0,
        right: 16,
        top: 8,
        bottom: 8,
      ),
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
                  backgroundImage: NetworkImage(comment.author.profileImageUrl),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                comment.author.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isOwner)
                SizedBox(
                  height: 30,
                  width: 30,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 18),
                    onPressed: () => _showCommentOptions(comment),
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: isReply ? 40.0 : 48.0, top: 4),
            child: Text(comment.text),
          ),
          Padding(
            padding: EdgeInsets.only(left: isReply ? 32.0 : 40.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showReplyDialog(comment),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    'Reply',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                children: comment.replies
                    .map((reply) => _buildCommentItem(reply, isReply: true))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfileScreen(userId: widget.post.author.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: widget.post.author.profileImageUrl.isNotEmpty
                      ? NetworkImage(widget.post.author.profileImageUrl)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.post.author.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        if (widget.post.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(widget.post.text),
          ),
        if (widget.post.imageUrls.isNotEmpty)
          AspectRatio(
            aspectRatio: 1.0,
            child: PageView.builder(
              itemCount: widget.post.imageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  widget.post.imageUrls[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        if (widget.post.linkedHairstyle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              child: ListTile(
                leading: Image.network(
                  widget.post.linkedHairstyle!.imageUrls.first,
                  width: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(widget.post.linkedHairstyle!.name),
                subtitle: const Text('Linked Hairstyle'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isPosting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Icon(Icons.send),
              onPressed: _postComment,
            ),
          ],
        ),
      ),
    );
  }
}