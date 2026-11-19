import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';
import '../../models/product.dart';
import '../../services/mitra_produk_service.dart';
import '../../theme/app_colors.dart';

class FormProdukMitraPage extends StatefulWidget {
  const FormProdukMitraPage({super.key, this.product});
  final Product? product;

  @override
  State<FormProdukMitraPage> createState() => _FormProdukMitraPageState();
}

class _FormProdukMitraPageState extends State<FormProdukMitraPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  File? _selectedImage;
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.namaProduk ?? '');
    _descriptionController = TextEditingController(text: widget.product?.deskripsi ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null || !mounted) return;
    final file = File(image.path);
    if (await file.length() > 2 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ukuran foto maksimal 2 MB.')));
      return;
    }
    setState(() => _selectedImage = file);
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Nama produk wajib diisi.';
    if (name.length < 3) return 'Nama produk minimal 3 karakter.';
    if (name.length > 150) return 'Nama produk maksimal 150 karakter.';
    if (!RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(name)) {
      return 'Nama produk hanya boleh berisi huruf dan spasi.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await MitraProdukService.saveProduct(
        id: widget.product?.idProduk,
        namaProduk: _nameController.text,
        deskripsi: _descriptionController.text,
        foto: _selectedImage,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Produk berhasil diperbarui.' : 'Produk berhasil ditambahkan.')));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? get _existingImageUrl {
    final path = widget.product?.fotoProduk;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base/storage/${path.replaceFirst(RegExp(r'^/'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    final existingImage = _existingImageUrl;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Ubah Produk' : 'Tambah Produk')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Informasi Produk', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nameController,
            validator: _validateName,
            textCapitalization: TextCapitalization.words,
            maxLength: 150,
            decoration: const InputDecoration(labelText: 'Nama Produk', hintText: 'Contoh: Keripik Pisang', border: OutlineInputBorder(), prefixIcon: Icon(Icons.fastfood_outlined)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            maxLength: 5000,
            decoration: const InputDecoration(labelText: 'Deskripsi', hintText: 'Tuliskan deskripsi produk (opsional)', border: OutlineInputBorder(), alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          Text('Foto Produk', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 190,
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              clipBehavior: Clip.antiAlias,
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity)
                  : existingImage != null
                      ? Image.network(existingImage, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, _, _) => _imagePlaceholder())
                      : _imagePlaceholder(),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Format JPG, JPEG, PNG, atau WEBP. Maksimal 2 MB.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Menyimpan...' : 'Simpan Produk'),
          ),
        ]),
      ),
    );
  }

  Widget _imagePlaceholder() => const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.add_a_photo_outlined, size: 42, color: AppColors.textSecondary),
    SizedBox(height: 8),
    Text('Pilih Foto Produk'),
  ]);
}
