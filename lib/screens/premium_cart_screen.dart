import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../models/product_model.dart';

class PremiumCartScreen extends StatefulWidget {
  final List<CartItem> cart;

  const PremiumCartScreen({super.key, required this.cart});

  @override
  State<PremiumCartScreen> createState() => _PremiumCartScreenState();
}

class _PremiumCartScreenState extends State<PremiumCartScreen>
    with SingleTickerProviderStateMixin {
  late List<CartItem> cart;
  late AnimationController _swipeController;
  double _swipeProgress = 0.0;
  bool _isSwiping = false;

  @override
  void initState() {
    super.initState();
    cart = widget.cart;
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  double get subtotal =>
      cart.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  double get tax => subtotal * 0.05;

  double get totalPrice => subtotal + tax;

  int get itemCount => cart.length;

  void increaseQty(int index) {
    setState(() {
      cart[index].quantity += 1;
    });
  }

  void decreaseQty(int index) {
    setState(() {
      if (cart[index].quantity > 1) {
        cart[index].quantity -= 1;
      } else {
        cart.removeAt(index);
      }
    });
  }

  void _onSwipeUpdate(DragUpdateDetails details, double maxWidth) {
    setState(() {
      _isSwiping = true;
      _swipeProgress += details.delta.dx;
      _swipeProgress = _swipeProgress.clamp(0.0, maxWidth - 80);
    });
  }

  void _onSwipeEnd(DragEndDetails details, double maxWidth) {
    if (_swipeProgress > (maxWidth - 80) * 0.75) {
      // User swiped far enough, trigger checkout
      _swipeController.forward().then((_) {
        Navigator.of(context).pop(cart);
        // Navigate to checkout
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CheckoutScreen(
              cart: cart,
              onFinish: () {
                setState(() {
                  cart.clear();
                });
              },
            ),
          ),
        );
      });
    } else {
      // Reset animation
      setState(() {
        _swipeProgress = 0.0;
        _isSwiping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF0f2321)
        : const Color(0xFFF5F8F8);
    final surfaceColor = isDark ? const Color(0xFF162d2a) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1D1B);
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Header
            _buildHeader(isDark, textColor),
            // Cart Items List
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              bottom: 280,
              child: cart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 80,
                            color: subtextColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your cart is empty',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              color: subtextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        return _buildCartItem(
                          cart[index],
                          index,
                          isDark,
                          surfaceColor,
                          textColor,
                          subtextColor,
                        );
                      },
                    ),
            ),
            // Bottom Sheet Summary
            _buildBottomSheet(isDark, surfaceColor, textColor, subtextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(cart),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.arrow_back, color: textColor, size: 20),
              ),
            ),
            // Title
            Column(
              children: [
                Text(
                  'My Cart',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$itemCount Items',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(
    CartItem item,
    int index,
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade200,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: item.product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 32,
                            color: subtextColor.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 32,
                      color: subtextColor.withOpacity(0.5),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF009485),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.product.price.toStringAsFixed(2)} / unit',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 12),
                // Quantity Controls
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => decreaseQty(index),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.remove, size: 18, color: textColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item.quantity}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => increaseQty(index),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF009485),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF009485).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white,
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

  Widget _buildBottomSheet(
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Indicator
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Price Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildPriceLine(
                    'Subtotal',
                    subtotal,
                    subtextColor,
                    textColor,
                  ),
                  const SizedBox(height: 12),
                  _buildPriceLine('Tax (5%)', tax, subtextColor, textColor),
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: isDark
                        ? Colors.grey.shade700.withOpacity(0.5)
                        : Colors.grey.shade100,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '\$${totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Swipe to Pay Button
            _buildSwipeToPayButton(isDark, surfaceColor, textColor),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceLine(
    String label,
    double amount,
    Color labelColor,
    Color amountColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: labelColor),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeToPayButton(
    bool isDark,
    Color surfaceColor,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          return GestureDetector(
            onHorizontalDragUpdate: (details) =>
                _onSwipeUpdate(details, maxWidth),
            onHorizontalDragEnd: (details) => _onSwipeEnd(details, maxWidth),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0f2321)
                    : const Color(0xFFF5F8F8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background Progress
                  if (_swipeProgress > 0)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: _swipeProgress + 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF009485).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                  // Text
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Swipe to pay',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF009485),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: const Color(0xFF009485),
                          size: 20,
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: const Color(0xFF009485).withOpacity(0.6),
                          size: 20,
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: const Color(0xFF009485).withOpacity(0.3),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  // Draggable Circle
                  AnimatedPositioned(
                    duration: _isSwiping
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    left: 6 + _swipeProgress,
                    top: 6,
                    child: GestureDetector(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF009485),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF009485).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
