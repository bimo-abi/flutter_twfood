class MitraRetur {
  final int idRetur;
  final String nomorRetur;
  final String statusRetur;
  final String alasanRetur;
  final String? catatanMitra;
  final String? statusPengembalianDana;
  final int nominalPengembalian;
  final String? diajukanPada;
  final Map<String, dynamic> pesanan;
  final List<Map<String, dynamic>> detailRetur;
  final List<Map<String, dynamic>> buktiRetur;

  const MitraRetur({
    required this.idRetur,
    required this.nomorRetur,
    required this.statusRetur,
    required this.alasanRetur,
    required this.catatanMitra,
    required this.statusPengembalianDana,
    required this.nominalPengembalian,
    required this.diajukanPada,
    required this.pesanan,
    required this.detailRetur,
    required this.buktiRetur,
  });

  factory MitraRetur.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> asMap(dynamic value) =>
        value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

    List<Map<String, dynamic>> asList(dynamic value) {
      if (value is! List) return [];
      return value.whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)).toList();
    }

    return MitraRetur(
      idRetur: int.tryParse(json['id_retur']?.toString() ?? '') ?? 0,
      nomorRetur: json['nomor_retur']?.toString() ?? '-',
      statusRetur: json['status_retur']?.toString() ?? '-',
      alasanRetur: json['alasan_retur']?.toString() ?? '-',
      catatanMitra: json['catatan_mitra']?.toString(),
      statusPengembalianDana: json['status_pengembalian_dana']?.toString(),
      nominalPengembalian:
          int.tryParse(json['nominal_pengembalian']?.toString() ?? '') ?? 0,
      diajukanPada: json['diajukan_pada']?.toString(),
      pesanan: asMap(json['pesanan']),
      detailRetur: asList(json['detail_retur']),
      buktiRetur: asList(json['bukti_retur']),
    );
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'menunggu_persetujuan': return 'Menunggu Persetujuan';
      case 'disetujui': return 'Disetujui';
      case 'menunggu_pengembalian_barang': return 'Menunggu Barang';
      case 'barang_diterima': return 'Barang Diterima';
      case 'sedang_diperiksa': return 'Sedang Diperiksa';
      case 'selesai': return 'Selesai';
      case 'ditolak': return 'Ditolak';
      case 'dibatalkan': return 'Dibatalkan';
      default: return status.replaceAll('_', ' ');
    }
  }
}
