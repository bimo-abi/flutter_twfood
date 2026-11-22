import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';

import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _emailController;
  late final TextEditingController _teleponController;
  bool _isSaving = false;
  XFile? _selectedPhoto;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.user.nama);
    _emailController = TextEditingController(text: widget.user.email);
    _teleponController =
        TextEditingController(text: widget.user.nomorTelepon);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (photo != null && mounted) setState(() => _selectedPhoto = photo);
  }

  String _responseMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
        if (decoded['message'] != null) return decoded['message'].toString();
      }
    } catch (_) {
      // Gunakan pesan umum jika respons server bukan JSON.
    }
    return 'Profil gagal diperbarui. Silakan coba lagi.';
  }

  Future<void> _saveProfile() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final response = await AuthService.updateProfile(
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        nomorTelepon: _teleponController.text.trim(),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        if (_selectedPhoto != null) {
          final photoResponse = await AuthService.uploadProfilePhoto(_selectedPhoto!.path);
          if (photoResponse.statusCode != 200) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_responseMessage(photoResponse.body))),
            );
            return;
          }
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui.')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_responseMessage(response.body))),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghubungi server: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Center(
              child: Column(children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  backgroundImage: _selectedPhoto != null
                      ? FileImage(File(_selectedPhoto!.path))
                      : (widget.user.fotoProfil != null && widget.user.fotoProfil!.isNotEmpty
                          ? NetworkImage(Uri.parse(widget.user.fotoProfil!).hasScheme
                              ? widget.user.fotoProfil!
                              : Uri.parse('${Uri.parse(ApiConfig.baseUrl).origin}${widget.user.fotoProfil}').toString())
                          : null) as ImageProvider?,
                  child: _selectedPhoto == null && (widget.user.fotoProfil == null || widget.user.fotoProfil!.isEmpty)
                      ? const Icon(Icons.person_outline, size: 48, color: AppColors.primary)
                      : null,
                ),
                TextButton.icon(
                  onPressed: _isSaving ? null : _choosePhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Pilih foto profil'),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informasi Pribadi', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 6),
                  Text('Pastikan data kontak kamu selalu aktif agar mudah dihubungi.', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _namaController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama lengkap',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama wajib diisi.';
                }
                if (value.trim().length > 100) return 'Nama maksimal 100 karakter.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Email wajib diisi.';
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                  return 'Format email tidak valid.';
                }
                if (email.length > 150) return 'Email maksimal 150 karakter.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teleponController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Nomor telepon',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (phone.isEmpty) return 'Nomor telepon wajib diisi.';
                if (phone.length > 20) return 'Nomor telepon maksimal 20 karakter.';
                return null;
              },
              onFieldSubmitted: (_) => _saveProfile(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
