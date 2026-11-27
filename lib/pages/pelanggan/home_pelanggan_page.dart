import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/recipe.dart';
import '../../services/product_service.dart';
import '../../services/recipe_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'outlet_page.dart';
import 'product_detail_page.dart';
import 'product_page.dart';
import 'profile_page.dart';
import 'recipe_detail_page.dart';
import 'recipe_page.dart';
import 'cart_page.dart';
import 'order_history_page.dart';
import 'notifikasi_page.dart';

// Alamat backend Laravel. Dipakai untuk melengkapi URL foto kalau API
// hanya mengirim path (contoh: "produk/abc.jpg"). Sesuaikan jika berbeda.
const String _kBackendUrl = 'http://127.0.0.1:8000';

class HomePelangganPage extends StatefulWidget {
  const HomePelangganPage({super.key});

  @override
  State<HomePelangganPage> createState() => _HomePelangganPageState();
}

class _HomePelangganPageState extends State<HomePelangganPage> {
  int _selectedIndex = 0;
  late Future<List<Product>> _productsFuture;
  late Future<List<Recipe>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  void _loadHomeData() {
    _productsFuture = ProductService.getProducts();
    _recipesFuture = RecipeService.getRecipes();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _refreshHome() async {
    setState(_loadHomeData);
    await Future.wait([_productsFuture, _recipesFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(),
          const ProductPage(),
          const OrderHistoryPage(),
          const CartPage(),
          const RecipePage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Menu bawah buatan sendiri: ikon di atas, nama menu di bawah ikon.
  Widget _buildBottomNav() {
    const items = [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Produk'),
      (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Pesanan'),
      (Icons.shopping_cart_outlined, Icons.shopping_cart_rounded, 'Keranjang'),
      (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Resep'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A2B2622),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _onItemTapped(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 56,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _selectedIndex == i
                                ? AppColors.primarySoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _selectedIndex == i ? items[i].$2 : items[i].$1,
                            size: 23,
                            color: _selectedIndex == i
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].$3,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10.5,
                            fontWeight: _selectedIndex == i
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: _selectedIndex == i
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Memberi jarak kiri-kanan untuk bagian yang tidak scroll menyamping.
  Widget _pad(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      );

  Widget _buildHomeContent() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondarySoft,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        toolbarHeight: 66,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: AppColors.bannerGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selamat datang di',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (rect) =>
                      AppColors.bannerGradient.createShader(rect),
                  child: const Text(
                    'TWFOOD',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 21,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              tooltip: 'Notifikasi',
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotifikasiPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.secondarySoft, AppColors.background],
            stops: [0.0, 0.25],
          ),
        ),
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _refreshHome,
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
              children: [
                _pad(_buildHeroBanner()),
                const SizedBox(height: 14),
                _pad(_buildMenuStrip()),
                const SizedBox(height: 32),
                _buildProductSection(),
                const SizedBox(height: 30),
                _buildRecipeSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _decorCircle(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }

  // Banner penuh selebar layar (rata kiri-kanan).
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33E31E24),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(gradient: AppColors.bannerGradient),
          child: InkWell(
            onTap: () => setState(() => _selectedIndex = 1),
            child: Stack(
              children: [
                Positioned(
                    right: -36, top: -36, child: _decorCircle(150, 0.15)),
                Positioned(
                    right: 40, bottom: -56, child: _decorCircle(130, 0.10)),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'SELAMAT DATANG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Nikmati pilihan\nproduk TWFOOD',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: Colors.white,
                          fontSize: 28,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Temukan produk dan inspirasi resep untuk menemani harimu.',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 11, 12, 11),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Belanja Sekarang',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.primary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Satu baris panjang berisi empat pintasan: Resep, Outlet, Pesanan, Keranjang.
  Widget _buildMenuStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          _stripItem(
            Icons.menu_book_rounded,
            'Resep',
            const Color(0xFFC98A00),
            AppColors.accentSoft,
            () => setState(() => _selectedIndex = 4),
          ),
          _stripItem(
            Icons.storefront_rounded,
            'Outlet',
            AppColors.primary,
            AppColors.primarySoft,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OutletPage()),
            ),
          ),
          _stripItem(
            Icons.receipt_long_rounded,
            'Pesanan',
            AppColors.secondary,
            AppColors.secondarySoft,
            () => setState(() => _selectedIndex = 2),
          ),
          _stripItem(
            Icons.shopping_cart_rounded,
            'Keranjang',
            const Color(0xFF2B2622),
            const Color(0xFFEFEAE4),
            () => setState(() => _selectedIndex = 3),
          ),
        ],
      ),
    );
  }

  Widget _stripItem(
    IconData icon,
    String label,
    Color warnaIkon,
    Color warnaLatar,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: warnaLatar,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: warnaIkon, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pad(
          _buildSectionHeader(
            title: 'Produk TWFOOD',
            subtitle: 'Pilihan produk untuk kamu.',
            onSeeAll: () => setState(() => _selectedIndex = 1),
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            if (snapshot.hasError) {
              return _pad(_buildErrorPreview('Gagal mengambil data produk.'));
            }

            final products = (snapshot.data ?? []).take(8).toList();
            if (products.isEmpty) {
              return _pad(_buildEmptyPreview('Belum ada produk tersedia.'));
            }

            // Produk disusun 2 kolom dan ikut scroll ke bawah bersama halaman.
            final rows = <Widget>[];
            for (var i = 0; i < products.length; i += 2) {
              rows.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildProductCard(products[i])),
                    const SizedBox(width: 14),
                    Expanded(
                      child: i + 1 < products.length
                          ? _buildProductCard(products[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
              rows.add(const SizedBox(height: 18));
            }
            return _pad(Column(children: rows));
          },
        ),
      ],
    );
  }

  // Kartu produk: foto besar, harga di atas foto, nama di bawah.
  Widget _buildProductCard(Product product) {
    final variants = product.varian.where((item) => item.statusAktif).toList();
    final startingPrice = _startingPrice(product);

    return InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(productId: product.idProduk),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.softShadow,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _networkImage(
                    product.fotoProduk,
                    fallbackIcon: Icons.fastfood_outlined,
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${variants.length} varian',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (startingPrice != null)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xE62B2622),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatRupiah(startingPrice),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                product.namaProduk,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
    );
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final result = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      result.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) result.write('.');
    }
    return 'Rp $result';
  }

