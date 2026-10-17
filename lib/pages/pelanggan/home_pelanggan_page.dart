import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/recipe.dart';
import '../../services/product_service.dart';
import '../../services/recipe_service.dart';
import 'outlet_page.dart';
import 'product_page.dart';
import 'profile_page.dart';
import 'recipe_page.dart';
import 'cart_page.dart';

class HomePelangganPage extends StatefulWidget {
  const HomePelangganPage({super.key});

  @override
  State<HomePelangganPage> createState() => _HomePelangganPageState();
}

class _HomePelangganPageState extends State<HomePelangganPage> {
  // ============================================================
  // INDEX MENU UTAMA
  // ============================================================

  int _selectedIndex = 0;

  // ============================================================
  // FUTURE DATA
  // ============================================================

  late Future<List<Product>> _productsFuture;
  late Future<List<Recipe>> _recipesFuture;

  @override
  void initState() {
    super.initState();

    _productsFuture = ProductService.getProducts();
    _recipesFuture = RecipeService.getRecipes();
  }

  // ============================================================
  // GANTI TAB
  // ============================================================

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ============================================================
  // REFRESH DATA HOME
  // ============================================================

  Future<void> _refreshHome() async {
    setState(() {
      _productsFuture = ProductService.getProducts();
      _recipesFuture = RecipeService.getRecipes();
    });

    await Future.wait([_productsFuture, _recipesFuture]);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(),
          const ProductPage(),
          const PesananPlaceholderPage(),
          const CartPage(),
          const RecipePage(),
          const ProfilePage(),
        ],
      ),

      // ========================================================
      // NAVIGASI UTAMA
      // ========================================================
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Produk',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Resep',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HOME CONTENT
  // ============================================================

  Widget _buildHomeContent() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TWFOOD'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshHome,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                // ==================================================
                // SAPAAN
                // ==================================================

                const Text(
                  'Selamat Datang di TWFOOD',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Temukan produk lezat dan sehat dari TWFOOD.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // TENTANG TWFOOD
                // ==================================================
                _buildSectionCard(
                  title: 'Tentang TWFOOD',
                  icon: Icons.info_outline,
                  child: const Text(
                    'TWFOOD merupakan UMKM yang menyediakan '
                    'produk makanan berbasis jamur dan produk '
                    'olahan lainnya.',
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // PREVIEW PRODUK
                // ==================================================
                _buildProductSection(),

                const SizedBox(height: 28),

                // ==================================================
                // PREVIEW RESEP
                // ==================================================
                _buildRecipeSection(),

                const SizedBox(height: 28),

                // ==================================================
                // OUTLET
                // ==================================================
                _buildOutletSection(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Icon(icon, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            child,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUK SECTION
  // ============================================================

  Widget _buildProductSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Row(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 28),
                SizedBox(width: 10),
                Text(
                  'Produk TWFOOD',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              'Beberapa produk TWFOOD yang tersedia.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),

            const SizedBox(height: 16),

            FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                // ------------------------------------------------
                // LOADING
                // ------------------------------------------------

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // ------------------------------------------------
                // ERROR
                // ------------------------------------------------

                if (snapshot.hasError) {
                  return _buildPreviewError(
                    message: 'Gagal mengambil data produk.',
                  );
                }

                // ------------------------------------------------
                // DATA
                // ------------------------------------------------

                final products = (snapshot.data ?? []).take(3).toList();

                // ------------------------------------------------
                // DATA KOSONG
                // ------------------------------------------------

                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Belum ada produk.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // ------------------------------------------------
                // PREVIEW
                // ------------------------------------------------

                return SizedBox(
                  height: 215,

                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,

                    itemCount: products.length,

                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),

                    itemBuilder: (context, index) {
                      final product = products[index];

                      return _buildProductPreviewCard(product);
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // LIHAT PRODUK
            // --------------------------------------------------
            SizedBox(
              height: 46,

              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
                child: const Text('Lihat Produk'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT PREVIEW CARD
  // ============================================================

  Widget _buildProductPreviewCard(Product product) {
    return SizedBox(
      width: 165,

      child: Card(
        clipBehavior: Clip.antiAlias,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            // --------------------------------------------------
            // FOTO PRODUK
            // --------------------------------------------------

            SizedBox(
              height: 125,

              child:
                  product.fotoProduk != null &&
                      product.fotoProduk!.trim().isNotEmpty
                  ? Image.network(
                      product.fotoProduk!,
                      fit: BoxFit.cover,

                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 45,
                          ),
                        );
                      },
                    )
                  : const Center(child: Icon(Icons.image_outlined, size: 45)),
            ),

            // --------------------------------------------------
            // NAMA PRODUK
            // --------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(10),

              child: Text(
                product.namaProduk,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESEP SECTION
  // ============================================================

  Widget _buildRecipeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Row(
              children: [
                Icon(Icons.menu_book_outlined, size: 28),
                SizedBox(width: 10),
                Text(
                  'Resep TWFOOD',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              'Beberapa resep yang menggunakan '
              'produk TWFOOD.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),

            const SizedBox(height: 16),

            FutureBuilder<List<Recipe>>(
              future: _recipesFuture,
              builder: (context, snapshot) {
                // ------------------------------------------------
                // LOADING
                // ------------------------------------------------

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 215,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // ------------------------------------------------
                // ERROR
                // ------------------------------------------------

                if (snapshot.hasError) {
                  return _buildPreviewError(
                    message: 'Gagal mengambil data resep.',
                  );
                }

                // ------------------------------------------------
                // DATA
                // ------------------------------------------------

                final recipes = (snapshot.data ?? []).take(3).toList();

                // ------------------------------------------------
                // DATA KOSONG
                // ------------------------------------------------

                if (recipes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Belum ada resep.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // ------------------------------------------------
                // PREVIEW
                // ------------------------------------------------

                return SizedBox(
                  height: 215,

                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,

                    itemCount: recipes.length,

                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),

                    itemBuilder: (context, index) {
                      final recipe = recipes[index];

                      return _buildRecipePreviewCard(recipe);
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // LIHAT RESEP
            // --------------------------------------------------
            SizedBox(
              height: 46,

              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 4;
                  });
                },
                child: const Text('Lihat Resep'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RECIPE PREVIEW CARD
  // ============================================================

  Widget _buildRecipePreviewCard(Recipe recipe) {
    return SizedBox(
      width: 165,

      child: Card(
        clipBehavior: Clip.antiAlias,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            // --------------------------------------------------
            // FOTO RESEP
            // --------------------------------------------------

            SizedBox(
              height: 125,

              child: recipe.foto != null && recipe.foto!.trim().isNotEmpty
                  ? Image.network(
                      recipe.foto!,
                      fit: BoxFit.cover,

                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 45,
                          ),
                        );
                      },
                    )
                  : const Center(child: Icon(Icons.image_outlined, size: 45)),
            ),

            // --------------------------------------------------
            // JUDUL RESEP
            // --------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(10),

              child: Text(
                recipe.judul,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OUTLET SECTION
  // ============================================================

  Widget _buildOutletSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Row(
              children: [
                Icon(Icons.location_on_outlined, size: 28),
                SizedBox(width: 10),
                Text(
                  'Outlet TWFOOD',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Text(
              'Lihat informasi outlet TWFOOD, '
              'alamat, telepon, dan jam operasional.',
              style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey),
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 46,

              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OutletPage()),
                  );
                },
                child: const Text('Lihat Outlet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR PREVIEW
  // ============================================================

  Widget _buildPreviewError({required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),

      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40),

          const SizedBox(height: 8),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// PLACEHOLDER PESANAN
// ================================================================

class PesananPlaceholderPage extends StatelessWidget {
  const PesananPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan'),
        automaticallyImplyLeading: false,
      ),

      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),

          child: Text(
            'Fitur Pesanan akan dibuat '
            'pada step berikutnya.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// PLACEHOLDER KERANJANG
// ================================================================

class KeranjangPlaceholderPage extends StatelessWidget {
  const KeranjangPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        automaticallyImplyLeading: false,
      ),

      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),

          child: Text(
            'Fitur Keranjang akan dibuat '
            'pada step berikutnya.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
