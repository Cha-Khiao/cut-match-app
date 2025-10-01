import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late TextEditingController _textController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.post.text);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _savePost() async {
    if (_textController.text.trim().isEmpty || _isSaving) return;
    setState(() => _isSaving = true);

    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final success = await feedProvider.updatePost(
      widget.post.id,
      _textController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(feedProvider.errorMessage ?? 'Failed to save post'),
          ),
        );
      }
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePost,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.post.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(widget.post.imageUrls.first, height: 200),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              autofocus: true,
              maxLines: null, // Allow multiline
              decoration: const InputDecoration(
                hintText: 'Edit your caption...',
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}