import 'package:cut_match_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('เกี่ยวกับแอปพลิเคชัน')),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.hasData ? snapshot.data!.version : '...';
          final buildNumber = snapshot.hasData
              ? snapshot.data!.buildNumber
              : '...';

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Center(
                child: Column(
                  children: [
                    Image.asset('assets/images/logo.png', width: 100),
                    const SizedBox(height: 16),
                    Text('Cut Match', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'เวอร์ชัน $version ($buildNumber)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(theme, 'แอปพลิเคชันค้นหาและลองทรงผมด้วย AI'),
              const SizedBox(height: 8),
              Text(
                'Cut Match คือแอปพลิเคชันที่ช่วยให้คุณค้นหาแรงบันดาลใจสำหรับทรงผมใหม่ๆ และสามารถลองทรงผมเหล่านั้นกับใบหน้าของคุณได้ทันทีด้วยเทคโนโลยี Virtual Try-On เพื่อให้คุณตัดสินใจเลือกร้านตัดผมและทรงผมที่ใช่ได้อย่างมั่นใจ',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(theme, 'ฟีเจอร์หลัก'),
              _buildFeatureTile(
                icon: Icons.cut,
                title: 'Hairstyle Gallery',
                subtitle: 'แกลเลอรีทรงผมหลากหลายสไตล์',
              ),
              _buildFeatureTile(
                icon: Icons.face_retouching_natural,
                title: 'Virtual Try-On',
                subtitle: 'ลองทรงผมเสมือนจริงด้วย AI',
              ),
              _buildFeatureTile(
                icon: Icons.dynamic_feed,
                title: 'Social Feed',
                subtitle: 'ชุมชนออนไลน์สำหรับแชร์สไตล์ของคุณ',
              ),
              _buildFeatureTile(
                icon: Icons.map,
                title: 'Salon Finder',
                subtitle: 'ค้นหาร้านตัดผมใกล้ตัวคุณ',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(title, style: theme.textTheme.titleLarge);
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primary, size: 30),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
    );
  }
}
