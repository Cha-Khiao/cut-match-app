import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:cut_match_app/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HairstyleFormScreen extends StatefulWidget {
  final Hairstyle? hairstyle;
  const HairstyleFormScreen({super.key, this.hairstyle});

  @override
  State<HairstyleFormScreen> createState() => _HairstyleFormScreenState();
}

class _HairstyleFormScreenState extends State<HairstyleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlsController;
  late TextEditingController _overlayImageUrlController;
  late TextEditingController _tagsController;
  late TextEditingController _shapesController;
  String _selectedGender = 'ชาย';

  @override
  void initState() {
    super.initState();
    final isEditing = widget.hairstyle != null;
    _nameController = TextEditingController(
      text: isEditing ? widget.hairstyle!.name : '',
    );
    _descriptionController = TextEditingController(
      text: isEditing ? widget.hairstyle!.description : '',
    );
    _imageUrlsController = TextEditingController(
      text: isEditing ? widget.hairstyle!.imageUrls.join(', ') : '',
    );
    _overlayImageUrlController = TextEditingController(
      text: isEditing ? widget.hairstyle!.overlayImageUrl : '',
    );
    _tagsController = TextEditingController(
      text: isEditing ? widget.hairstyle!.tags.join(', ') : '',
    );
    _shapesController = TextEditingController(
      text: isEditing ? widget.hairstyle!.suitableFaceShapes.join(', ') : '',
    );
    if (isEditing) {
      _selectedGender = widget.hairstyle!.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlsController.dispose();
    _overlayImageUrlController.dispose();
    _tagsController.dispose();
    _shapesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final token = Provider.of<AuthProvider>(context, listen: false).token!;

      final data = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'imageUrls': _imageUrlsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'overlayImageUrl': _overlayImageUrlController.text,
        'gender': _selectedGender,
        'tags': _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'suitableFaceShapes': _shapesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      };

      try {
        if (widget.hairstyle == null) {
          await ApiService.createHairstyle(data, token);
        } else {
          await ApiService.updateHairstyle(widget.hairstyle!.id, data, token);
        }

        if (!mounted) return;
        NotificationHelper.showSuccess(
          context,
          message: 'บันทึกข้อมูลทรงผมสำเร็จ!',
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        NotificationHelper.showError(context, message: 'เกิดข้อผิดพลาด: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.hairstyle == null ? 'เพิ่มทรงผมใหม่' : 'แก้ไขทรงผม'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _nameController,
                hintText: 'ชื่อทรงผม',
                icon: Icons.title,
                validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อทรงผม' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'คำอธิบาย'),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => v!.isEmpty ? 'กรุณากรอกคำอธิบาย' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _imageUrlsController,
                hintText: 'ลิงก์รูปภาพ (คั่นด้วย ,)',
                icon: Icons.image_outlined,
                validator: (v) =>
                    v!.isEmpty ? 'กรุณาใส่ลิงก์รูปภาพอย่างน้อย 1 รูป' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _overlayImageUrlController,
                hintText: 'ลิงก์ Overlay Image (.png)',
                icon: Icons.face_retouching_natural,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _tagsController,
                hintText: 'แท็ก (คั่นด้วย ,)',
                icon: Icons.tag,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _shapesController,
                hintText: 'รูปหน้าที่เหมาะสม (คั่นด้วย ,)',
                icon: Icons.face_retouching_natural,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'เพศ',
                  prefixIcon: Icon(Icons.wc, color: AppTheme.lightText),
                ),
                items: ['ชาย', 'หญิง', 'Unisex'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedGender = newValue!);
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('บันทึกทรงผม'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
