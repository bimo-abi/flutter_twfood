import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/token_storage.dart';
import '../auth/login_page.dart';
import 'address_page.dart';
import '../../services/cart_service.dart';

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
              padding: const EdgeInsets.all(20),
              children: [
                const CircleAvatar(
                  radius: 45,
                  child: Icon(Icons.person_outline, size: 50),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    user.nama,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 28),

                _buildProfileField(
                  icon: Icons.person_outline,
                  label: 'Nama',
                  value: user.nama,
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

                _buildProfileField(
                  icon: Icons.check_circle_outline,
                  label: 'Status Akun',
                  value: user.statusAktif == true ? 'Aktif' : 'Tidak Aktif',
                ),

                const SizedBox(height: 8),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text(
                      'Alamat Saya',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Kelola alamat pengiriman Anda'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressPage(),
                        ),
                      );
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
