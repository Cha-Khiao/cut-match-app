import 'dart:io';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<File> _imageFiles = [];
  bool _isPosting = false;

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage(
      imageQuality: 70,
    );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _submitPost() async {
    if (_textController.text.trim().isEmpty && _imageFiles.isEmpty) {
      NotificationHelper.showError(
        context,
        message: 'กรุณาใส่ข้อความหรือเลือกรูปภาพ',
      );
      return;
    }

    setState(() => _isPosting = true);

    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final success = await feedProvider.createPost(
      text: _textController.text.trim(),
      imageFiles: _imageFiles,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        NotificationHelper.showError(
          context,
          message: feedProvider.errorMessage ?? 'ไม่สามารถสร้างโพสต์ได้',
        );
      }
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPost =
        _textController.text.trim().isNotEmpty || _imageFiles.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('สร้างโพสต์ใหม่'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: (_isPosting || !canPost) ? null : _submitPost,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white54,
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('โพสต์'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "คุณกำลังคิดอะไรอยู่...",
                      border: InputBorder.none,
                    ),
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (text) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  if (_imageFiles.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _imageFiles.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_imageFiles[index], fit: BoxFit.cover),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black54,
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined, size: 30),
                  color: AppTheme.primary,
                  onPressed: _pickImages,
                  tooltip: 'เลือกรูปภาพจากอัลบั้ม',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}