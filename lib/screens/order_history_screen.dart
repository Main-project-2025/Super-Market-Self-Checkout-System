import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<dynamic> transactions = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _showOrderItems(String orderId, String orderShortId, double total, String dateStr, String status) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF009485))),
    );
    try {
      final result = await ApiService.getTransaction(orderId);
      if (!mounted) return;
      Navigator.of(context).pop();
      final data = result['data'];
      final items = data != null && data['items'] != null ? data['items'] as List : <dynamic>[];
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #$orderShortId',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0C1D1B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dateStr • ${status.toUpperCase()}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF009485),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No items found for this order.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final it = items[index] as Map<String, dynamic>;
                          final name = (it['product_name'] ?? it['name'] ?? 'Product').toString();
                          final qty = (it['quantity'] ?? 0).toInt();
                          final unitPrice = (it['unit_price'] ?? 0).toDouble();
                          final lineTotal = (it['total_price'] ?? unitPrice * qty).toDouble();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF009485).withOpacity(0.12),
                                  child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF009485), size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0C1D1B),
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        '$qty × \$${unitPrice.toStringAsFixed(2)}',
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${lineTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0C1D1B),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close', style: TextStyle(color: Color(0xFF009485), fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load order details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadOrders() async {
    try {
      final data = await ApiService.getTransactions(limit: 50);
      if (mounted) {
        setState(() {
          transactions = data;
          isLoading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C1D1B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Order History',
          style: TextStyle(
            color: Color(0xFF0C1D1B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF009485)))
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
                        const SizedBox(height: 16),
                        Text(
                          'Could not load orders',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: _loadOrders,
                          child: const Text('Retry', style: TextStyle(color: Color(0xFF009485), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                )
              : transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No orders yet',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your completed orders will appear here',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final total = (tx['total_amount'] ?? 0).toDouble();
                        final createdAt = tx['created_at']?.toString() ?? '';
                        final status = (tx['status'] ?? 'pending').toString();
                        final id = (tx['id'] ?? '').toString();
                        final dateStr = createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
                        final orderShortId = id.length > 8 ? id.substring(0, 8) : id;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            onTap: () => _showOrderItems(id, orderShortId, total, dateStr, status),
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF009485).withOpacity(0.15),
                                child: const Icon(Icons.receipt, color: Color(0xFF009485), size: 22),
                              ),
                              title: Text(
                                'Order #$orderShortId',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0C1D1B)),
                              ),
                              subtitle: Text(
                                '$dateStr • ${status.toUpperCase()} • \$${total.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Color(0xFF0C1D1B)),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
