import 'package:flutter/material.dart';

import '../../models/address.dart';
import '../../services/address_service.dart';
import 'add_address_page.dart';
import 'edit_address_page.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  late Future<List<Address>> _addressesFuture;

  @override
  void initState() {
    super.initState();

    _addressesFuture = AddressService.getAddresses();
  }


  // REFRESH ALAMAT
  Future<void> _refreshAddresses() async {
    setState(() {
      _addressesFuture = AddressService.getAddresses();
    });

    await _addressesFuture;
  }


  // TAMBAH ALAMAT
  Future<void> _openAddAddressPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAddressPage(),
      ),
    );

    if (result == true) {
      await _refreshAddresses();
    }
  }

  // EDIT ALAMAT
  Future<void> _openEditAddressPage(
    Address address,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAddressPage(
          address: address,
        ),
      ),
    );

    if (result == true) {
      await _refreshAddresses();
    }
  }

  // HAPUS ALAMAT
  Future<void> _deleteAddress(
    Address address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Alamat'),
          content: Text(
            'Apakah kamu yakin ingin menghapus alamat '
            '"${address.label}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    // Jika pengguna memilih Batal
    if (confirmed != true) {
      return;
    }

    try {
      await AddressService.deleteAddress(
        idAlamat: address.idAlamat,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Alamat berhasil dihapus.',
          ),
        ),
      );

      // Refresh daftar alamat setelah berhasil dihapus
      await _refreshAddresses();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus alamat: $e',
          ),
        ),
      );
    }
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alamat Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Alamat',
            onPressed: _openAddAddressPage,
          ),
        ],
      ),
      body: FutureBuilder<List<Address>>(
        future: _addressesFuture,
        builder: (context, snapshot) {

          // LOADING
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ERROR
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal mengambil daftar alamat.',
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
                      onPressed: _refreshAddresses,
                      child: const Text(
                        'Coba Lagi',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // DATA
          final addresses = snapshot.data ?? [];

          // BELUM ADA ALAMAT
          if (addresses.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshAddresses,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Icon(
                    Icons.location_off_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Belum ada alamat tersimpan.',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Tekan tombol + di kanan atas '
                      'untuk menambahkan alamat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // DAFTAR ALAMAT
          return RefreshIndicator(
            onRefresh: _refreshAddresses,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];

                return _buildAddressCard(address);
              },
            ),
          );
        },
      ),
    );
  }

  // CARD ALAMAT
  Widget _buildAddressCard(
    Address address,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // LABEL + UTAMA
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    address.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (address.alamatUtama)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                      color:
                          Colors.grey.shade200,
                    ),
                    child: const Text(
                      'Utama',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

           //nama penerima
            Text(
              address.namaPenerima,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            //nomor telepon
            Text(
              address.nomorTelepon,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 12),

            //alamat lengkap
            Text(
              address.alamatLengkap,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 8),

            //kota, provinsi, kode pos
            Text(
              '${address.kota}, '
              '${address.provinsi} '
              '${address.kodePos}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            // Koordinat
            if (address.latitude != null &&
                address.longitude != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.map_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${address.latitude}, '
                      '${address.longitude}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // TOMBOL EDIT DAN HAPUS
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [

                //tombol edit
                OutlinedButton.icon(
                  onPressed: () {
                    _openEditAddressPage(
                      address,
                    );
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text(
                    'Edit',
                  ),
                ),

                const SizedBox(width: 8),

                //tombol hapus
                OutlinedButton.icon(
                  onPressed: () {
                    _deleteAddress(
                      address,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                  label: const Text(
                    'Hapus',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}