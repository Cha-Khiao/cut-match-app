import 'dart:io';
import 'package:cut_match_app/providers/feed_provider.dart';
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
  List<File> _imageFiles = []; // <-- ✨ แก้ไข
  bool _isPosting = false;

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    // --- ✨ ใช้ pickMultiImage ✨ ---
    final List<XFile> pickedFiles = await picker.pickMultiImage(
      imageQuality: 70,
    );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _submitPost() async {
    if (_textController.text.isEmpty && _imageFiles.isEmpty) return;

    setState(() => _isPosting = true);

    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final success = await feedProvider.createPost(
      text: _textController.text,
      imageFiles: _imageFiles, // <-- ✨ ส่งเป็น List
    );

    if (mounted) {
      if (success) {
        Navigator.of(
          context,
        ).pop(true); // ส่ง true กลับไปเพื่อบอกให้ฟีด refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              feedProvider.errorMessage ?? 'Failed to create post.',
            ),
          ),
        );
      }
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _submitPost,
            child: _isPosting
                ? const CircularProgressIndicator()
                : const Text('Post'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            // --- ✨ UI สำหรับแสดงผลหลายรูป ✨ ---
            if (_imageFiles.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          Image.file(
                            _imageFiles[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _imageFiles.removeAt(index));
                              },
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
              ),
            const Spacer(),
            const Divider(),
            // --- ✨ เปลี่ยนปุ่มให้เลือกจากแกลเลอรีอย่างเดียว ✨ ---
            IconButton(
              icon: const Icon(Icons.photo_library, size: 30),
              onPressed: _pickImages,
              tooltip: 'Choose from Gallery',
            ),
          ],
        ),
      ),
    );
  }
}