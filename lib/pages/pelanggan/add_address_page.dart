import 'package:flutter/material.dart';

import '../../models/region_selection.dart';
import '../../services/address_service.dart';
import '../../theme/app_colors.dart';
import 'location_picker_page.dart';
import '../../widgets/administrative_region_fields.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _namaPenerimaController = TextEditingController();
  final _nomorTeleponController = TextEditingController();
  final _alamatLengkapController = TextEditingController();
  final _kodePosController = TextEditingController();
  double? _latitude;
  double? _longitude;

  RegionSelection? _region;
  bool _alamatUtama = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _labelController.dispose();
    _namaPenerimaController.dispose();
    _nomorTeleponController.dispose();
    _alamatLengkapController.dispose();
    _kodePosController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_region == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih wilayah sampai desa/kelurahan.')),
      );
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      if (_latitude == null || _longitude == null) {
        throw Exception(
          'Tentukan titik lokasi pengiriman melalui peta terlebih dahulu.',
        );
      }

      final address = await AddressService.addAddress(
        label: _labelController.text.trim(),
        namaPenerima: _namaPenerimaController.text.trim(),
        nomorTelepon: _nomorTeleponController.text.trim(),
        alamatLengkap: _alamatLengkapController.text.trim(),
        region: _region!,
        kodePos: _kodePosController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        alamatUtama: _alamatUtama,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alamat "${address.label}" berhasil ditambahkan.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan alamat: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.of(context).push<MapLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (!mounted || result == null) return;
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
    });
  }

  Widget _buildLocationPicker() {
    final hasLocation = _latitude != null && _longitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Lokasi Pengiriman',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          hasLocation
              ? 'Latitude: ${_latitude!.toStringAsFixed(6)}\\nLongitude: ${_longitude!.toStringAsFixed(6)}'
              : 'Titik lokasi wajib ditentukan agar kurir dapat menemukan alamat.',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _isSubmitting ? null : _selectLocation,
          icon: const Icon(Icons.map_outlined),
          label: Text(
            hasLocation ? 'Ubah Titik Lokasi' : 'Pilih Titik Lokasi di Peta',
          ),
        ),
        if (!hasLocation)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'GPS dapat digunakan sebagai titik awal, lalu geser peta untuk menyesuaikan lokasi rumah.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Alamat')),
      body: Container(
        color: AppColors.background,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              color: AppColors.secondary.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, color: AppColors.secondary, size: 26),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Lengkapi alamat pengiriman', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('Pastikan nama penerima, nomor telepon, dan titik lokasi sudah benar.', style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
                    ])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label Alamat',
                hintText: 'Contoh: Rumah, Kantor',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _required(value, 'Label alamat'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _namaPenerimaController,
              decoration: const InputDecoration(
                labelText: 'Nama Penerima',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _required(value, 'Nama penerima'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomorTeleponController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _required(value, 'Nomor telepon'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _alamatLengkapController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Alamat Lengkap',
                hintText: 'Nama jalan, nomor rumah, RT/RW, patokan',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) => _required(value, 'Alamat lengkap'),
            ),
            const SizedBox(height: 20),
            AdministrativeRegionFields(
              onChanged: (selection) {
                setState(() => _region = selection);
                if (selection?.village.postalCode != null &&
                    _kodePosController.text.trim().isEmpty) {
                  _kodePosController.text = selection!.village.postalCode!;
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kodePosController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kode Pos',
                hintText: 'Terisi otomatis jika tersedia; dapat dikoreksi',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _required(value, 'Kode pos'),
            ),
            const SizedBox(height: 20),
            _buildLocationPicker(),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Jadikan alamat utama'),
              subtitle: const Text(
                'Alamat ini akan digunakan sebagai alamat utama.',
              ),
              value: _alamatUtama,
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() => _alamatUtama = value),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan Alamat'),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
