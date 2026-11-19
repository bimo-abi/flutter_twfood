class MitraRefund {
  final Map<String, dynamic> data;

  const MitraRefund(this.data);

  factory MitraRefund.fromJson(Map<String, dynamic> json) => MitraRefund(json);

  int get idRefund => int.tryParse(data['id_refund']?.toString() ?? '') ?? 0;
  int get nominalRefund => int.tryParse(data['nominal_refund']?.toString() ?? '') ?? 0;
  String get statusRefund => data['status_refund']?.toString() ?? '-';
  String get jenisRefund => data['jenis_refund']?.toString() ?? '-';
  String get nomorRetur => data['nomor_retur']?.toString() ?? '-';
  String get nomorPesanan => data['nomor_pesanan']?.toString() ?? '-';
  String get namaPelanggan => data['nama_pelanggan']?.toString() ?? '-';

  List<Map<String, dynamic>> get riwayatPercobaan {
    final value = data['riwayat_percobaan'];
    if (value is! List) return [];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'belum_diajukan': return 'Belum diajukan';
      case 'menunggu_diproses': return 'Menunggu diproses';
      case 'diproses': return 'Sedang diproses';
      case 'berhasil': return 'Berhasil';
      case 'gagal': return 'Gagal';
      case 'perlu_diproses_ulang': return 'Perlu diproses ulang';
      default: return status.replaceAll('_', ' ');
    }
  }
}
