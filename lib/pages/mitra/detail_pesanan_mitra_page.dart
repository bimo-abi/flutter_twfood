import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/mitra_pesanan.dart';
import '../../services/mitra_pesanan_service.dart';
import '../../theme/app_colors.dart';

class DetailPesananMitraPage extends StatefulWidget {
  final int idPesanan;

  const DetailPesananMitraPage({super.key, required this.idPesanan});

  @override
  State<DetailPesananMitraPage> createState() => _DetailPesananMitraPageState();
}

class _DetailPesananMitraPageState extends State<DetailPesananMitraPage> {
  late Future<MitraPesanan> _future;

  @override
  void initState() {
    super.initState();
    _future = MitraPesananService.fetchDetail(widget.idPesanan);
  }

  bool _updatingStatus = false;

  String _rupiah(dynamic value) {
    final amount = int.tryParse(value?.toString() ?? '') ?? 0;
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  String _text(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';
    return value.toString().replaceAll('_', ' ');
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _info(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              _text(value),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeHeader(MitraPesanan order) {
    final isPo = order.isPreOrder;
    final color = isPo ? AppColors.warning : AppColors.secondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isPo ? Icons.factory_outlined : Icons.inventory_2_outlined,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPo ? 'PESANAN PRE-ORDER' : 'PESANAN REGULER',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isPo
                      ? 'Periksa jadwal dan progres produksi sebelum menyiapkan pesanan.'
                      : 'Periksa ketersediaan barang dan siapkan pesanan.',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productSection(MitraPesanan order) {
    final items = order.detailItems;
    return _section('Rincian Produk', [
      if (items.isEmpty)
        const Text('Rincian produk tidak tersedia.')
      else
        ...items.map((item) {
          final name =
              item['nama_produk_saat_pesan'] ?? item['nama_produk'] ?? 'Produk';
          final variant = item['nama_varian_saat_pesan'];
          final quantity = item['jumlah'] ?? 0;
          final unitPrice = item['harga_saat_pesan'];
          final subtotal =
              item['subtotal_setelah_diskon'] ?? item['subtotal'] ?? 0;
          final production = order.produksiUntuk(item);
          final reservations = item['reservasi_stok'];
          final reservationList = reservations is List
              ? reservations.whereType<Map>().toList()
              : <Map>[];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(name),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (variant != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Varian: ${_text(variant)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 5),
                _info('Jumlah', '$quantity'),
                _info('Harga satuan', _rupiah(unitPrice)),
                _info('Subtotal item', _rupiah(subtotal)),
                if (order.isPreOrder) ...[
                  const Divider(),
                  Text(
                    'Informasi Produksi',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _info('Jumlah produksi', production?['jumlah_produksi']),
                  _info('Status produksi', production?['status_produksi']),
                  _info('Estimasi produksi', production?['estimasi_selesai']),
                  _info('Mulai produksi', production?['mulai_produksi_pada']),
                  _info(
                    'Produksi selesai',
                    production?['selesai_produksi_pada'],
                  ),
                  _info('Catatan produksi', production?['catatan_produksi']),
                ],
                if (reservationList.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Reservasi Stok',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  ...reservationList.map(
                    (reservation) => _info(
                      'Reservasi ${reservation['jumlah']}',
                      reservation['status_reservasi'],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
    ]);
  }

  Future<void> _ubahStatus(
    MitraPesanan order,
    String statusBaru,
    String judul,
  ) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(judul),
        content: Text(
          'Apakah kamu yakin ingin memperbarui status '
          'pesanan ${order.nomor}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    setState(() => _updatingStatus = true);

    try {
      await MitraPesananService.updateStatus(
        idPesanan: order.id,
        statusPesanan: statusBaru,
      );

      if (!mounted) return;

      setState(() {
        _future = MitraPesananService.fetchDetail(widget.idPesanan);
        _updatingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status pesanan berhasil diperbarui.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _updatingStatus = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _statusActionSection(MitraPesanan order) {
    final status = order.status;
    final pickup = order.jenisPesanan == 'pickup';
    final lunas = order.pembayaran == 'lunas';

    final kurir = order.getValue('kurir')?.toString();
    final nomorResi = order.getValue('nomor_resi')?.toString() ?? '';
    final tautanTracking =
        order.getValue('tautan_pelacakan')?.toString() ?? '';

    final trackingSiap = kurir == 'gosend'
        ? tautanTracking.trim().isNotEmpty
        : kurir == 'jnt'
            ? nomorResi.trim().isNotEmpty
            : false;

    String? statusBaru;
    String? labelTombol;
    String? keterangan;

    if (status == 'sedang_diproses') {
      statusBaru = pickup ? 'siap_diambil' : 'siap_dikirim';
      labelTombol = pickup ? 'Tandai Siap Diambil' : 'Tandai Siap Dikirim';
      keterangan = order.isPreOrder
          ? 'Pastikan proses produksi Pre-Order sudah selesai dan pesanan siap dipenuhi.'
          : 'Pastikan seluruh produk telah disiapkan sebelum mengubah status.';
    } else if (status == 'siap_diambil') {
      statusBaru = 'diterima';
      labelTombol = 'Konfirmasi Pesanan Diambil';
      keterangan = !lunas
          ? 'Pesanan belum lunas. Pelanggan harus menyelesaikan pembayaran sebelum pesanan diserahkan.'
          : 'Pastikan pesanan benar-benar sudah diserahkan kepada pelanggan.';
    } else if (status == 'siap_dikirim') {
      statusBaru = 'dalam_pengiriman';
      labelTombol = 'Mulai Pengiriman';
      keterangan = !lunas
          ? 'Pesanan belum lunas. Pembayaran harus diselesaikan sebelum pengiriman dimulai.'
          : !trackingSiap
              ? 'Simpan kurir dan informasi tracking terlebih dahulu sebelum memulai pengiriman.'
              : 'Pastikan kurir dan informasi tracking sudah benar sebelum memulai pengiriman.';
    } else if (status == 'dalam_pengiriman') {
      statusBaru = 'diterima';
      labelTombol = 'Konfirmasi Pesanan Diterima';
      keterangan = !lunas
          ? 'Pesanan belum lunas sehingga penerimaan belum dapat dikonfirmasi.'
          : 'Konfirmasi hanya setelah pesanan benar-benar diterima pelanggan.';
    } else if (status == 'diterima') {
      keterangan = 'Pesanan telah selesai diterima.';
    }

    if (statusBaru == null && keterangan == null) {
      return const SizedBox.shrink();
    }

    final tombolAktif = statusBaru != null &&
        (statusBaru != 'diterima' || lunas) &&
        (statusBaru != 'dalam_pengiriman' || (lunas && trackingSiap)) &&
        (statusBaru != 'diterima' || status != 'dalam_pengiriman' || lunas) &&
        !_updatingStatus;

    return _section(
      status == 'diterima' ? 'Status Pesanan' : 'Tindakan Pesanan',
      [
        if (keterangan != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              keterangan,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        if (statusBaru != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: tombolAktif
                  ? () => _ubahStatus(order, statusBaru!, labelTombol!)
                  : null,
              icon: _updatingStatus
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_updatingStatus ? 'Memproses...' : labelTombol!),
            ),
          ),
    ]);
  }

  Future<void> _simpanPengiriman({
    required MitraPesanan order,
    required String kurir,
    required String nomorResi,
    required String tautan,
  }) async {
    try {
      await MitraPesananService.updatePengiriman(
        idPesanan: order.id,
        kurir: kurir,
        nomorResi: kurir == 'jnt' ? nomorResi.trim() : null,
        tautanPelacakan: kurir == 'gosend' ? tautan.trim() : null,
      );

      if (!mounted) return;

      setState(() {
        _future = MitraPesananService.fetchDetail(widget.idPesanan);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informasi pengiriman berhasil disimpan.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _pengirimanSection(MitraPesanan order) {
    final kurirTersimpan = order.getValue('kurir')?.toString();
    final nomorResi = order.getValue('nomor_resi')?.toString() ?? '';
    final tautan = order.getValue('tautan_pelacakan')?.toString() ?? '';

    return _section('Pengiriman dan Tracking', [
      _info('Kurir', kurirTersimpan),
      if (kurirTersimpan == 'jnt') _info('Nomor resi', nomorResi),
      if (kurirTersimpan == 'gosend') _info('Tautan tracking', tautan),
      if (order.status == 'siap_dikirim')
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _dialogPengiriman(order),
            icon: const Icon(Icons.local_shipping_outlined),
            label: Text(
              kurirTersimpan == null
                  ? 'Atur Pengiriman'
                  : 'Ubah Informasi Pengiriman',
            ),
          ),
        ),
      if (order.status == 'dalam_pengiriman')
        const Text(
          'Pesanan sedang dalam pengiriman.',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
    ]);
  }

  Future<void> _dialogPengiriman(MitraPesanan order) async {
    String kurir = order.getValue('kurir')?.toString() ?? 'gosend';

    final resiController = TextEditingController(
      text: order.getValue('nomor_resi')?.toString() ?? '',
    );

    final tautanController = TextEditingController(
      text: order.getValue('tautan_pelacakan')?.toString() ?? '',
    );

    String? errorText;

    final hasil = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Informasi Pengiriman'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: kurir,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Kurir',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'gosend',
                          child: Text('GoSend'),
                        ),
                        DropdownMenuItem(value: 'jnt', child: Text('J&T')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            kurir = value;
                            errorText = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (kurir == 'gosend')
                      TextField(
                        controller: tautanController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Tautan Tracking GoSend',
                          hintText: 'https://...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (kurir == 'jnt')
                      TextField(
                        controller: resiController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Resi J&T',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (kurir == 'gosend') {
                      final uri = Uri.tryParse(tautanController.text.trim());

                      if (uri == null ||
                          !uri.hasScheme ||
                          !['http', 'https'].contains(uri.scheme) ||
                          uri.host.isEmpty) {
                        setDialogState(() {
                          errorText = 'Masukkan tautan tracking yang valid.';
                        });
                        return;
                      }
                    }

                    if (kurir == 'jnt' && resiController.text.trim().isEmpty) {
                      setDialogState(() {
                        errorText = 'Nomor resi J&T wajib diisi.';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, {
                      'kurir': kurir,
                      'resi': resiController.text,
                      'tautan': tautanController.text,
                    });
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    resiController.dispose();
    tautanController.dispose();

    if (hasil == null || !mounted) return;

    await _simpanPengiriman(
      order: order,
      kurir: hasil['kurir']!,
      nomorResi: hasil['resi'] ?? '',
      tautan: hasil['tautan'] ?? '',
    );
  }

  Widget _buildDetail(MitraPesanan order) {
    final pengguna = order.getValue('pengguna');
    final customer = pengguna is Map ? pengguna : <String, dynamic>{};
    final isPo = order.isPreOrder;

    return RefreshIndicator(
      onRefresh: () async {
        final future = MitraPesananService.fetchDetail(widget.idPesanan);
        setState(() => _future = future);
        await future;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _typeHeader(order),
          const SizedBox(height: 12),
          _section('Informasi Pesanan', [
            _info('Nomor pesanan', order.nomor),
            _info('Jenis pemenuhan', isPo ? 'Pre-Order' : 'Reguler'),
            _info('Status pesanan', order.status),
            _info('Status pembayaran', order.pembayaran),
            _info('Jenis pesanan', order.jenisPesanan),
            _info('Saluran pesanan', order.getValue('saluran_pesanan')),
            _info('Tanggal dibuat', order.getValue('created_at')),
            if (isPo)
              _info('Estimasi selesai', order.getValue('estimasi_selesai')),
          ]),
          _section('Informasi Pelanggan', [
            _info('Nama', customer['nama']),
            _info('Email', customer['email']),
            _info(
              'Nomor telepon',
              order.getValue('nomor_telepon_saat_pesan') ??
                  customer['nomor_telepon'],
            ),
          ]),
          _productSection(order),
          _section('Ringkasan Pembayaran', [
            _info(
              'Subtotal produk',
              _rupiah(order.getValue('subtotal_produk')),
            ),
            _info('Diskon', _rupiah(order.getValue('diskon'))),
            _info('Total pesanan', _rupiah(order.getValue('total_pesanan'))),
            _info(
              'Pembayaran DP',
              order.getValue('menggunakan_dp') == true ? 'Ya' : 'Tidak',
            ),
            if (order.getValue('menggunakan_dp') == true) ...[
              _info('Persentase DP', order.getValue('persentase_dp')),
              _info('Nominal DP', _rupiah(order.getValue('nominal_dp'))),
            ],
          ]),
          if (order.isPreOrder)
            _section('Ringkasan Produksi', [
              _info(
                'Tanggal estimasi selesai',
                order.getValue('estimasi_selesai'),
              ),
              _info('Jumlah item Pre-Order', order.detailItems.length),
              _info(
                'Status proses',
                order.detailItems.every(
                      (item) =>
                          order.produksiUntuk(item)?['status_produksi'] ==
                          'selesai',
                    )
                    ? 'Produksi selesai'
                    : 'Menunggu / dalam produksi',
              ),
            ]),
          _section('Informasi Pemenuhan', [
            _info('Metode', order.jenisPesanan),
            _info('Kurir', order.getValue('kurir')),
            _info('Nomor resi', order.getValue('nomor_resi')),
            _info('Tautan pelacakan', order.getValue('tautan_pelacakan')),
            _info('Nama penerima', order.getValue('nama_penerima_saat_pesan')),
            _info(
              'Nomor telepon penerima',
              order.getValue('nomor_telepon_saat_pesan'),
            ),
            _info('Alamat', order.getValue('alamat_lengkap_saat_pesan')),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final parts = [
                    order.getValue('nama_penerima_saat_pesan'),
                    order.getValue('nomor_telepon_saat_pesan'),
                    order.getValue('alamat_lengkap_saat_pesan'),
                    order.getValue('desa_kelurahan_saat_pesan'),
                    order.getValue('kecamatan_saat_pesan'),
                    order.getValue('kabupaten_kota_saat_pesan'),
                    order.getValue('provinsi_saat_pesan'),
                    order.getValue('kode_pos_saat_pesan'),
                  ].where((value) => value != null && value.toString().trim().isNotEmpty);
                  final text = parts.join(', ');
                  if (text.isEmpty) return;
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alamat berhasil disalin.')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Salin alamat lengkap'),
              ),
            ),
            _info('Kecamatan', order.getValue('kecamatan_saat_pesan')),
            _info(
              'Kabupaten/Kota',
              order.getValue('kabupaten_kota_saat_pesan'),
            ),
            _info('Provinsi', order.getValue('provinsi_saat_pesan')),
            _info('Catatan pesanan', order.getValue('catatan')),
          ]),
          _statusActionSection(order),
          if (order.jenisPesanan == 'delivery') ...[
            const SizedBox(height: 12),
            _pengirimanSection(order),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: FutureBuilder<MitraPesanan>(
        future: _future,
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
                    const Icon(Icons.error_outline, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _future = MitraPesananService.fetchDetail(
                            widget.idPesanan,
                          );
                        });
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildDetail(snapshot.data!);
        },
      ),
    );
  }
}
