import 'package:flutter/material.dart';

import '../../models/address.dart';
import '../../services/address_service.dart';
import 'add_address_page.dart';

/// Halaman pemilihan alamat yang mengembalikan alamat terpilih
/// kepada halaman pemanggil melalui Navigator.pop(context, address).
class AddressSelectionPage extends StatefulWidget {
  const AddressSelectionPage({super.key});

  @override
  State<AddressSelectionPage> createState() => _AddressSelectionPageState();
}

class _AddressSelectionPageState extends State<AddressSelectionPage> {
  late Future<List<Address>> _addressesFuture;
  int? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _addressesFuture = _loadAddresses();
  }

  Future<List<Address>> _loadAddresses() async {
    final addresses = await AddressService.getAddresses();
    if (mounted && _selectedAddressId == null && addresses.isNotEmpty) {
      final defaultAddress = addresses.where((address) => address.alamatUtama);
      _selectedAddressId = defaultAddress.isNotEmpty
          ? defaultAddress.first.idAlamat
          : addresses.first.idAlamat;
    }
    return addresses;
  }

  Future<void> _refreshAddresses() async {
    setState(() {
      _addressesFuture = _loadAddresses();
    });
    await _addressesFuture;
  }

  Future<void> _addAddress() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddAddressPage()),
    );

    if (result == true && mounted) {
      setState(() {
        _selectedAddressId = null;
        _addressesFuture = _loadAddresses();
      });
    }
  }

  void _confirmSelection(List<Address> addresses) {
    Address? selected;
    for (final address in addresses) {
      if (address.idAlamat == _selectedAddressId) {
        selected = address;
        break;
      }
    }

    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih alamat pengiriman terlebih dahulu.'),
        ),
      );
      return;
    }

    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Alamat Pengiriman')),
      body: FutureBuilder<List<Address>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Daftar alamat tidak dapat dimuat.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refreshAddresses,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final addresses = snapshot.data ?? [];
          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off_outlined, size: 64),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum ada alamat pengiriman.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tambahkan alamat terlebih dahulu untuk digunakan saat checkout.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _addAddress,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Alamat'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshAddresses,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Pilih alamat yang akan digunakan untuk pengiriman pesanan.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                ...addresses.map(_buildAddressOption),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: addresses.length >= AddressService.maxAddresses
                      ? null
                      : _addAddress,
                  icon: const Icon(Icons.add),
                  label: Text(
                    addresses.length >= AddressService.maxAddresses
                        ? 'Batas 3 alamat tercapai'
                        : 'Tambah alamat baru',
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<List<Address>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          final addresses = snapshot.data;
          if (snapshot.connectionState != ConnectionState.done ||
              snapshot.hasError ||
              addresses == null ||
              addresses.isEmpty) {
            return const SizedBox.shrink();
          }

          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              onPressed: () => _confirmSelection(addresses),
              child: const Text('Gunakan Alamat Ini'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressOption(Address address) {
    final isSelected = _selectedAddressId == address.idAlamat;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RadioGroup<int>(
        groupValue: _selectedAddressId,
        onChanged: (value) => setState(() => _selectedAddressId = value),
        child: RadioListTile<int>(
          value: address.idAlamat,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  address.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (address.alamatUtama)
                const Chip(
                  label: Text('Utama'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${address.namaPenerima} • ${address.nomorTelepon}\n'
              '${address.alamatLengkap}, ${address.kota}, '
              '${address.provinsi} ${address.kodePos}',
            ),
          ),
          isThreeLine: true,
          controlAffinity: ListTileControlAffinity.trailing,
        ),
      ),
    );
  }
}
