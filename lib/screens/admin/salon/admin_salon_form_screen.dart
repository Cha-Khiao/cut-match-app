import 'package:cut_match_app/api/api_service.dart';
import 'package:cut_match_app/models/salon_model.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AdminSalonFormScreen extends StatefulWidget {
  // --- ✨ แก้ไขส่วนนี้: รับ salon object เข้ามา ✨ ---
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
    _phoneController = TextEditingController(text: ''); // Phone is optional
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
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.salon == null ? 'Add Salon' : 'Edit Salon'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Salon Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone (Optional)'),
            ),
            TextFormField(
              controller: _latController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _lngController,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save Salon'),
            ),
          ],
        ),
      ),
    );
  }
}
