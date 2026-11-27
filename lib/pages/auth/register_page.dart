import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/auth_service.dart';
import '../../models/region_selection.dart';
import '../../widgets/administrative_region_fields.dart';
import '../pelanggan/location_picker_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Data dasar penggunan
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nomorTeleponController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _konfirmasiPasswordController =
      TextEditingController();

  // Data profil bisnis
  final TextEditingController _namaBisnisController = TextEditingController();
  final TextEditingController _namaPicController = TextEditingController();
  final TextEditingController _nomorTeleponBisnisController =
      TextEditingController();
  final TextEditingController _alamatBisnisController = TextEditingController();
  RegionSelection? _businessRegion;
  double? _businessLatitude;
  double? _businessLongitude;
  final TextEditingController _kodePosController = TextEditingController();
  final TextEditingController _nibController = TextEditingController();
  final TextEditingController _npwpController = TextEditingController();

  String _jenisPelanggan = 'umum';

  PlatformFile? _dokumenKtp;
  PlatformFile? _dokumenPendukung;
  PlatformFile? _dokumenNib;
  PlatformFile? _dokumenNpwp;
  bool _sedangMengirim = false;

  Future<void> _pilihDokumen(String jenis) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (!mounted || file == null) return;

    setState(() {
      switch (jenis) {
        case 'ktp':
          _dokumenKtp = file;
          break;
        case 'pendukung':
          _dokumenPendukung = file;
          break;
        case 'nib':
          _dokumenNib = file;
          break;
        case 'npwp':
          _dokumenNpwp = file;
          break;
      }
    });
  }

  Widget _pemilihDokumen(
    String judul,
    String jenis,
    PlatformFile? file, {
    bool wajib = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: OutlinedButton.icon(
        onPressed: _sedangMengirim ? null : () => _pilihDokumen(jenis),
        icon: const Icon(Icons.upload_file_outlined),
        label: Text(
          file == null
              ? '$judul${wajib ? ' (Wajib)' : ' (Opsional)'} - Pilih File'
              : '$judul: ${file.name}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  bool _obscurePassword = true;
  bool _obscureKonfirmasiPassword = true;

  bool get _isBisnis =>
      _jenisPelanggan == 'toko' || _jenisPelanggan == 'horeca';

  @override
  void dispose() {
    // Data dasar
    _namaController.dispose();
    _emailController.dispose();
    _nomorTeleponController.dispose();
    _passwordController.dispose();
    _konfirmasiPasswordController.dispose();

    // Profil bisnis
    _namaBisnisController.dispose();
    _namaPicController.dispose();
    _nomorTeleponBisnisController.dispose();
    _alamatBisnisController.dispose();
    _kodePosController.dispose();
    _nibController.dispose();
    _npwpController.dispose();

    super.dispose();
  }

  String _getApiErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody);

      if (data is Map<String, dynamic>) {
        final errors = data['errors'];

        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
        }

        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
    } catch (_) {
      // Response bukan JSON yang valid.
    }

    return 'Terjadi kesalahan saat registrasi.';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isBisnis &&
        (_dokumenKtp?.path == null || _dokumenPendukung?.path == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('KTP dan dokumen pendukung usaha wajib diunggah.'),
        ),
      );
      return;
    }
    if (_isBisnis &&
        _nibController.text.trim().isNotEmpty &&
        _dokumenNib?.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unggah dokumen NIB karena nomor NIB telah diisi.'),
        ),
      );
      return;
    }
    if (_isBisnis &&
        _npwpController.text.trim().isNotEmpty &&
        _dokumenNpwp?.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unggah dokumen NPWP karena nomor NPWP telah diisi.'),
        ),
      );
      return;
    }

    if (_isBisnis && _businessRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih wilayah usaha sampai desa/kelurahan.'),
        ),
      );
      return;
    }
    if (_isBisnis &&
        (_businessLatitude == null || _businessLongitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tentukan titik lokasi usaha melalui peta.'),
        ),
      );
      return;
    }

    setState(() => _sedangMengirim = true);
    try {
      Map<String, dynamic>? profilBisnis;

      if (_isBisnis) {
        profilBisnis = {
          'nama_bisnis': _namaBisnisController.text.trim(),
          'nama_pic': _namaPicController.text.trim(),
          'nomor_telepon_bisnis': _nomorTeleponBisnisController.text.trim(),
          'alamat_bisnis': _alamatBisnisController.text.trim(),
          'kota': _businessRegion!.regency.name,
          'provinsi': _businessRegion!.province.name,
          'kode_pos': _kodePosController.text.trim(),
          'kode_provinsi': _businessRegion!.province.id,
          'kode_kabupaten_kota': _businessRegion!.regency.id,
          'kode_kecamatan': _businessRegion!.district.id,
          'kode_desa_kelurahan': _businessRegion!.village.id,
          'kabupaten_kota': _businessRegion!.regency.name,
          'kecamatan': _businessRegion!.district.name,
          'desa_kelurahan': _businessRegion!.village.name,
          'latitude': _businessLatitude!.toString(),
          'longitude': _businessLongitude!.toString(),
          'nib': _nibController.text.trim().isEmpty
              ? null
              : _nibController.text.trim(),
          'npwp': _npwpController.text.trim().isEmpty
              ? null
              : _npwpController.text.trim(),
        };
      }

      final response = await AuthService.register(
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        nomorTelepon: _nomorTeleponController.text.trim(),
        kataSandi: _passwordController.text,
        kataSandiConfirmation: _konfirmasiPasswordController.text,
        jenisPelanggan: _jenisPelanggan,
        profilBisnis: profilBisnis,
        dokumen: _isBisnis
            ? {
                'dokumen_ktp': _dokumenKtp!.path!,
                'dokumen_pendukung': _dokumenPendukung!.path!,
                if (_dokumenNib?.path != null)
                  'dokumen_nib': _dokumenNib!.path!,
                if (_dokumenNpwp?.path != null)
                  'dokumen_npwp': _dokumenNpwp!.path!,
              }
            : const {},
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 201) {
        // Kembali ke halaman Login dan kirim tanda bahwa registrasi berhasil.
        // Halaman Login akan menampilkan pesan sukses setelah halaman ini ditutup.
        Navigator.pop(context, true);
        return;
      }

      final errorMessage = _getApiErrorMessage(response.body);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat terhubung ke server: $e')),
      );
    } finally {
      if (mounted) setState(() => _sedangMengirim = false);
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Future<void> _selectBusinessLocation() async {
    final result = await Navigator.of(context).push<MapLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initialLatitude: _businessLatitude,
          initialLongitude: _businessLongitude,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _businessLatitude = result.latitude;
      _businessLongitude = result.longitude;
    });
  }

  Widget _buildBusinessLocationPicker() {
    final selected = _businessLatitude != null && _businessLongitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        const Text(
          'Titik Lokasi Usaha',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          selected
              ? 'Latitude: ${_businessLatitude!.toStringAsFixed(6)}\nLongitude: ${_businessLongitude!.toStringAsFixed(6)}'
              : 'Tentukan titik lokasi usaha pada peta.',
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _sedangMengirim ? null : _selectBusinessLocation,
          icon: const Icon(Icons.map_outlined),
          label: Text(
            selected ? 'Ubah Titik Lokasi' : 'Pilih Lokasi pada Peta',
          ),
        ),
      ],
    );
  }

  Widget _buildProfileBisnisSection() {
    if (!_isBisnis) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),

        Text('Profil Bisnis', style: AppTextStyles.headingSmall),

        const SizedBox(height: 8),

        Text(
          'Lengkapi data bisnis untuk pelanggan Toko/Horeca.',
          style: AppTextStyles.bodySmall,
        ),

        const SizedBox(height: 20),

        // Nama Bisnis
        TextFormField(
          controller: _namaBisnisController,
          decoration: _inputDecoration(
            labelText: 'Nama Bisnis',
            hintText: 'Masukkan nama bisnis',
            icon: Icons.store_outlined,
          ),
          validator: (value) {
            if (!_isBisnis) {
              return null;
            }

            if (value == null || value.trim().isEmpty) {
              return 'Nama bisnis wajib diisi.';
            }

            return null;
          },
        ),

        const SizedBox(height: 16),

        // Nama PIC
        TextFormField(
          controller: _namaPicController,
          decoration: _inputDecoration(
            labelText: 'Nama PIC',
            hintText: 'Masukkan nama PIC',
            icon: Icons.person_outline,
          ),
          validator: (value) {
            if (!_isBisnis) {
              return null;
            }

            if (value == null || value.trim().isEmpty) {
              return 'Nama PIC wajib diisi.';
            }

            return null;
          },
        ),

        const SizedBox(height: 16),

        // Nomor Telepon Bisnis
        TextFormField(
          controller: _nomorTeleponBisnisController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration(
            labelText: 'Nomor Telepon Bisnis',
            hintText: 'Masukkan nomor telepon bisnis',
            icon: Icons.phone_outlined,
          ),
          validator: (value) {
            if (!_isBisnis) {
              return null;
            }

            if (value == null || value.trim().isEmpty) {
              return 'Nomor telepon bisnis wajib diisi.';
            }

            return null;
          },
        ),

        const SizedBox(height: 16),

        // Alamat Bisnis
        TextFormField(
          controller: _alamatBisnisController,
          maxLines: 3,
          decoration: _inputDecoration(
            labelText: 'Alamat Bisnis',
            hintText: 'Masukkan alamat bisnis',
            icon: Icons.location_on_outlined,
          ),
          validator: (value) {
            if (!_isBisnis) {
              return null;
            }

            if (value == null || value.trim().isEmpty) {
              return 'Alamat bisnis wajib diisi.';
            }

            return null;
          },
        ),

        const SizedBox(height: 16),

        // Wilayah administratif menggunakan API wilayah yang sama dengan Alamat Saya.
        AdministrativeRegionFields(
          onChanged: (selection) => setState(() => _businessRegion = selection),
        ),

        _buildBusinessLocationPicker(),

        const SizedBox(height: 16),

        // Kode Pos
        TextFormField(
          controller: _kodePosController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(
            labelText: 'Kode Pos',
            hintText: 'Masukkan kode pos',
            icon: Icons.markunread_mailbox_outlined,
          ),
          validator: (value) {
            if (!_isBisnis) {
              return null;
            }

            if (value == null || value.trim().isEmpty) {
              return 'Kode pos wajib diisi.';
            }

            return null;
          },
        ),

        const SizedBox(height: 16),

        // NIB
        TextFormField(
          controller: _nibController,
          decoration: _inputDecoration(
            labelText: 'NIB (Opsional)',
            hintText: 'Masukkan NIB jika ada',
            icon: Icons.description_outlined,
          ),
        ),

        const SizedBox(height: 16),

        // NPWP
        TextFormField(
          controller: _npwpController,
          decoration: _inputDecoration(
            labelText: 'NPWP (Opsional)',
            hintText: 'Masukkan NPWP jika ada',
            icon: Icons.receipt_long_outlined,
          ),
        ),

        const SizedBox(height: 20),
        Text('Dokumen Verifikasi', style: AppTextStyles.headingSmall),
        const SizedBox(height: 8),
        Text(
          'Format JPG, PNG, atau PDF. Ukuran maksimal 10 MB per file. '
          'KTP dan bukti kegiatan/lokasi usaha wajib disertakan.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 14),
        _pemilihDokumen('KTP', 'ktp', _dokumenKtp, wajib: true),
        _pemilihDokumen(
          'Dokumen Pendukung Usaha',
          'pendukung',
          _dokumenPendukung,
          wajib: true,
        ),
        _pemilihDokumen('Dokumen NIB', 'nib', _dokumenNib),
        _pemilihDokumen('Dokumen NPWP', 'npwp', _dokumenNpwp),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Akun'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bergabung dengan TWFOOD',
                      style: AppTextStyles.headingLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Buat akun pelanggan untuk mulai menikmati produk kami.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: AppColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Informasi Akun',
                              style: AppTextStyles.headingSmall,
                            ),
                            const SizedBox(height: 18),
                            // DATA DASAR
                            TextFormField(
                              controller: _namaController,
                              keyboardType: TextInputType.name,
                              decoration: _inputDecoration(
                                labelText: 'Nama',
                                hintText: 'Masukkan nama lengkap',
                                icon: Icons.person_outline,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nama wajib diisi.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration(
                                labelText: 'Email',
                                hintText: 'Masukkan email',
                                icon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email wajib diisi.';
                                }

                                final emailRegex = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                );

                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Format email tidak valid.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _nomorTeleponController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration(
                                labelText: 'Nomor Telepon',
                                hintText: 'Masukkan nomor telepon',
                                icon: Icons.phone_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nomor telepon wajib diisi.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Masukkan password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password wajib diisi.';
                                }

                                if (value.length < 8) {
                                  return 'Password minimal 8 karakter.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _konfirmasiPasswordController,
                              obscureText: _obscureKonfirmasiPassword,
                              decoration: InputDecoration(
                                labelText: 'Konfirmasi Password',
                                hintText: 'Ulangi password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureKonfirmasiPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureKonfirmasiPassword =
                                          !_obscureKonfirmasiPassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Konfirmasi password wajib diisi.';
                                }

                                if (value != _passwordController.text) {
                                  return 'Konfirmasi password tidak sama.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // JENIS PELANGGAN
                            DropdownButtonFormField<String>(
                              initialValue: _jenisPelanggan,
                              decoration: InputDecoration(
                                labelText: 'Jenis Pelanggan',
                                prefixIcon: const Icon(Icons.category_outlined),
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'umum',
                                  child: Text('Umum'),
                                ),
                                DropdownMenuItem(
                                  value: 'toko',
                                  child: Text('Toko'),
                                ),
                                DropdownMenuItem(
                                  value: 'horeca',
                                  child: Text('Horeca'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _jenisPelanggan = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Jenis pelanggan wajib dipilih.';
                                }

                                return null;
                              },
                            ),

                            // PROFIL BISNIS
                            _buildProfileBisnisSection(),

                            const SizedBox(height: 28),

                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _sedangMengirim ? null : _submitForm,
                                child: const Text(
                                  'DAFTAR',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Dengan mendaftar, data akun akan diproses sesuai ketentuan TWFOOD.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
