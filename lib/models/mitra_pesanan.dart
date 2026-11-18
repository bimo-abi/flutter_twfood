class MitraPesanan {
  final Map<String, dynamic> data;

  MitraPesanan(this.data);

  factory MitraPesanan.fromJson(Map<String, dynamic> json) {
    return MitraPesanan(Map<String, dynamic>.from(json));
  }

  dynamic getValue(String key) => data[key];

  int get id {
    final value = data['id_pesanan'];
    return value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get nomor => data['nomor_pesanan']?.toString() ?? 'Pesanan #$id';
  String get status => data['status_pesanan']?.toString() ?? '-';
  String get pembayaran => data['status_pembayaran']?.toString() ?? '-';
  String get jenisPesanan => data['jenis_pesanan']?.toString() ?? '-';

  // Kolom database: pesanan.jenis_pemenuhan = reguler / pre_order.
  String get jenisPemenuhan =>
      data['jenis_pemenuhan']?.toString() == 'pre_order'
          ? 'pre_order'
          : 'reguler';

  bool get isPreOrder => jenisPemenuhan == 'pre_order';

  String get namaPelanggan {
    final pengguna = data['pengguna'];
    if (pengguna is Map) {
      return pengguna['nama']?.toString() ?? 'Pelanggan';
    }
    return 'Pelanggan';
  }

  List<Map<String, dynamic>> get detailItems {
    final raw = data['detail_pesanan'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> get reservasiStok {
    final raw = data['reservasi_stok'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic>? produksiUntuk(
    Map<String, dynamic> detail,
  ) {
    final raw = detail['produksi_pre_order'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }
}
