import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/salon_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminSalonFormScreen extends StatefulWidget {
  final Salon? salon;
  const AdminSalonFormScreen({super.key, this.salon});

  @override
  State<AdminSalonFormScreen> createState() => _AdminSalonFormScreenState();
}

class _AdminSalonFormScreenState extends State<AdminSalonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    final isEditing = widget.salon != null;
    _nameController = TextEditingController(
      text: isEditing ? widget.salon!.name : '',
    );
    _addressController = TextEditingController(
      text: isEditing ? widget.salon!.address : '',
    );
    _phoneController = TextEditingController(
      text: isEditing ? widget.salon!.phone : '',
    );
    _latController = TextEditingController(
      text: isEditing ? widget.salon!.location.latitude.toString() : '',
    );
    _lngController = TextEditingController(
      text: isEditing ? widget.salon!.location.longitude.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final token = Provider.of<AuthProvider>(context, listen: false).token!;

      final data = {
        'name': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'latitude': double.tryParse(_latController.text) ?? 0.0,
        'longitude': double.tryParse(_lngController.text) ?? 0.0,
      };

      try {
        if (widget.salon == null) {
          await ApiService.createSalon(data, token);
        } else {
          await ApiService.updateSalon(widget.salon!.id, data, token);
        }
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
        }
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
        title: Text(widget.salon == null ? 'เพิ่มร้านตัดผม' : 'แก้ไขร้านตัดผม'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            CustomTextField(
              controller: _nameController,
              hintText: 'ชื่อร้านตัดผม',
              icon: Icons.storefront_outlined,
              validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อร้าน' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _addressController,
              hintText: 'ที่อยู่',
              icon: Icons.location_on_outlined,
              validator: (v) => v!.isEmpty ? 'กรุณากรอกที่อยู่' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              hintText: 'เบอร์โทรศัพท์ (ไม่บังคับ)',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _latController,
                    hintText: 'ละติจูด',
                    icon: Icons.map_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _lngController,
                    hintText: 'ลองจิจูด',
                    icon: Icons.map_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Text('บันทึกข้อมูลร้านตัดผม'),
            ),
          ],
        ),
      ),
    );
  }
}
