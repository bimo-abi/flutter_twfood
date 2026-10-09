class Product {
  final int idProduk;
  final String namaProduk;
  final String? deskripsi;
  final String? fotoProduk;
  final bool statusAktif;
  final List<ProductVariant> varian;

  const Product({
    required this.idProduk,
    required this.namaProduk,
    this.deskripsi,
    this.fotoProduk,
    required this.statusAktif,
    required this.varian,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawVarian = json['varian'];

    final List<ProductVariant> varian = [];

    if (rawVarian is List) {
      for (final item in rawVarian) {
        if (item is Map<String, dynamic>) {
          varian.add(
            ProductVariant.fromJson(item),
          );
        }
      }
    }

    return Product(
      idProduk: int.tryParse(
            json['id_produk'].toString(),
          ) ??
          0,
      namaProduk:
          json['nama_produk']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString(),
      fotoProduk: json['foto_produk']?.toString(),
      statusAktif:
          json['status_aktif'] == true,
      varian: varian,
    );
  }
}

class ProductVariant {
  final int idVarian;
  final int idProduk;
  final String namaVarian;
  final int? beratGram;
  final String? satuanJual;
  final int stok;
  final bool tersediaPreOrder;
  final DateTime? tanggalMulaiPreOrder;
  final DateTime? tanggalSelesaiPreOrder;
  final DateTime? estimasiTersedia;
  final bool statusAktif;
  final List<ProductPrice> daftarHarga;

  const ProductVariant({
    required this.idVarian,
    required this.idProduk,
    required this.namaVarian,
    this.beratGram,
    this.satuanJual,
    required this.stok,
    required this.tersediaPreOrder,
    this.tanggalMulaiPreOrder,
    this.tanggalSelesaiPreOrder,
    this.estimasiTersedia,
    required this.statusAktif,
    required this.daftarHarga,
  });

  factory ProductVariant.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawHarga = json['daftar_harga'];

    final List<ProductPrice> daftarHarga = [];

    if (rawHarga is List) {
      for (final item in rawHarga) {
        if (item is Map<String, dynamic>) {
          daftarHarga.add(
            ProductPrice.fromJson(item),
          );
        }
      }
    }

    return ProductVariant(
      idVarian: int.tryParse(
            json['id_varian'].toString(),
          ) ??
          0,
      idProduk: int.tryParse(
            json['id_produk'].toString(),
          ) ??
          0,
      namaVarian:
          json['nama_varian']?.toString() ?? '',
      beratGram: _parseNullableInt(
        json['berat_gram'],
      ),
      satuanJual:
          json['satuan_jual']?.toString(),
      stok: int.tryParse(
            json['stok'].toString(),
          ) ??
          0,
      tersediaPreOrder:
          json['tersedia_pre_order'] == true,
      tanggalMulaiPreOrder:
          _parseDateTime(
        json['tanggal_mulai_pre_order'],
      ),
      tanggalSelesaiPreOrder:
          _parseDateTime(
        json['tanggal_selesai_pre_order'],
      ),
      estimasiTersedia:
          _parseDateTime(
        json['estimasi_tersedia'],
      ),
      statusAktif:
          json['status_aktif'] == true,
      daftarHarga: daftarHarga,
    );
  }

  static int? _parseNullableInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}

class ProductPrice {
  final int idDaftarHarga;
  final int idVarian;
  final String jenisHarga;
  final int harga;
  final int? minimalPembelian;
  final String? satuanMinimal;
  final bool statusAktif;

  const ProductPrice({
    required this.idDaftarHarga,
    required this.idVarian,
    required this.jenisHarga,
    required this.harga,
    this.minimalPembelian,
    this.satuanMinimal,
    required this.statusAktif,
  });

  factory ProductPrice.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProductPrice(
      idDaftarHarga: int.tryParse(
            json['id_daftar_harga'].toString(),
          ) ??
          0,
      idVarian: int.tryParse(
            json['id_varian'].toString(),
          ) ??
          0,
      jenisHarga:
          json['jenis_harga']?.toString() ?? '',
      harga: int.tryParse(
            json['harga'].toString(),
          ) ??
          0,
      minimalPembelian: _parseNullableInt(
        json['minimal_pembelian'],
      ),
      satuanMinimal:
          json['satuan_minimal']?.toString(),
      statusAktif:
          json['status_aktif'] == true,
    );
  }

  static int? _parseNullableInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString());
  }
}