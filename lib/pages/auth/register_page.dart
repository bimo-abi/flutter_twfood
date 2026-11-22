import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
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
  final TextEditingController _kotaController = TextEditingController();
  final TextEditingController _provinsiController = TextEditingController();
  final TextEditingController _kodePosController = TextEditingController();
  final TextEditingController _nibController = TextEditingController();
  final TextEditingController _npwpController = TextEditingController();

  String _jenisPelanggan = 'umum';

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
    _kotaController.dispose();
    _provinsiController.dispose();
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

    try {
      Map<String, dynamic>? profilBisnis;

      if (_isBisnis) {
        profilBisnis = {
          'nama_bisnis': _namaBisnisController.text.trim(),
          'nama_pic': _namaPicController.text.trim(),
          'nomor_telepon_bisnis': _nomorTeleponBisnisController.text.trim(),
          'alamat_bisnis': _alamatBisnisController.text.trim(),
          'kota': _kotaController.text.trim(),
          'provinsi': _provinsiController.text.trim(),
          'kode_pos': _kodePosController.text.trim(),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
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

        Text('Lengkapi data bisnis untuk pelanggan Toko/Horeca.', style: AppTextStyles.bodySmall),

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

        // Kota
        TextFormField(
          controller: _kotaController,
          decoration: _inputDecoration(
            labelText: 'Kota',
            hintText: 'Masukkan kota',
            icon: Icons.location_city_outlined,
          ),
          validator: (value) {
            if (!_isBisnis) {
              return null;
            }

            if (value == null || value.trim().isEmpty) {
              return 'Kota wajib diisi.';
            }

            return null;
          },
        ),

        const SizedBox(height: 16),

        // Provinsi
        TextFormField(
          controller: _provinsiController,
          decoration: _inputDecoration(
            labelText: 'Provinsi',
            hintText: 'Masukkan provinsi',
            icon: Icons.map_outlined,
          ),
          validator: (value) {
            if (!_isBisnis) {
              return null;
            }

            if (value == null || value.trim().isEmpty) {
              return 'Provinsi wajib diisi.';
            }

            return null;
          },
        ),

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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buat Akun'), backgroundColor: AppColors.background, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    width: 64, height: 64, alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 16),
                  Text('Bergabung dengan TWFOOD', style: AppTextStyles.headingLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('Buat akun pelanggan untuk mulai menikmati produk kami.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Card(
                    color: AppColors.surface, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text('Informasi Akun', style: AppTextStyles.headingSmall),
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

                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'umum', child: Text('Umum')),
                    DropdownMenuItem(value: 'toko', child: Text('Toko')),
                    DropdownMenuItem(value: 'horeca', child: Text('Horeca')),
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
                    onPressed: _submitForm,
                    child: const Text(
                      'DAFTAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Dengan mendaftar, data akun akan diproses sesuai ketentuan TWFOOD.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}