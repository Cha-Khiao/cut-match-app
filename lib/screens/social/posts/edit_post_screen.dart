import 'package:cut_match_app/models/post_model.dart';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
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
        Navigator.of(context).pop(true);
      } else {
        NotificationHelper.showError(
          context,
          message: feedProvider.errorMessage ?? 'ไม่สามารถบันทึกโพสต์ได้',
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('แก้ไขโพสต์'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePost,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white54,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('บันทึก'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.post.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.post.imageUrls.first,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              autofocus: true,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'แก้ไขแคปชั่นของคุณ...',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}