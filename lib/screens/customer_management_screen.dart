import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> customers = [];
  bool isLoading = true;
  String? errorMessage;
  int currentOffset = 0;
  final int limit = 20;
  bool hasMore = true;
  int totalCustomers = 0;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        currentOffset = 0;
        customers.clear();
        hasMore = true;
        isLoading = true;
      });
    } else {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final result = await ApiService.getCustomers(
        limit: limit,
        offset: currentOffset,
        search: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          final newCustomers = result['data'] as List<dynamic>? ?? [];
          if (refresh) {
            customers = newCustomers;
          } else {
            customers.addAll(newCustomers);
          }
          
          final pagination = result['pagination'] ?? {};
          totalCustomers = pagination['total'] ?? 0;
          
          hasMore = newCustomers.length >= limit;
          isLoading = false;
          errorMessage = null;
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

  void _loadMore() {
    if (!isLoading && hasMore) {
      currentOffset += limit;
      _fetchCustomers();
    }
  }

  void _showCustomerDetailDialog(Map<String, dynamic> customerBase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomerDetailSheet(customerId: customerBase['id'].toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _fetchCustomers(refresh: true);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (_) => _fetchCustomers(refresh: true),
            ),
          ),
          
          // Header Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Customers: $totalCustomers',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (isLoading && customers.isNotEmpty)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Main List
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchCustomers(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (customers.isEmpty) {
      return const Center(
        child: Text('No customers found. Try a different search.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchCustomers(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!isLoading &&
              hasMore &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
            _loadMore();
            return true;
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: customers.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == customers.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final customer = customers[index];
            final role = customer['role']?.toString() ?? 'customer';
            final name = customer['name']?.toString() ?? 'Unknown';
            final email = customer['email']?.toString() ?? 'No Email';
            final transactionCount = customer['transaction_count'] ?? 0;
            final totalSpend = (customer['total_spend'] ?? 0.0).toDouble();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: role == 'admin' ? Colors.red[100] : Colors.teal[100],
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: role == 'admin' ? Colors.red[800] : Colors.teal[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (role == 'admin')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(fontSize: 10, color: Colors.red[800], fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(email, style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.teal[700]),
                        const SizedBox(width: 4),
                        Text('$transactionCount orders'),
                        const SizedBox(width: 16),
                        Icon(Icons.attach_money, size: 14, color: Colors.green[700]),
                        Text('\$${totalSpend.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCustomerDetailDialog(customer),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CustomerDetailSheet extends StatefulWidget {
  final String customerId;

  const _CustomerDetailSheet({required this.customerId});

  @override
  State<_CustomerDetailSheet> createState() => _CustomerDetailSheetState();
}

class _CustomerDetailSheetState extends State<_CustomerDetailSheet> {
  Map<String, dynamic>? detail;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final result = await ApiService.getCustomerDetail(widget.customerId);
      if (mounted) {
        setState(() {
          detail = result['data'];
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDetail,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (detail == null) {
      return const Center(child: Text('Customer not found'));
    }

    final name = detail!['name'] ?? 'Unknown';
    final email = detail!['email'] ?? '';
    final role = detail!['role'] ?? 'customer';
    final transactionCount = detail!['transaction_count'] ?? 0;
    final totalSpend = (detail!['total_spend'] ?? 0.0).toDouble();
    final createdAt = detail!['created_at'] != null 
        ? DateFormat('MMM d, yyyy').format(DateTime.parse(detail!['created_at']))
        : 'Unknown';
    final transactions = (detail!['transactions'] as List<dynamic>? ?? []);

    return Column(
      children: [
        // Customer Header
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: role == 'admin' ? Colors.red[100] : Colors.teal[100],
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 24,
                    color: role == 'admin' ? Colors.red[800] : Colors.teal[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(email, style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text('Joined: $createdAt', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Summary Stats Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Card(
            color: Colors.grey[50],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Orders', transactionCount.toString(), Icons.shopping_bag),
                  _buildStatColumn('Total Spent', '\$${totalSpend.toStringAsFixed(2)}', Icons.payment),
                  _buildStatColumn('Avg Order', 
                    transactionCount > 0 
                        ? '\$${(totalSpend / transactionCount).toStringAsFixed(2)}' 
                        : '\$0.00', 
                    Icons.analytics),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Transaction History Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Transaction History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        
        const SizedBox(height: 8),

        // Transaction List
        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Text('No transactions yet', style: TextStyle(color: Colors.grey[500])),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    final date = t['created_at'] != null 
                        ? DateFormat('MMM d, y h:mm a').format(DateTime.parse(t['created_at']))
                        : 'Unknown Date';
                    final amount = (t['total_amount'] ?? 0.0).toDouble();
                    final status = t['status'] ?? 'unknown';
                    
                    Color statusColor;
                    if (status == 'paid') statusColor = Colors.green;
                    else if (status == 'pending') statusColor = Colors.orange;
                    else statusColor = Colors.red;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long, color: Colors.teal),
                      ),
                      title: Text('Order #${t['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(date, style: const TextStyle(fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$${amount.toStringAsFixed(2)}', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(status.toUpperCase(), 
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal[300], size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}
