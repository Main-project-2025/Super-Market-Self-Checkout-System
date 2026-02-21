import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'premium_login_screen.dart';
import 'premium_cart_screen.dart';
import 'premium_scanner_screen.dart';
import 'product_list_screen.dart';
import 'order_history_screen.dart';

class PremiumHomeScreen extends StatefulWidget {
  const PremiumHomeScreen({super.key});

  @override
  State<PremiumHomeScreen> createState() => _PremiumHomeScreenState();
}

class _PremiumHomeScreenState extends State<PremiumHomeScreen>
    with SingleTickerProviderStateMixin {
  List<CartItem> cart = [];
  List<Product> recommendations = [];
  bool isLoadingRecs = true;
  String userName = '';
  int totalOrders = 0;
  List<Product> buyItAgainProducts = [];
  bool isLoadingHistory = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _fetchRecommendations();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      userName = ApiService.userName;
    });
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final transactions = await ApiService.getTransactions(limit: 50);

      // Extract unique products for "Buy It Again"
      final Map<String, Product> uniqueProducts = {};
      for (var tx in transactions) {
        final items = tx['items'] as List?;
        if (items != null) {
          for (var item in items) {
            final productData = item['product'];
            if (productData != null) {
              final product = Product.fromJson(productData);
              uniqueProducts[product.id] = product;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          totalOrders = transactions.length;
          buyItAgainProducts = uniqueProducts.values.take(10).toList();
          isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
      if (mounted) {
        setState(() => isLoadingHistory = false);
      }
    }
  }

  Future<void> _fetchRecommendations() async {
    try {
      final currentItemIds = cart.map((item) => item.product.id).toList();
      final recs = await ApiService.getRecommendations(
        currentItems: currentItemIds,
      );
      if (mounted) {
        setState(() {
          recommendations = recs.map((e) => Product.fromJson(e)).toList();
          isLoadingRecs = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching recommendations: $e');
      if (mounted) {
        setState(() {
          isLoadingRecs = false;
        });
      }
    }
  }

  double get totalPrice =>
      cart.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  int get cartCount => cart.length;

  void scanProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PremiumScannerScreen(
          cartTotal: totalPrice,
          itemCount: cartCount,
          onBarcodeScanned: (barcode) async {
            // Fetch product by barcode from API
            try {
              final productData = await ApiService.getProductByBarcode(barcode);
              final product = Product.fromJson(productData);
              if (mounted) {
                setState(() {
                  final index = cart.indexWhere(
                    (item) => item.product.id == product.id,
                  );
                  if (index >= 0) {
                    cart[index].quantity += 1;
                  } else {
                    cart.add(CartItem(product: product, quantity: 1));
                  }
                });
                _fetchRecommendations();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added "${product.name}" to cart!'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: const Color(0xFF009485),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Product not found: $barcode'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> goToCart() async {
    final updatedCart = await Navigator.of(context).push<List<CartItem>>(
      MaterialPageRoute(
        builder: (_) => PremiumCartScreen(cart: List<CartItem>.from(cart)),
      ),
    );
    if (updatedCart != null) {
      setState(() {
        cart = updatedCart;
      });
    }
  }

  void goToCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(cart: cart, onFinish: clearCart),
      ),
    );
  }

  void clearCart() {
    setState(() {
      cart.clear();
    });
  }

  void _showAccountDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Account details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _accountRow(Icons.person_outline, 'Name', userName),
            const SizedBox(height: 12),
            _accountRow(Icons.badge_outlined, 'Role', ApiService.userRole ?? 'customer'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF009485), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _accountRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF0C1D1B))),
          ],
        ),
      ],
    );
  }

  void _showOrderHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
    );
  }

  void addToCart(Product product) {
    setState(() {
      final index = cart.indexWhere((item) => item.product.id == product.id);
      if (index >= 0) {
        cart[index].quantity += 1;
      } else {
        cart.add(CartItem(product: product, quantity: 1));
      }
    });
    _fetchRecommendations();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${product.name}" to cart!'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF009485),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F8),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Column(
              children: [
                // Header
                _buildHeader(),
                // Scrollable Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _fetchRecommendations();
                      await _fetchHistory();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          // Stats Card
                          _buildStatsCard(),
                          const SizedBox(height: 24),
                          // Recommendations Section
                          _buildRecommendationsSection(),
                          const SizedBox(height: 32),
                          // Buy It Again Section
                          if (buyItAgainProducts.isNotEmpty) ...[
                            _buildBuyItAgainSection(),
                            const SizedBox(height: 32),
                          ],
                          // Empty State / Cart Status
                          _buildCartStatus(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Bottom Floating Section
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final status = totalOrders > 20
        ? 'Gold Member'
        : totalOrders > 10
        ? 'Silver Member'
        : 'Bronze Member';
    final statusColor = totalOrders > 20
        ? const Color(0xFFFFD700)
        : totalOrders > 10
        ? const Color(0xFFC0C0C0)
        : const Color(0xFFCD7F32);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0C1D1B), Color(0xFF1B3A36)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Shopping Activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatItem('Orders', totalOrders.toString()),
                      const SizedBox(width: 24),
                      _buildStatItem('Points', (totalOrders * 50).toString()),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.stars_rounded, color: statusColor, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBuyItAgainSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Buy It Again',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C1D1B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: buyItAgainProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final product = buyItAgainProducts[index];
                return GestureDetector(
                  onTap: () => addToCart(product),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        product.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  product.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Colors.grey.shade400,
                                        size: 32,
                                      ),
                                ),
                              )
                            : Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.grey.shade400,
                                size: 32,
                              ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0C1D1B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F8).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile avatar with dropdown (Account details, Order history)
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'account') _showAccountDetails();
              if (value == 'orders') _showOrderHistory();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'account',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Color(0xFF0C1D1B), size: 22),
                    SizedBox(width: 12),
                    Text('Account details', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'orders',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: Color(0xFF0C1D1B), size: 22),
                    SizedBox(width: 12),
                    Text('Order history', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Container(
                          color: const Color(0xFF009485),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF5F8F8),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'WELCOME BACK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C1D1B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600, size: 24),
              ],
            ),
          ),
          // Logout button (top right)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () async {
                await ApiService.logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const PremiumLoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Icon(
                Icons.logout,
                color: Color(0xFF0C1D1B),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Just For You',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C1D1B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Based on your purchase history',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (recommendations.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductListScreen(
                            title: 'Just For You',
                            products: recommendations,
                            onAddToCart: addToCart,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: Color(0xFF009485),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: isLoadingRecs
                ? const Center(child: CircularProgressIndicator())
                : recommendations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Complete a purchase to get personalized recommendations here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: recommendations.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final product = recommendations[index];
                      return _buildRecommendationCard(product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Product product) {
    return Container(
      width: 176,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Stack(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          product.imageUrl!,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: Color(0xFF009485),
                  ),
                ),
              ),
            ],
          ),
          // Product Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C1D1B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.description ?? 'Fresh & Quality',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF009485),
                      ),
                    ),
                    InkWell(
                      onTap: () => addToCart(product),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF009485).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 18,
                          color: Color(0xFF009485),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: goToCart,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: cart.isEmpty
                ? _buildEmptyCartContent()
                : _buildCartWithItemsContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCartContent() {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.shopping_basket_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C1D1B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap scan to add items. Tap here to open cart.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartWithItemsContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'You have $cartCount item(s)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C1D1B),
              ),
            ),
            Text(
              'Total: \$${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF009485),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Recently added • Tap to view full cart',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cart.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = cart[index];
              final p = item.product;
              return Container(
                width: 88,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: p.imageUrl != null
                          ? Image.network(
                              p.imageUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.shopping_bag_outlined,
                                size: 32,
                                color: Colors.grey.shade400,
                              ),
                            )
                          : Icon(
                              Icons.shopping_bag_outlined,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0C1D1B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '×${item.quantity}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF5F8F8).withOpacity(0),
              const Color(0xFFF5F8F8).withOpacity(0.9),
              const Color(0xFFF5F8F8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scan Button
              Center(
                child: Transform.translate(
                  offset: const Offset(0, -8),
                  child: ElevatedButton.icon(
                    onPressed: scanProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C1D1B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                    icon: const Icon(Icons.qr_code_scanner, size: 28),
                    label: const Text(
                      'Scan Product',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Checkout Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL AMOUNT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0C1D1B),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ITEMS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$cartCount',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0C1D1B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cart.isEmpty ? null : goToCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009485),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: cart.isEmpty ? 0 : 4,
                          shadowColor: const Color(0xFF009485).withOpacity(0.3),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Checkout',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
