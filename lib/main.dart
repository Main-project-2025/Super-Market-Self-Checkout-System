// ============== DATA MODELS ==============
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/product_model.dart';
import 'screens/premium_login_screen.dart';
import 'screens/premium_home_screen.dart';
import 'screens/premium_cart_screen.dart';

// CartItem model
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});
}

// ============== MOCK DATA ==============
const List<Product> mockProducts = [
  Product(id: '1', name: 'Fresh Milk', price: 1.50, barcode: '111111'),
  Product(id: '2', name: 'Brown Bread', price: 2.20, barcode: '222222'),
  Product(id: '3', name: 'Organic Eggs (12)', price: 4.50, barcode: '333333'),
  Product(id: '4', name: 'Avocado', price: 1.80, barcode: '444444'),
  Product(id: '5', name: 'Chicken Breast', price: 8.99, barcode: '555555'),
  Product(id: '6', name: 'Cheddar Cheese', price: 5.40, barcode: '666666'),
];

const List<Product> mockRecommendations = [
  Product(id: '7', name: 'Greek Yogurt', price: 3.25, barcode: '777777'),
  Product(id: '8', name: 'Almond Milk', price: 2.99, barcode: '888888'),
  Product(id: '9', name: 'Whole Wheat Pasta', price: 1.75, barcode: '999999'),
];

// ============== MAIN APP ==============
void main() {
  runApp(SelfCheckoutApp());
}

class SelfCheckoutApp extends StatelessWidget {
  const SelfCheckoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Self-Checkout',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const PremiumLoginScreen(), // Using the premium login screen
      debugShowCheckedModeBanner: false,
    );
  }
}


// ============== OLD AUTHENTICATION SCREENS REMOVED ==============
// The old LoginScreen and RegistrationScreen have been replaced with PremiumLoginScreen
// located in lib/screens/premium_login_screen.dart

// ============== HOME SCREEN ==============
// ============== OLD HOME SCREEN REMOVED ==============
// The old HomeScreen has been replaced with PremiumHomeScreen
// located in lib/screens/premium_home_screen.dart

// ============== CART SCREEN ==============
// ============== OLD CART SCREEN REMOVED ==============
// The old CartScreen has been replaced with PremiumCartScreen
// located in lib/screens/premium_cart_screen.dart

