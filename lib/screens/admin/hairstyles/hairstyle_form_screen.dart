import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/hairstyle_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
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

  // --- 1. ประกาศ Controller เพิ่ม ---
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlsController;
  late TextEditingController
  _overlayImageUrlController; // <-- ✨ เพิ่ม Controller นี้
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
    ); // <-- ✨ ตั้งค่า Controller นี้
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

  // --- 2. อย่าลืม dispose Controller ที่สร้างเพิ่ม ---
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlsController.dispose();
    _overlayImageUrlController.dispose(); // <-- ✨ dispose Controller นี้
    _tagsController.dispose();
    _shapesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token!;

      final imageUrls = _imageUrlsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final shapes = _shapesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // --- 3. เพิ่มข้อมูล overlayImageUrl เข้าไปใน data object ---
      final data = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'imageUrls': imageUrls,
        'overlayImageUrl':
            _overlayImageUrlController.text, // <-- ✨ เพิ่ม field นี้
        'gender': _selectedGender,
        'tags': tags,
        'suitableFaceShapes': shapes,
      };

      try {
        if (widget.hairstyle == null) {
          await ApiService.createHairstyle(data, token);
        } else {
          await ApiService.updateHairstyle(widget.hairstyle!.id, data, token);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hairstyle saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.hairstyle == null ? 'Add Hairstyle' : 'Edit Hairstyle',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFormField(_nameController, 'Name'),
              _buildTextFormField(
                _descriptionController,
                'Description',
                maxLines: 3,
              ),
              _buildTextFormField(
                _imageUrlsController,
                'Image URLs (คั่นด้วย ,)',
              ),

              // --- 4. เพิ่มช่องกรอกสำหรับ Overlay Image URL ---
              _buildTextFormField(
                _overlayImageUrlController,
                'Overlay Image URL (.png)',
                isRequired: false, // field นี้ไม่บังคับ
              ),

              _buildTextFormField(
                _tagsController,
                'Tags (คั่นด้วย ,)',
                isRequired: false,
              ),
              _buildTextFormField(
                _shapesController,
                'Suitable Face Shapes (คั่นด้วย ,)',
                isRequired: false,
              ),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Hairstyle'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'This field cannot be empty';
          }
          return null;
        },
      ),
    );
  }
}