  int? _startingPrice(Product product) {
    final prices = product.varian
        .where((variant) => variant.statusAktif)
        .expand((variant) => variant.daftarHarga)
        .where((price) => price.statusAktif)
        .map((price) => price.harga)
        .toList();
    if (prices.isEmpty) return null;
    prices.sort();
    return prices.first;
  }

  Widget _buildRecipeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pad(
          _buildSectionHeader(
            title: 'Inspirasi Resep',
            subtitle: 'Ide sajian dari produk TWFOOD.',
            onSeeAll: () => setState(() => _selectedIndex = 4),
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<Recipe>>(
          future: _recipesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            if (snapshot.hasError) {
              return _pad(_buildErrorPreview('Gagal mengambil data resep.'));
            }

            final recipes = (snapshot.data ?? []).take(6).toList();
            if (recipes.isEmpty) {
              return _pad(_buildEmptyPreview('Belum ada resep tersedia.'));
            }

            return SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                itemCount: recipes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) =>
                    _buildRecipeCard(recipes[index]),
              ),
            );
          },
        ),
      ],
    );
  }

  // Kartu resep: foto penuh dengan judul di atas lapisan gelap.
  Widget _buildRecipeCard(Recipe recipe) {
    return SizedBox(
      width: 236,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeDetailPage(recipeId: recipe.idResep),
                ),
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                _networkImage(
                  recipe.foto,
                  fallbackIcon: Icons.menu_book_outlined,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xCC1A1410)],
                      stops: [0.35, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Lihat resep',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required VoidCallback onSeeAll,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 5,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headingMedium),
              const SizedBox(height: 3),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lihat semua'),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  // Melengkapi URL foto: kalau API hanya mengirim path (mis. "produk/a.jpg"),
  // diubah menjadi "http://.../storage/produk/a.jpg".
  String _resolveImageUrl(String url) {
    final u = url.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final path = u.startsWith('/') ? u.substring(1) : u;
    if (path.startsWith('storage/')) return '$_kBackendUrl/$path';
    return '$_kBackendUrl/storage/$path';
  }

  Widget _networkImage(String? url, {required IconData fallbackIcon}) {
    if (url == null || url.trim().isEmpty) {
      return _imageFallback(fallbackIcon);
    }
    return Image.network(
      _resolveImageUrl(url),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // Cadangan untuk Chrome (web) bila foto terhalang aturan CORS.
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => _imageFallback(fallbackIcon),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.primarySoft,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }

  // Placeholder bermerek: gradasi lembut dengan logo TWFOOD.
  Widget _imageFallback(IconData icon) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarySoft, AppColors.secondarySoft],
        ),
      ),
      alignment: Alignment.center,
      child: Opacity(
        opacity: 0.85,
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            width: 54,
            height: 54,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Icon(icon, size: 38, color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPreview(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(message, style: AppTextStyles.bodySmall),
    );
  }

  Widget _buildErrorPreview(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}