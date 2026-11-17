import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/outlet.dart';
import '../../services/outlet_service.dart';
import '../../theme/app_colors.dart';

class OutletPage extends StatefulWidget {
  const OutletPage({super.key});

  @override
  State<OutletPage> createState() => _OutletPageState();
}

class _OutletPageState extends State<OutletPage> {
  late Future<List<Outlet>> _outletsFuture;

  @override
  void initState() {
    super.initState();

    _outletsFuture = OutletService.getOutlets();
  }

  Future<void> _refreshOutlets() async {
    setState(() {
      _outletsFuture = OutletService.getOutlets();
    });

    await _outletsFuture;
  }

  Future<void> _openGoogleMaps(String link) async {
    final uri = Uri.tryParse(link);

    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link Google Maps tidak valid.')),
      );
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outlet TWFOOD')),
      body: Container(
        color: AppColors.background,
        child: FutureBuilder<List<Outlet>>(
        future: _outletsFuture,
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
                      'Gagal mengambil data outlet.',
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
                      onPressed: _refreshOutlets,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final outlets = snapshot.data ?? [];

          if (outlets.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshOutlets,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Belum ada outlet yang tersedia.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshOutlets,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: outlets.length,
              itemBuilder: (context, index) {
                final outlet = outlets[index];

                return _buildOutletCard(outlet);
              },
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildOutletCard(Outlet outlet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOutletImage(outlet),

            const SizedBox(height: 16),

            Text(
              outlet.namaOutlet,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),

            const SizedBox(height: 16),

            if (outlet.alamat != null && outlet.alamat!.isNotEmpty)
              _buildInfoRow(
                Icons.location_on_outlined,
                'Alamat',
                outlet.alamat!,
              ),

            if (outlet.linkGoogleMaps != null &&
                outlet.linkGoogleMaps!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openGoogleMaps(outlet.linkGoogleMaps!),
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Lihat Lokasi di Google Maps'),
                ),
              ),
            ],

            if (outlet.nomorTelepon != null &&
                outlet.nomorTelepon!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.phone_outlined,
                'Nomor Telepon',
                outlet.nomorTelepon!,
              ),
            ],

            if (outlet.latitude != null && outlet.longitude != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.map_outlined,
                'Koordinat',
                '${outlet.latitude}, ${outlet.longitude}',
              ),
            ],

            if (outlet.deskripsi != null && outlet.deskripsi!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Deskripsi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                outlet.deskripsi!,
                style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textPrimary),
              ),
            ],

            const SizedBox(height: 20),

            const Text(
              'Jam Operasional',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            if (outlet.jamOperasional.isEmpty)
              const Text(
                'Belum ada informasi jam operasional.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...outlet.jamOperasional.map((jam) => _buildOperatingHour(jam)),
          ],
        ),
      ),
    );
  }

  Widget _buildOutletImage(Outlet outlet) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.secondary.withValues(alpha: 0.08),
      ),
      child: outlet.foto != null && outlet.foto!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                outlet.foto!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    size: 60,
                  );
                },
              ),
            )
          : const Icon(Icons.store_outlined, size: 60),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingHour(OutletOperatingHour jam) {
    final String waktu;

    if (jam.tutup) {
      waktu = 'Tutup';
    } else if ((jam.jamBuka == null || jam.jamBuka!.isEmpty) &&
        (jam.jamTutup == null || jam.jamTutup!.isEmpty)) {
      waktu = 'Jam belum tersedia';
    } else {
      final jamBuka = jam.jamBuka?.isNotEmpty == true ? jam.jamBuka! : '-';

      final jamTutup = jam.jamTutup?.isNotEmpty == true ? jam.jamTutup! : '-';

      waktu = '$jamBuka - $jamTutup';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              jam.hari,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            waktu,
            style: TextStyle(
              color: jam.tutup ? Colors.grey : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
