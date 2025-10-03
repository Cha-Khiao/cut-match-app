import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/screens/photos/photo_viewer_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // Import สำหรับ BackdropFilter

class SavedLooksScreen extends StatelessWidget {
  const SavedLooksScreen({super.key});

  // ✨ [UI Revamp] สร้าง Widget สำหรับปุ่มลบแบบ Glassmorphism
  Widget _buildDeleteButton(BuildContext context, VoidCallback onPressed) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            iconSize: 16,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // ✨ [i18n] แปลเป็นภาษาไทย
        title: const Text('รูปภาพที่บันทึกไว้'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.savedLooks.isEmpty) {
            // ✨ [UI Revamp & i18n] สร้าง Empty State ที่สวยงามขึ้น
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      size: 80,
                      color: AppTheme.lightText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ยังไม่มีรูปภาพที่บันทึก',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.darkText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'รูปภาพที่คุณบันทึกจากการลองทรงผมเสมือนจริงจะแสดงที่นี่',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: authProvider.savedLooks.length,
            itemBuilder: (context, index) {
              final imageUrl = authProvider.savedLooks[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PhotoViewerScreen(imageUrl: imageUrl),
                    ),
                  );
                },
                child: ClipRRect(
                  // ✨ เพิ่ม ClipRRect เพื่อให้ขอบมน
                  borderRadius: BorderRadius.circular(12.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(imageUrl, fit: BoxFit.cover),
                      Positioned(
                        top: 6,
                        right: 6,
                        // ✨ [UI Revamp] ใช้ปุ่มลบดีไซน์ใหม่
                        child: _buildDeleteButton(context, () {
                          // ✨ เพิ่ม Dialog ยืนยันการลบเพื่อ UX ที่ดีขึ้น
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('ยืนยันการลบ'),
                              content: const Text(
                                'คุณต้องการลบรูปภาพนี้ใช่หรือไม่?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('ยกเลิก'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    authProvider.deleteLook(imageUrl);
                                    Navigator.of(ctx).pop();
                                  },
                                  child: Text(
                                    'ลบ',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}