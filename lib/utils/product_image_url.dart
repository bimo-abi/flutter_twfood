import '../config/api_config.dart';

/// Menormalkan nilai foto_produk dari Laravel menjadi URL endpoint media.
/// Mendukung path relatif products/..., storage/products/..., dan URL lama
/// yang mengarah ke /storage/products/....
class ProductImageUrl {
  static String resolve(String? imagePath) {
    final path = imagePath?.trim() ?? '';
    if (path.isEmpty) return '';

    final uri = Uri.tryParse(path);
    String? filename;

    if (uri != null && uri.hasScheme) {
      final segments = uri.pathSegments;
      final productsIndex = segments.lastIndexOf('products');

      // URL eksternal/non-foto produk tidak diubah.
      if (productsIndex == -1 || productsIndex + 1 >= segments.length) {
        return path;
      }
      filename = segments.last;
    } else {
      final segments = path
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .toList();
      final productsIndex = segments.lastIndexOf('products');

      if (productsIndex == -1 || productsIndex + 1 >= segments.length) {
        // Path relatif lama yang hanya berisi nama file tetap didukung.
        if (segments.length == 1) {
          filename = segments.single;
        } else {
          return '';
        }
      } else {
        filename = segments[productsIndex + 1];
      }
    }

    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*\.(png|jpe?g|webp)$',
            caseSensitive: false)
        .hasMatch(filename)) {
      return '';
    }

    // baseUrl API biasanya berakhir dengan /api. Hapus segmen tersebut
    // agar URL gambar diarahkan ke /storage/products/{filename}, bukan API.
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final baseSegments = baseUri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (baseSegments.isNotEmpty &&
        baseSegments.last.toLowerCase() == 'api') {
      baseSegments.removeLast();
    }

    final imageUri = baseUri.replace(
      pathSegments: [
        ...baseSegments,
        'storage',
        'products',
        filename,
      ],
      query: null,
      fragment: null,
    );

    return imageUri.toString();
  }
}
