import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    FocusScope.of(context).unfocus();
    Provider.of<AuthProvider>(context, listen: false).clearError();

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = await authProvider.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (success && mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/main', (Route<dynamic> route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('สร้างบัญชีผู้ใช้')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/register.png',
                      height: MediaQuery.of(context).size.height * 0.18,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'สร้างบัญชีของคุณ',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'เริ่มต้นค้นหาสไตล์ใหม่ๆ ได้เลย!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightText,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      controller: _usernameController,
                      hintText: 'ชื่อผู้ใช้',
                      icon: Icons.person_outline,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'กรุณากรอกชื่อผู้ใช้'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'อีเมล',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || v.isEmpty || !v.contains('@'))
                          ? 'กรุณากรอกอีเมลที่ถูกต้อง'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'รหัสผ่าน',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: 'ยืนยันรหัสผ่าน',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (v) => v != _passwordController.text
                          ? 'รหัสผ่านไม่ตรงกัน'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    if (auth.errorMessage != null && !auth.isLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          auth.errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _submitForm,
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Text('สร้างบัญชี'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'มีบัญชีอยู่แล้ว?',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text('เข้าสู่ระบบที่นี่'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}