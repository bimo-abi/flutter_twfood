import 'dart:convert';

import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/token_storage.dart';
import '../../services/cart_service.dart';
import '../../theme/app_colors.dart';
import '../auth/login_page.dart';
import 'address_page.dart';
import 'edit_profile_page.dart';

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

  Future<User> _loadUser() async {
    final response = await AuthService.me();
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil profil (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['data'] is! Map<String, dynamic>) {
      throw Exception('Format data profil dari server tidak valid.');
    }
    return User.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  Future<void> _refreshProfile() async {
    final future = _loadUser();
    setState(() {
      _userFuture = future;
    });
    await future;
  }

  String? _photoUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final uri = Uri.tryParse(path);
    if (uri == null) return null;
    if (uri.hasScheme) return path;
    final apiUri = Uri.parse(ApiConfig.baseUrl);
    return apiUri.resolve(path.startsWith('/') ? path : '/$path').toString();
  }

  String _verificationLabel(String? status) => switch (status) {
    'menunggu_verifikasi' => 'Menunggu verifikasi',
    'disetujui' => 'Disetujui',
    'ditolak' => 'Ditolak',
    _ => 'Belum tersedia',
  };

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    String? notice;
    try {
      final response = await AuthService.logout();
      if (response.statusCode != 200) {
        notice = 'Sesi lokal dihapus, tetapi server merespons ${response.statusCode}.';
      }
    } catch (_) {
      notice = 'Server tidak dapat dihubungi. Sesi lokal tetap dihapus.';
    }
    await TokenStorage.deleteToken();
    CartService.resetSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
    if (notice != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notice)));
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
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_outlined, size: 44),
                  const SizedBox(height: 12),
                  const Text('Profil belum dapat dimuat.', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: _refreshProfile, child: const Text('Coba lagi')),
                ]),
              ),
            );
          }
          final user = snapshot.data;
          if (user == null) return const Center(child: Text('Data profil tidak ditemukan.'));

          final photoUrl = _photoUrl(user.fotoProfil);
          return RefreshIndicator(
            onRefresh: _refreshProfile,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                      backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
                      child: photoUrl == null
                          ? const Icon(Icons.person_outline, size: 48, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(user.nama, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(user.email, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditProfilePage(user: user)));
                        if (updated == true && mounted) await _refreshProfile();
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit profil'),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(left: 2, bottom: 10),
                  child: Text('Informasi akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                _infoTile(Icons.phone_outlined, 'Nomor telepon', user.nomorTelepon),
                _infoTile(Icons.verified_user_outlined, 'Status akun', user.statusAktif == true ? 'Aktif' : 'Tidak aktif'),
                if (['toko', 'horeca'].contains(user.jenisPelanggan.toLowerCase()))
                  _infoTile(Icons.fact_check_outlined, 'Status verifikasi', _verificationLabel(user.statusVerifikasi)),
                _infoTile(Icons.category_outlined, 'Jenis pelanggan', user.jenisPelanggan),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: AppColors.secondary),
                    title: const Text('Alamat saya', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Kelola alamat pengiriman'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressPage()));
                    },
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _isLoggingOut ? null : _logout,
                  icon: _isLoggingOut
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.logout),
                  label: Text(_isLoggingOut ? 'Keluar...' : 'Keluar dari akun'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13), side: const BorderSide(color: AppColors.border)),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: AppColors.secondary),
        title: Text(title, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        subtitle: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
