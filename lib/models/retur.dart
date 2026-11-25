class ReturnRequest {
  final int idRetur;
  final int idPesanan;
  final String nomorRetur;
  final String alasanRetur;
  final String statusRetur;
  final String statusPengembalianDana;
  final int nominalPengembalian;
  final DateTime? diajukanPada;
  final DateTime? disetujuiPada;
  final DateTime? barangDiterimaPada;
  final DateTime? diperiksaPada;
  final DateTime? selesaiPada;
  final String? alasanPenolakan;
  final String? catatanMitra;
  final String? metodePengembalian;
  final String? instruksiPengembalian;
  final String? nomorPesanan;
  final List<ReturnRequestItem> items;
  final List<ReturnProof> proofs;
  final List<ReturnRefund> refunds;

  const ReturnRequest({
    required this.idRetur,
    required this.idPesanan,
    required this.nomorRetur,
    required this.alasanRetur,
    required this.statusRetur,
    required this.statusPengembalianDana,
    required this.nominalPengembalian,
    required this.diajukanPada,
    required this.disetujuiPada,
    required this.barangDiterimaPada,
    required this.diperiksaPada,
    required this.selesaiPada,
    required this.alasanPenolakan,
    required this.catatanMitra,
    required this.metodePengembalian,
    required this.instruksiPengembalian,
    required this.nomorPesanan,
    required this.items,
    required this.proofs,
    required this.refunds,
  });

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    final order = json['pesanan'];
    final rawItems = json['detail_retur'];
    final rawProofs = json['bukti_retur'];
    final rawRefunds = json['riwayat_refund'];
    return ReturnRequest(
      idRetur: _toInt(json['id_retur']),
      idPesanan: _toInt(json['id_pesanan'] ?? (order is Map ? order['id_pesanan'] : null)),
      nomorRetur: json['nomor_retur']?.toString() ?? '-',
      alasanRetur: json['alasan_retur']?.toString() ?? '-',
      statusRetur: json['status_retur']?.toString() ?? '-',
      statusPengembalianDana: json['status_pengembalian_dana']?.toString() ?? 'tidak_ada',
      nominalPengembalian: _toInt(json['nominal_pengembalian']),
      diajukanPada: DateTime.tryParse(json['diajukan_pada']?.toString() ?? ''),
      disetujuiPada: DateTime.tryParse(json['disetujui_pada']?.toString() ?? ''),
      barangDiterimaPada: DateTime.tryParse(json['barang_diterima_pada']?.toString() ?? ''),
      diperiksaPada: DateTime.tryParse(json['diperiksa_pada']?.toString() ?? ''),
      selesaiPada: DateTime.tryParse(json['selesai_pada']?.toString() ?? ''),
      alasanPenolakan: json['alasan_penolakan']?.toString(),
      catatanMitra: json['catatan_mitra']?.toString(),
      metodePengembalian: json['metode_pengembalian']?.toString(),
      instruksiPengembalian: json['instruksi_pengembalian']?.toString(),
      nomorPesanan: order is Map ? order['nomor_pesanan']?.toString() : null,
      items: rawItems is List
          ? rawItems.whereType<Map>().map((e) => ReturnRequestItem.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
      proofs: rawProofs is List
          ? rawProofs.whereType<Map>().map((e) => ReturnProof.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
      refunds: rawRefunds is List
          ? rawRefunds.whereType<Map>().map((e) => ReturnRefund.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
    );
  }
}

class ReturnRefund {
  final int idRefund;
  final String jenisRefund;
  final int nominalRefund;
  final String statusRefund;
  final String? alasan;
  final DateTime? disetujuiPada;
  final DateTime? diprosesPada;
  final DateTime? selesaiPada;
  final List<ReturnRefundAttempt> attempts;

  const ReturnRefund({
    required this.idRefund, required this.jenisRefund, required this.nominalRefund,
    required this.statusRefund, required this.alasan, required this.disetujuiPada,
    required this.diprosesPada, required this.selesaiPada, required this.attempts,
  });

  factory ReturnRefund.fromJson(Map<String, dynamic> json) {
    final raw = json['riwayat_percobaan'];
    return ReturnRefund(
      idRefund: _toInt(json['id_refund']),
      jenisRefund: json['jenis_refund']?.toString() ?? '-',
      nominalRefund: _toInt(json['nominal_refund']),
      statusRefund: json['status_refund']?.toString() ?? '-',
      alasan: json['alasan']?.toString(),
      disetujuiPada: DateTime.tryParse(json['disetujui_pada']?.toString() ?? ''),
      diprosesPada: DateTime.tryParse(json['diproses_pada']?.toString() ?? ''),
      selesaiPada: DateTime.tryParse(json['selesai_pada']?.toString() ?? ''),
      attempts: raw is List ? raw.whereType<Map>().map((e) => ReturnRefundAttempt.fromJson(Map<String, dynamic>.from(e))).toList() : const [],
    );
  }
}

class ReturnRefundAttempt {
  final int idPercobaanRefund;
  final int nominalRefund;
  final String statusPercobaan;
  final String? referensiGateway;
  final String? metodeRefund;
  final String? catatan;
  final bool buktiTersedia;
  final DateTime? dimulaiPada;
  final DateTime? selesaiPada;

  const ReturnRefundAttempt({
    required this.idPercobaanRefund, required this.nominalRefund, required this.statusPercobaan,
    required this.referensiGateway, required this.metodeRefund, required this.catatan,
    required this.buktiTersedia, required this.dimulaiPada, required this.selesaiPada,
  });

  factory ReturnRefundAttempt.fromJson(Map<String, dynamic> json) => ReturnRefundAttempt(
    idPercobaanRefund: _toInt(json['id_percobaan_refund']),
    nominalRefund: _toInt(json['nominal_refund']),
    statusPercobaan: json['status_percobaan']?.toString() ?? '-',
    referensiGateway: json['referensi_gateway']?.toString(),
    metodeRefund: json['metode_refund']?.toString(),
    catatan: json['catatan']?.toString(),
    buktiTersedia: json['bukti_tersedia'] == true,
    dimulaiPada: DateTime.tryParse(json['dimulai_pada']?.toString() ?? ''),
    selesaiPada: DateTime.tryParse(json['selesai_pada']?.toString() ?? ''),
  );
}

class ReturnRequestItem {
  final int idDetailPesanan;
  final int jumlahDiminta;
  final int? jumlahDisetujui;
  final int jumlahDiretur;
  final String? alasanItem;
  final String? namaProduk;
  final String? namaVarian;
  final String statusKelayakanStok;

  const ReturnRequestItem({
    required this.idDetailPesanan,
    required this.jumlahDiminta,
    required this.jumlahDisetujui,
    required this.jumlahDiretur,
    required this.alasanItem,
    required this.namaProduk,
    required this.namaVarian,
    required this.statusKelayakanStok,
  });

  factory ReturnRequestItem.fromJson(Map<String, dynamic> json) {
    final detail = json['detail_pesanan'];
    return ReturnRequestItem(
      idDetailPesanan: _toInt(json['id_detail_pesanan']),
      jumlahDiminta: _toInt(json['jumlah_diminta'] ?? json['jumlah_diretur']),
      jumlahDisetujui: json['jumlah_disetujui'] == null ? null : _toInt(json['jumlah_disetujui']),
      jumlahDiretur: _toInt(json['jumlah_diretur']),
      alasanItem: json['alasan_item']?.toString(),
      namaProduk: detail is Map ? detail['nama_produk_saat_pesan']?.toString() : null,
      namaVarian: detail is Map ? detail['nama_varian_saat_pesan']?.toString() : null,
      statusKelayakanStok: json['status_kelayakan_stok']?.toString() ?? 'belum_diperiksa',
    );
  }
}

class ReturnProof {
  final int idBuktiRetur;
  final String jenisMedia;
  final String? urlBukti;

  const ReturnProof({
    required this.idBuktiRetur,
    required this.jenisMedia,
    required this.urlBukti,
  });

  factory ReturnProof.fromJson(Map<String, dynamic> json) => ReturnProof(
        idBuktiRetur: _toInt(json['id_bukti_retur']),
        jenisMedia: json['jenis_media']?.toString() ?? 'foto',
        urlBukti: json['url_bukti']?.toString(),
      );
}

class ReturnRequestPage {
  final List<ReturnRequest> returns;
  final int currentPage;
  final int lastPage;
  final int total;

  const ReturnRequestPage({required this.returns, required this.currentPage, required this.lastPage, required this.total});
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