// ============== CHECKOUT SCREEN ==============
class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cart;
  final VoidCallback onFinish;

  const CheckoutScreen({super.key, required this.cart, required this.onFinish});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String qrData = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  double get totalPrice => widget.cart.fold(
    0,
    (sum, item) => sum + item.product.price * item.quantity,
  );

  String get userId => 'user_001'; // Mock userId

  Future<void> _generateQRCode() async {
    try {
      final qrCodeData = await getBillJson();
      setState(() {
        qrData = qrCodeData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating QR code: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> getBillJson() async {
    try {
      // Create transaction on backend
      final items = widget.cart
          .map(
            (item) => {
              'product_id': item.product.id,
              'quantity': item.quantity,
            },
          )
          .toList();

      final transactionResult = await ApiService.createTransaction(
        items: items,
        paymentMethod: 'qr_code',
      );

      if (transactionResult['success'] == true) {
        final transactionData = transactionResult['data'];
        return transactionData['qr_code_data'] ?? jsonEncode(transactionData);
      } else {
        throw Exception('Failed to create transaction');
      }
    } catch (e) {
      // Fallback to local QR code
      final bill = {
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'total': totalPrice,
        'items': widget.cart
            .map(
              (item) => {
                'id': item.product.id,
                'name': item.product.name,
                'price': item.product.price,
                'quantity': item.quantity,
                'barcode': item.product.barcode,
              },
            )
            .toList(),
      };
      return jsonEncode(bill);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Text(
              'Please show this QR code to a staff member for payment verification.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Center(
              child: SizedBox(
                width: 220.0,
                height: 220.0,
                child: isLoading
                    ? CircularProgressIndicator(
                        color: Colors.teal,
                        strokeWidth: 3,
                      )
                    : QrImageView(data: qrData, size: 220.0),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Total Bill: \$${totalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(Icons.check_circle_outline),
                label: Text(
                  'Finish Shopping',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  widget.onFinish();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => PremiumHomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============== BARCODE SCANNER SCREEN ==============
class BarcodeScannerScreen extends StatefulWidget {
  final Function(Product) onProductScanned;

  const BarcodeScannerScreen({super.key, required this.onProductScanned});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;
  bool torchOn = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  // Find product by barcode using API
  Future<Product?> findProductByBarcode(String barcode) async {
    try {
      final response = await ApiService.getProductByBarcode(barcode);
      if (response['success'] == true) {
        return Product.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error finding product: $e');
      return null;
    }
  }

  // Handle barcode detection
  void _onDetect(BarcodeCapture capture) {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          isScanning = false;
        });

        _handleBarcodeScan(code);
      }
    }
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    try {
      final Product? product = await findProductByBarcode(barcode);
      if (product != null) {
        widget.onProductScanned(product);
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product not found for barcode: $barcode'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          isScanning = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning barcode: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        isScanning = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
        actions: [
          IconButton(
            icon: Icon(
              torchOn ? Icons.flash_on : Icons.flash_off,
              color: torchOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                torchOn = !torchOn;
              });
              cameraController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_rear),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onDetect),
          // Scanning overlay
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Corner indicators
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.teal, width: 4),
                            left: BorderSide(color: Colors.teal, width: 4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.teal, width: 4),
                            right: BorderSide(color: Colors.teal, width: 4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.teal, width: 4),
                            left: BorderSide(color: Colors.teal, width: 4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.teal, width: 4),
                            right: BorderSide(color: Colors.teal, width: 4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Position the barcode within the frame to scan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============== ADMIN DASHBOARD SCREEN ==============
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => PremiumLoginScreen()),
                (route) => false,
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.tealAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            size: 40,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Admin Dashboard',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage and analyze customer data',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Admin Features Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildAdminFeatureCard(
                        context,
                        icon: Icons.analytics,
                        title: 'Customer\nSegmentation',
                        description: 'Analyze customer purchase patterns',
                        color: Colors.green,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CustomerSegmentationScreen(),
                            ),
                          );
                        },
                      ),
                      // Placeholder for future admin features
                      _buildAdminFeatureCard(
                        context,
                        icon: Icons.notifications_active,
                        title: 'Low Stock\nAlerts',
                        description: 'Predictive inventory warnings',
                        color: Colors.redAccent,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LowStockAlertsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildAdminFeatureCard(
                        context,
                        icon: Icons.people,
                        title: 'Customer\nManagement',
                        description: 'Manage customer accounts (Coming Soon)',
                        color: Colors.blue,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('This feature is coming soon!'),
                            ),
                          );
                        },
                      ),
                      _buildAdminFeatureCard(
                        context,
                        icon: Icons.inventory,
                        title: 'Product\nManagement',
                        description: 'Manage products and inventory (Coming Soon)',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductManagementScreen(),
                            ),
                          );
                        },
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

  Widget _buildAdminFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============== CUSTOMER SEGMENTATION SCREEN ==============
class CustomerSegmentationScreen extends StatefulWidget {
  const CustomerSegmentationScreen({super.key});

  @override
  State<CustomerSegmentationScreen> createState() => _CustomerSegmentationScreenState();
}

class _CustomerSegmentationScreenState extends State<CustomerSegmentationScreen> {
  Map<String, dynamic>? segmentationData;
  Map<String, dynamic>? statisticsData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final segmentationResult = await ApiService.getCustomerSegmentation();
      final statisticsResult = await ApiService.getStatistics();

      if (mounted) {
        setState(() {
          segmentationData = segmentationResult['data'];
          statisticsData = statisticsResult['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Segmentation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading data',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics Summary
                        if (statisticsData != null) _buildStatisticsCard(),
                        const SizedBox(height: 16),
                        // Segmentation Results
                        if (segmentationData != null) _buildSegmentationResults(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatisticsCard() {
    final stats = statisticsData!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Overall Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Customers', '${stats['total_customers'] ?? 0}'),
            _buildStatRow('Active Customers', '${stats['active_customers'] ?? 0}'),
            _buildStatRow('Total Transactions', '${stats['total_transactions'] ?? 0}'),
            _buildStatRow(
              'Total Revenue',
              '\$${(stats['total_revenue'] ?? 0).toStringAsFixed(2)}',
              isHighlight: true,
            ),
            _buildStatRow(
              'Paid Revenue',
              '\$${(stats['paid_revenue'] ?? 0).toStringAsFixed(2)}',
            ),
            _buildStatRow(
              'Avg Transaction',
              '\$${(stats['avg_transaction_amount'] ?? 0).toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.teal : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentationResults() {
    final data = segmentationData!;
    final clusters = data['clusters'] as Map<String, dynamic>?;
    final summary = data['summary'] as Map<String, dynamic>?;

    if (clusters == null || clusters.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No customer segments found. Need more transaction data.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Segments',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Total Customers Analyzed: ${data['total_customers'] ?? 0}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ...clusters.entries.map((entry) {
          final clusterId = entry.key;
          final clusterData = entry.value as Map<String, dynamic>;
          return _buildClusterCard(clusterId, clusterData);
        }),
        if (summary != null) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.teal),
                      const SizedBox(width: 8),
                      const Text(
                        'Summary',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Overall Avg Purchase',
                    '\$${(summary['overall_avg_purchase'] ?? 0).toStringAsFixed(2)}',
                  ),
                  _buildStatRow(
                    'Total Revenue',
                    '\$${(summary['overall_total_revenue'] ?? 0).toStringAsFixed(2)}',
                    isHighlight: true,
                  ),
                  _buildStatRow(
                    'Avg Transactions per Customer',
                    '${(summary['overall_avg_transactions'] ?? 0).toStringAsFixed(1)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClusterCard(String clusterId, Map<String, dynamic> clusterData) {
    final label = clusterData['label'] as String? ?? 'Cluster $clusterId';
    final customerCount = clusterData['customer_count'] ?? 0;
    final avgPurchase = clusterData['avg_total_purchase'] ?? 0.0;
    final minPurchase = clusterData['min_purchase'] ?? 0.0;
    final maxPurchase = clusterData['max_purchase'] ?? 0.0;
    final avgTransactions = clusterData['avg_transaction_count'] ?? 0.0;

    Color clusterColor;
    IconData clusterIcon;
    switch (label) {
      case 'High Value':
        clusterColor = Colors.green;
        clusterIcon = Icons.star;
        break;
      case 'Medium Value':
        clusterColor = Colors.orange;
        clusterIcon = Icons.star_border;
        break;
      case 'Low Value':
        clusterColor = Colors.blue;
        clusterIcon = Icons.star_outline;
        break;
      default:
        clusterColor = Colors.teal;
        clusterIcon = Icons.people;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: clusterColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(clusterIcon, color: clusterColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: clusterColor,
                        ),
                      ),
                      Text(
                        '$customerCount customers',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Avg Total Purchase', '\$${avgPurchase.toStringAsFixed(2)}'),
            _buildStatRow('Purchase Range', '\$${minPurchase.toStringAsFixed(2)} - \$${maxPurchase.toStringAsFixed(2)}'),
            _buildStatRow('Avg Transactions', avgTransactions.toStringAsFixed(1)),
            if (clusterData['avg_transaction_amount'] != null)
              _buildStatRow(
                'Avg Transaction Amount',
                '\$${(clusterData['avg_transaction_amount'] as num).toStringAsFixed(2)}',
              ),
          ],
        ),
      ),
    );
  }
}

// ============== ADMIN PRODUCT MANAGEMENT ==============
class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final list = await ApiService.getProducts();
      setState(() {
        products = list;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withOpacity(0.1),
                      child: Text(product['name'][0].toUpperCase()),
                    ),
                    title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Price: \$${product['price']} | Stock: ${product['stock_quantity'] ?? 0}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminProductDetailScreen(product: product),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class AdminProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const AdminProductDetailScreen({super.key, required this.product});

  @override
  State<AdminProductDetailScreen> createState() => _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends State<AdminProductDetailScreen> {
  bool isLoadingSuggestion = false;
  Map<String, dynamic>? pricingSuggestion;
  String? errorMessage;

  Future<void> _fetchPricingSuggestion() async {
    setState(() {
      isLoadingSuggestion = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getPricingSuggestion(widget.product['id']);
      if (result['success'] == true) {
        setState(() {
          pricingSuggestion = result['data'];
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSuggestion = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['name']),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            const Text(
              'Dynamic Pricing Analysis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPricingCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Barcode', widget.product['barcode']),
            _row('Category', widget.product['category'] ?? 'N/A'),
            _row('Current Price', '\$${widget.product['price']}'),
            _row('Stock', '${widget.product['stock_quantity'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AI Suggested Price', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (!isLoadingSuggestion && pricingSuggestion == null)
                  ElevatedButton(
                    onPressed: _fetchPricingSuggestion,
                    child: const Text('Analyze'),
                  ),
              ],
            ),
            if (isLoadingSuggestion)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: $errorMessage', style: const TextStyle(color: Colors.red)),
              ),
            if (pricingSuggestion != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _priceBox('Current', pricingSuggestion!['current_price'], Colors.grey),
                  const Icon(Icons.arrow_forward, color: Colors.teal),
                  _priceBox('Suggested', pricingSuggestion!['suggested_price'], Colors.green),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (pricingSuggestion!['confidence'] ?? 0).toDouble(),
                backgroundColor: Colors.grey[200],
                color: Colors.green,
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                'Confidence Score: ${((pricingSuggestion!['confidence'] ?? 0) * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                      if (pricingSuggestion == null) return;
                      
                      try {
                        // Confirm dialog
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (cntx) => AlertDialog(
                            title: const Text('Update Price?'),
                            content: Text(
                              'This will update the product price to \\\$${pricingSuggestion!['suggested_price'].toStringAsFixed(2)}.\\nAre you sure?'
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(cntx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(cntx, true), child: const Text('Update')),
                            ],
                          )
                        );
                        
                        if (confirm == true) {
                           final result = await ApiService.applyPricingSuggestion(widget.product['id']);
                           if (result['success'] == true && mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Price updated successfully!'), backgroundColor: Colors.green)
                             );
                             // Refresh data
                             setState(() {
                               pricingSuggestion!['current_price'] = result['new_price'];
                               // Update widget.product['price'] locally so "Info Card" updates too purely for display
                               widget.product['price'] = result['new_price'];
                             });
                           }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update price: \$e'), backgroundColor: Colors.red)
                          );
                        }
                      }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Apply Suggestion"),
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _priceBox(String label, dynamic price, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          '\$${price?.toStringAsFixed(2) ?? "N/A"}',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
// ============== LOW STOCK ALERTS SCREEN ==============
class LowStockAlertsScreen extends StatefulWidget {
  const LowStockAlertsScreen({super.key});

  @override
  State<LowStockAlertsScreen> createState() => _LowStockAlertsScreenState();
}

class _LowStockAlertsScreenState extends State<LowStockAlertsScreen> {
  List<dynamic> alerts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getLowStockAlerts();
      if (mounted) {
        setState(() {
          alerts = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Alerts'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.tealAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading alerts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadAlerts,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : alerts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Inventory is Healthy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No low stock items detected.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          final isCritical = (alert['days_until_stockout'] != 'N/A' &&
                                  alert['days_until_stockout'] < 3) ||
                              alert['current_stock'] == 0;

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isCritical
                                              ? Colors.red.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.warning_amber_rounded,
                                          color: isCritical
                                              ? Colors.red
                                              : Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              alert['product_name'] ?? 'Unknown',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'ID: ${alert['product_id']}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoItem(
                                        'Current Stock',
                                        '${alert['current_stock']}',
                                        Colors.black87,
                                      ),
                                      _buildInfoItem(
                                        'Daily Sales',
                                        '${alert['daily_velocity']}',
                                        Colors.black87,
                                      ),
                                      _buildInfoItem(
                                        'Days Left',
                                        '${alert['days_until_stockout']}',
                                        isCritical ? Colors.red : Colors.orange,
                                      ),
                                    ],
                                  ),
                                  if (alert['reason'] != null &&
                                      (alert['reason'] as List).isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              (alert['reason'] as List).join(', '),
                                              style: TextStyle(
                                                color: Colors.grey[800],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
