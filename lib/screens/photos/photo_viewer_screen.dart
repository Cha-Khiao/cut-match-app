import 'dart:io';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PhotoViewerScreen extends StatelessWidget {
  final String imageUrl;

  const PhotoViewerScreen({super.key, required this.imageUrl});

  Future<void> _shareImage() async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final bytes = response.bodyBytes;

      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/shared_look.png';
      await File(path).writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(path),
      ], text: 'ดูรูปที่ฉันบันทึกไว้จากแอป Cut Match สิ!');
    } catch (e) {
      print("Error sharing saved look: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkText,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'แชร์รูปภาพ',
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareImage,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}