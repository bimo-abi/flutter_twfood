import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/token_storage.dart';
import '../auth/login_page.dart';
import 'address_page.dart';
import 'edit_profile_page.dart';
import '../../services/cart_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<User> _userFuture;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();

    _userFuture = _loadUser();
  }

  String _getStatusVerifikasi(String? status) {
    switch (status) {
      case 'menunggu_verifikasi':
        return 'Menunggu Verifikasi';
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      default:
        return 'Belum Tersedia';
    }
  }

  Future<User> _loadUser() async {
    final response = await AuthService.me();

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil profil. '
        'Status: ${response.statusCode}',
      );
    }

    final responseData = jsonDecode(response.body);

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Format response profil tidak valid.');
    }

    final rawData = responseData['data'];

    if (rawData is! Map<String, dynamic>) {
      throw Exception('Data profil tidak valid.');
    }

    return User.fromJson(rawData);
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _userFuture = _loadUser();
    });

    await _userFuture;
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      final response = await AuthService.logout();

      await TokenStorage.deleteToken();
      CartService.resetSession();

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logout server gagal (${response.statusCode}), '
              'tetapi sesi lokal sudah dihapus.',
            ),
          ),
        );
      }

      return;
    } catch (e) {
      await TokenStorage.deleteToken();
      CartService.resetSession();

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak dapat menghubungi server. '
            'Sesi lokal sudah dihapus.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil Saya')),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal mengambil profil.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _refreshProfile,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = snapshot.data;

          if (user == null) {
            return const Center(child: Text('Data profil tidak ditemukan.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshProfile,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                        child: const Icon(Icons.person_outline, size: 46, color: AppColors.primary),
                      ),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    user.nama,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingMedium,
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ),

                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('Informasi Akun', style: AppTextStyles.headingSmall),
                ),

                _buildProfileField(
                  icon: Icons.check_circle_outline,
                  label: 'Status Akun',
                  value: user.statusAktif == true ? 'Aktif' : 'Tidak Aktif',
                ),

                if ([
                  'toko',
                  'horeca',
                ].contains(user.jenisPelanggan.trim().toLowerCase()))
                  _buildProfileField(
                    icon: Icons.verified_user_outlined,
                    label: 'Status Verifikasi',
                    value: _getStatusVerifikasi(user.statusVerifikasi),
                  ),

                _buildProfileField(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user.email,
                ),

                _buildProfileField(
                  icon: Icons.phone_outlined,
                  label: 'Nomor Telepon',
                  value: user.nomorTelepon,
                ),

                _buildProfileField(
                  icon: Icons.badge_outlined,
                  label: 'Peran',
                  value: user.peran,
                ),

                _buildProfileField(
                  icon: Icons.category_outlined,
                  label: 'Jenis Pelanggan',
                  value: user.jenisPelanggan,
                ),

                const SizedBox(height: 8),

                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    title: const Text(
                      'Edit Profil',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Ubah nama, email, dan nomor telepon'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(user: user),
                        ),
                      );
                      if (updated == true && mounted) {
                        await _refreshProfile();
                      }
                    },
                  ),
                ),

                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: const Icon(Icons.location_on_outlined, color: AppColors.secondary),
                    title: const Text(
                      'Alamat Saya',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Kelola alamat pengiriman Anda'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressPage(),
                        ),
                      );
                      if (mounted) {
                        await _refreshProfile();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: Text(_isLoggingOut ? 'LOGOUT...' : 'LOGOUT'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Icon(icon, color: AppColors.secondary),
        title: Text(
          label,
          style: AppTextStyles.bodySmall,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
