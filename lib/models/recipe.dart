import 'product.dart';

class Recipe {
  final int idResep;
  final String judul;
  final String? deskripsi;
  final String? foto;
  final String? bahan;
  final String? langkahPembuatan;
  final String? waktuMemasak;
  final List<RecipeProduct> produk;

  const Recipe({
    required this.idResep,
    required this.judul,
    this.deskripsi,
    this.foto,
    this.bahan,
    this.langkahPembuatan,
    this.waktuMemasak,
    required this.produk,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final rawProduk = json['produk'];

    final List<RecipeProduct> produk = [];

    if (rawProduk is List) {
      for (final item in rawProduk) {
        if (item is Map<String, dynamic>) {
          produk.add(
            RecipeProduct.fromJson(item),
          );
        }
      }
    }

    return Recipe(
      idResep: int.tryParse(
            json['id_resep'].toString(),
          ) ??
          0,
      judul:
          json['judul']?.toString() ?? '',
      deskripsi:
          json['deskripsi']?.toString(),
      foto:
          json['foto']?.toString(),
      bahan:
          json['bahan']?.toString(),
      langkahPembuatan:
          json['langkah_pembuatan']?.toString(),
      waktuMemasak:
          json['waktu_memasak']?.toString(),
      produk: produk,
    );
  }
}

class RecipeProduct {
  final int idResepProduk;
  final int idResep;
  final int idProduk;
  final String jumlah;
  final Product? produk;

  const RecipeProduct({
    required this.idResepProduk,
    required this.idResep,
    required this.idProduk,
    required this.jumlah,
    this.produk,
  });

  factory RecipeProduct.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawProduk = json['produk'];

    Product? produk;

    if (rawProduk is Map<String, dynamic>) {
      produk = Product.fromJson(rawProduk);
    }

    return RecipeProduct(
      idResepProduk: int.tryParse(
            json['id_resep_produk'].toString(),
          ) ??
          0,
      idResep: int.tryParse(
            json['id_resep'].toString(),
          ) ??
          0,
      idProduk: int.tryParse(
            json['id_produk'].toString(),
          ) ??
          0,
      jumlah:
          json['jumlah']?.toString() ?? '',
      produk: produk,
    );
  }
}