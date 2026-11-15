class OrderItem {
  final int idDetailPesanan;
  final String namaProduk;
  final String namaVarian;
  final int harga;
  final int jumlah;
  final int subtotal;
  final int subtotalSetelahDiskon;

  const OrderItem({
    required this.idDetailPesanan,
    required this.namaProduk,
    required this.namaVarian,
    required this.harga,
    required this.jumlah,
    required this.subtotal,
    required this.subtotalSetelahDiskon,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    idDetailPesanan: _asInt(json['id_detail_pesanan']),
    namaProduk: json['nama_produk_saat_pesan']?.toString() ?? 'Produk',
    namaVarian: json['nama_varian_saat_pesan']?.toString() ?? '-',
    harga: _asInt(json['harga_saat_pesan']),
    jumlah: _asInt(json['jumlah']),
    subtotal: _asInt(json['subtotal']),
    subtotalSetelahDiskon: _asInt(
      json['subtotal_setelah_diskon'] ?? json['subtotal'],
    ),
  );
}

class OrderPayment {
  final String jenisPembayaran;
  final String penyediaPembayaran;
  final int jumlahPembayaran;
  final String statusPembayaran;
  final String? metodePembayaran;
  final DateTime? dibayarPada;

  const OrderPayment({
    required this.jenisPembayaran,
    required this.penyediaPembayaran,
    required this.jumlahPembayaran,
    required this.statusPembayaran,
    this.metodePembayaran,
    this.dibayarPada,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) => OrderPayment(
    jenisPembayaran: json['jenis_pembayaran']?.toString() ?? '-',
    penyediaPembayaran: json['penyedia_pembayaran']?.toString() ?? '-',
    jumlahPembayaran: _asInt(json['jumlah_pembayaran']),
    statusPembayaran: json['status_pembayaran']?.toString() ?? '-',
    metodePembayaran: json['metode_pembayaran']?.toString(),
    dibayarPada: DateTime.tryParse(json['dibayar_pada']?.toString() ?? ''),
  );
}

class CustomerOrder {
  final int idPesanan;
  final String nomorPesanan;
  final String jenisPesanan;
  final String jenisPemenuhan;
  final int subtotalProduk;
  final int diskon;
  final int totalPesanan;
  final String statusPembayaran;
  final String statusPesanan;
  final DateTime? createdAt;
  final DateTime? diterimaPada;
  final DateTime? estimasiSelesai;
  final String? kurir;
  final String? nomorResi;
  final String? tautanPelacakan;
  final String? catatan;
  final bool menggunakanDp;
  final int? nominalDp;
  final String? alasanPembatalan;
  final List<OrderItem> items;
  final List<OrderPayment> payments;

  const CustomerOrder({
    required this.idPesanan,
    required this.nomorPesanan,
    required this.jenisPesanan,
    required this.jenisPemenuhan,
    required this.subtotalProduk,
    required this.diskon,
    required this.totalPesanan,
    required this.statusPembayaran,
    required this.statusPesanan,
    required this.createdAt,
    required this.diterimaPada,
    required this.estimasiSelesai,
    required this.kurir,
    required this.nomorResi,
    required this.tautanPelacakan,
    required this.catatan,
    required this.menggunakanDp,
    required this.nominalDp,
    required this.alasanPembatalan,
    required this.items,
    required this.payments,
  });

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['detail_pesanan'];
    final rawPayments = json['pembayaran'];
    return CustomerOrder(
      idPesanan: _asInt(json['id_pesanan']),
      nomorPesanan: json['nomor_pesanan']?.toString() ?? '-',
      jenisPesanan: json['jenis_pesanan']?.toString() ?? '-',
      jenisPemenuhan: json['jenis_pemenuhan']?.toString() ?? 'reguler',
      subtotalProduk: _asInt(json['subtotal_produk']),
      diskon: _asInt(json['diskon']),
      totalPesanan: _asInt(json['total_pesanan']),
      // Status ini adalah status agregat pesanan, bukan status transaksi Midtrans.
      statusPembayaran: json['status_pembayaran']?.toString() ?? '-',
      statusPesanan: json['status_pesanan']?.toString() ?? '-',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      diterimaPada: DateTime.tryParse(json['diterima_pada']?.toString() ?? ''),
      estimasiSelesai: DateTime.tryParse(
        json['estimasi_selesai']?.toString() ?? '',
      ),
      kurir: json['kurir']?.toString(),
      nomorResi: json['nomor_resi']?.toString(),
      tautanPelacakan: json['tautan_pelacakan']?.toString(),
      catatan: json['catatan']?.toString(),
      menggunakanDp:
          json['menggunakan_dp'] == true ||
          json['menggunakan_dp']?.toString() == '1',
      nominalDp: json['nominal_dp'] == null ? null : _asInt(json['nominal_dp']),
      alasanPembatalan: json['alasan_pembatalan']?.toString(),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      payments: rawPayments is List
          ? rawPayments
                .whereType<Map>()
                .map((e) => OrderPayment.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
