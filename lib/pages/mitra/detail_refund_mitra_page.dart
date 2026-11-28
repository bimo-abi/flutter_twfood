import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/mitra_refund.dart';
import '../../services/mitra_refund_service.dart';
import '../../theme/app_colors.dart';

class DetailRefundMitraPage extends StatefulWidget {
  final int idRefund;
  const DetailRefundMitraPage({super.key, required this.idRefund});
  @override
  State<DetailRefundMitraPage> createState() => _DetailRefundMitraPageState();
}

class _DetailRefundMitraPageState extends State<DetailRefundMitraPage> {
  late Future<MitraRefund> _future;
  bool _saving = false;
  @override
  void initState() { super.initState(); _load(); }
  void _load() { _future = MitraRefundService.fetchDetail(widget.idRefund); }
  String _rupiah(dynamic value) { final n = int.tryParse(value?.toString() ?? '') ?? 0; return 'Rp ${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}'; }
  Widget _line(String label, dynamic value) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 138, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))), const Text(': '), Expanded(child: Text(value?.toString().trim().isNotEmpty == true ? value.toString() : '-'))]));
  Widget _section(String title, List<Widget> children) => Card(elevation: 0, color: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 12), ...children])));

  Future<void> _manualDialog(MitraRefund refund) async {
    final reference = TextEditingController();
    final note = TextEditingController();
    String hasil = 'berhasil';
    String metode = 'transfer_bank';
    PlatformFile? proof;
    String? error;
    try {
      final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Catat Refund Manual'),
        content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nominal refund: ${_rupiah(refund.nominalRefund)}'), const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue: hasil, decoration: const InputDecoration(labelText: 'Hasil refund', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'berhasil', child: Text('Berhasil')), DropdownMenuItem(value: 'gagal', child: Text('Gagal'))], onChanged: (v) { if (v != null) setDialogState(() { hasil = v; error = null; }); }),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: metode, decoration: const InputDecoration(labelText: 'Metode refund', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'midtrans_dashboard', child: Text('Midtrans Dashboard')), DropdownMenuItem(value: 'transfer_bank', child: Text('Transfer Bank')), DropdownMenuItem(value: 'lainnya', child: Text('Metode lainnya'))], onChanged: (v) { if (v != null) setDialogState(() => metode = v); }),
          const SizedBox(height: 10),
          if (hasil == 'berhasil') ...[
            TextField(controller: reference, maxLength: 100, decoration: const InputDecoration(labelText: 'Referensi transaksi *', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () async { final selected = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf']); if (selected != null) { final size = selected.lengthSync() ?? await selected.length(); if (size == null || size > 10 * 1024 * 1024) { setDialogState(() => error = 'Ukuran bukti maksimal 10 MB atau ukuran file tidak dapat dibaca.'); } else { setDialogState(() { proof = selected; error = null; }); } } }, icon: const Icon(Icons.attach_file), label: Text(proof?.name ?? 'Pilih bukti refund *')),
            const Text('Format JPG, PNG, atau PDF. Maksimal 10 MB.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ] else
            TextField(controller: note, minLines: 2, maxLines: 4, maxLength: 2000, decoration: const InputDecoration(labelText: 'Catatan kegagalan *', border: OutlineInputBorder())),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: AppColors.error))),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')), ElevatedButton(onPressed: () { if (hasil == 'berhasil' && (reference.text.trim().isEmpty || proof == null)) { setDialogState(() => error = 'Referensi transaksi dan bukti refund wajib diisi.'); return; } if (hasil == 'gagal' && note.text.trim().length < 5) { setDialogState(() => error = 'Catatan kegagalan minimal 5 karakter.'); return; } Navigator.pop(dialogContext, true); }, child: const Text('Simpan Hasil'))],
      )));
      if (confirmed != true || !mounted) return;
      setState(() => _saving = true);
      await MitraRefundService.submitManual(idRefund: refund.idRefund, hasil: hasil, metodeRefund: metode, referensiTransaksi: reference.text, catatan: note.text, bukti: proof);
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hasil refund manual berhasil dicatat.')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    finally { reference.dispose(); note.dispose(); if (mounted) setState(() => _saving = false); }
  }

  Future<void> _automatic(MitraRefund refund) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proses Refund Otomatis'),
        content: Text('Ajukan refund ${_rupiah(refund.nominalRefund)} ke Midtrans? Permintaan yang diterima akan tetap menunggu konfirmasi bank.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ajukan Refund')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final message = await MitraRefundService.submitAutomatic(idRefund: refund.idRefund);
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _download(int id) async {
    try { await MitraRefundService.downloadEvidence(id); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bukti berhasil disimpan.'))); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  Widget _build(MitraRefund refund) {
    final canManual = ['menunggu_diproses', 'gagal', 'perlu_diproses_ulang'].contains(refund.statusRefund);
    final payment = refund.data['pembayaran'];
    final approver = refund.data['penyetuju'];
    return RefreshIndicator(onRefresh: () async { setState(_load); await _future; }, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
      _section('Informasi Refund', [_line('ID refund', refund.idRefund), _line('Nomor retur', refund.nomorRetur), _line('Nomor pesanan', refund.nomorPesanan), _line('Pelanggan', refund.namaPelanggan), _line('Jenis refund', refund.jenisRefund), _line('Nominal', _rupiah(refund.nominalRefund)), _line('Status', MitraRefund.statusLabel(refund.statusRefund)), _line('Alasan', refund.data['alasan']), _line('Penyetuju', approver is Map ? approver['nama'] : null), _line('Disetujui pada', refund.data['disetujui_pada']), _line('Diproses pada', refund.data['diproses_pada']), _line('Selesai pada', refund.data['selesai_pada'])]),
      const SizedBox(height: 12),
      _section('Pembayaran Sumber', [if (payment is Map) ...[_line('ID pembayaran', payment['id_pembayaran']), _line('ID transaksi', payment['id_transaksi']), _line('Metode', payment['metode_pembayaran']), _line('Jumlah pembayaran', _rupiah(payment['jumlah_pembayaran'])), _line('Status pembayaran', payment['status_pembayaran'])] else const Text('Informasi pembayaran tidak tersedia.')]),
      const SizedBox(height: 12),
      _section('Riwayat Percobaan Refund', [if (refund.riwayatPercobaan.isEmpty) const Text('Belum ada percobaan refund.') else ...refund.riwayatPercobaan.map((attempt) { final id = int.tryParse(attempt['id_percobaan_refund']?.toString() ?? '') ?? 0; return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_line('Percobaan #$id', attempt['status_percobaan']), _line('Penyedia', attempt['penyedia_pembayaran']), _line('Metode', attempt['metode_refund']), _line('Nominal', _rupiah(attempt['nominal_refund'])), _line('Referensi', attempt['referensi_gateway']), _line('Catatan', attempt['catatan']), _line('Dicatat oleh', attempt['dicatat_oleh']), _line('Dimulai', attempt['dimulai_pada']), _line('Selesai', attempt['selesai_pada']), if (attempt['bukti_tersedia'] == true) Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => _download(id), icon: const Icon(Icons.download_outlined), label: const Text('Unduh bukti'))), const Divider() ])); })]),
      if (canManual && payment is Map && payment['status_pembayaran'] == 'paid' && payment['id_transaksi'] != null) ...[
        const SizedBox(height: 12),
        _section('Refund Otomatis Midtrans', [
          const Text('Aplikasi akan memeriksa status settlement sebelum mengirim permintaan. Refund baru dinyatakan berhasil setelah Midtrans mengirim konfirmasi bank.'),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: _saving ? null : () => _automatic(refund),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Proses Refund Otomatis'),
          )),
        ]),
      ],
      if (canManual) ...[const SizedBox(height: 12), _section('Pencatatan Refund Manual', [const Text('Catat hasil pengembalian dana yang telah dilakukan melalui Midtrans Dashboard atau transfer manual. Aplikasi tidak menjalankan refund gateway otomatis.'), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _saving ? null : () => _manualDialog(refund), icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.edit_note), label: Text(_saving ? 'Menyimpan...' : 'Catat Hasil Refund')))])],
    ]));
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Detail Refund')), body: FutureBuilder<MitraRefund>(future: _future, builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(snapshot.error.toString(), textAlign: TextAlign.center), const SizedBox(height: 12), ElevatedButton.icon(onPressed: () => setState(_load), icon: const Icon(Icons.refresh), label: const Text('Coba Lagi'))]))); return _build(snapshot.data!); }));
}
