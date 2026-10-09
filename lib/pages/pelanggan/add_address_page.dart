import 'package:flutter/material.dart';

import '../../services/address_service.dart';

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

  final _kotaController = TextEditingController();

  final _provinsiController = TextEditingController();

  final _kodePosController = TextEditingController();

  final _latitudeController = TextEditingController();

  final _longitudeController = TextEditingController();

  bool _alamatUtama = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _labelController.dispose();
    _namaPenerimaController.dispose();
    _nomorTeleponController.dispose();
    _alamatLengkapController.dispose();
    _kotaController.dispose();
    _provinsiController.dispose();
    _kodePosController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();

    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final latitudeText = _latitudeController.text.trim();

      final longitudeText = _longitudeController.text.trim();

      final double? latitude = latitudeText.isEmpty
          ? null
          : double.tryParse(latitudeText);

      final double? longitude = longitudeText.isEmpty
          ? null
          : double.tryParse(longitudeText);

      if (latitudeText.isNotEmpty && latitude == null) {
        throw Exception('Latitude harus berupa angka yang valid.');
      }

      if (longitudeText.isNotEmpty && longitude == null) {
        throw Exception('Longitude harus berupa angka yang valid.');
      }

      final address = await AddressService.addAddress(
        label: _labelController.text.trim(),
        namaPenerima: _namaPenerimaController.text.trim(),
        nomorTelepon: _nomorTeleponController.text.trim(),
        alamatLengkap: _alamatLengkapController.text.trim(),
        kota: _kotaController.text.trim(),
        provinsi: _provinsiController.text.trim(),
        kodePos: _kodePosController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        alamatUtama: _alamatUtama,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alamat "${address.label}" berhasil ditambahkan.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menambahkan alamat: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Alamat')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label Alamat',
                hintText: 'Contoh: Rumah, Kantor',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Label alamat wajib diisi';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _namaPenerimaController,
              decoration: const InputDecoration(
                labelText: 'Nama Penerima',
                hintText: 'Masukkan nama penerima',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama penerima wajib diisi';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _nomorTeleponController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                hintText: 'Masukkan nomor telepon',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor telepon wajib diisi';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _alamatLengkapController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Alamat Lengkap',
                hintText: 'Masukkan alamat lengkap',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alamat lengkap wajib diisi';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _kotaController,
              decoration: const InputDecoration(
                labelText: 'Kota',
                hintText: 'Contoh: Jember',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kota wajib diisi';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _provinsiController,
              decoration: const InputDecoration(
                labelText: 'Provinsi',
                hintText: 'Contoh: Jawa Timur',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Provinsi wajib diisi';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _kodePosController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kode Pos',
                hintText: 'Contoh: 68100',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kode pos wajib diisi';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'Koordinat (opsional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            TextFormField(
              controller: _latitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'Contoh: -8.17234567',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _longitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'Contoh: 113.70012345',
                border: OutlineInputBorder(),
              ),
            ),

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
                  : (value) {
                      setState(() {
                        _alamatUtama = value;
                      });
                    },
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
    );
  }
}
