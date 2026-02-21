import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';

class ProductListScreen extends StatelessWidget {
  final String title;
  final List<Product> products;
  final Function(Product) onAddToCart;

  const ProductListScreen({
    super.key,
    required this.title,
    required this.products,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF0f2321)
        : const Color(0xFFF5F8F8);
    final surfaceColor = isDark ? const Color(0xFF162d2a) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0C1D1B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: products.isEmpty
          ? Center(
              child: Text(
                'No products available',
                style: GoogleFonts.plusJakartaSans(color: textColor),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(
                  context,
                  product,
                  surfaceColor,
                  textColor,
                );
              },
            ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    Color surfaceColor,
    Color textColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            product.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: GestureDetector(
                      onTap: () => onAddToCart(product),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF009485),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF009485),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
