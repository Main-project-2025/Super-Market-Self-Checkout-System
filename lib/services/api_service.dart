import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_data.dart';
import '../models/product_model.dart';
import '../models/staff_model.dart';

class ApiService {
  // Default backend URL
  static const String _defaultBaseUrl = 'http://192.168.58.17:3000/api';
  static String _baseUrl = _defaultBaseUrl;
  static String? _token;
  static String? _userRole;
  static String? _userName;

  // Get current base URL
  static String get baseUrl => _baseUrl;

  // Get current user name
  static String get userName => _userName ?? 'User';

  // Set and save base URL
  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.endsWith('/api') ? url : '$url/api';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', _baseUrl);
  }

  // Get saved base URL or return default
  static Future<String> getSavedBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? _defaultBaseUrl;
  }

  // Initialize token and base URL from storage
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userRole = prefs.getString('user_role');
    _userName = prefs.getString('user_name');
    _baseUrl = prefs.getString('base_url') ?? _defaultBaseUrl;
  }

  // Get current user role
  static String? get userRole => _userRole;

  // Check if user is admin
  static bool get isAdmin => _userRole == 'admin';

  // Save token and user info to storage
  static Future<void> saveToken(
    String token, {
    String? role,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
    if (role != null) {
      await prefs.setString('user_role', role);
      _userRole = role;
    }
    if (name != null) {
      await prefs.setString('user_name', name);
      _userName = name;
    }
  }

  // Clear token and user info from storage
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    _token = null;
    _userRole = null;
    _userName = null;
  }

  // Get headers with authentication
  static Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // Handle API responses
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Request failed');
    }
  }

  // Authentication APIs
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _getHeaders(),
      body: json.encode({'email': email, 'password': password, 'name': name}),
    );

    final result = _handleResponse(response);
    if (result['token'] != null) {
      await saveToken(
        result['token'],
        role: result['user']?['role'],
        name: result['user']?['name'],
      );
    }
    return result;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(),
      body: json.encode({'email': email, 'password': password}),
    );

    final result = _handleResponse(response);
    if (result['token'] != null) {
      await saveToken(
        result['token'],
        role: result['user']?['role'],
        name: result['user']?['name'],
      );
    }
    return result;
  }

  static Future<Map<String, dynamic>> staffLogin({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(),
      body: json.encode({'email': email, 'password': password}),
    );

    final result = _handleResponse(response);

    // Ensure the user actually has the staff role
    if (result['user']?['role'] != 'staff' &&
        result['user']?['role'] != 'admin') {
      await clearToken();
      throw Exception('Access denied: Unauthorized role');
    }

    if (result['token'] != null) {
      await saveToken(
        result['token'],
        role: result['user']?['role'],
        name: result['user']?['name'],
      );
    }
    return result;
  }

  static Future<Map<String, dynamic>> verifyToken() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/verify'),
      headers: _getHeaders(),
    );

    final result = _handleResponse(response);
    // Update role and name from response if available
    if (result['user'] != null) {
      final prefs = await SharedPreferences.getInstance();
      if (result['user']['role'] != null) {
        await prefs.setString('user_role', result['user']['role']);
        _userRole = result['user']['role'];
      }
      if (result['user']['name'] != null) {
        await prefs.setString('user_name', result['user']['name']);
        _userName = result['user']['name'];
      }
    }
    return result;
  }

  static Future<void> logout() async {
    await clearToken();
  }

  // Product APIs
  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: _getHeaders(),
    );

    final result = _handleResponse(response);
    return result['data'] ?? [];
  }

  static Future<Map<String, dynamic>> getProductByBarcode(
    String barcode,
  ) async {
    // Check mock data first for demo purposes (to ensure images are shown)
    final mockProduct = ([
      ...mockProducts,
      ...mockRecommendations,
    ]).where((p) => p.barcode == barcode).firstOrNull;

    if (mockProduct != null) {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate network delay
      return mockProduct.toJson();
    }

    final response = await http.get(
      Uri.parse('$baseUrl/products/barcode/$barcode'),
      headers: _getHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProduct(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Transaction APIs
  static Future<Map<String, dynamic>> createTransaction({
    required List<Map<String, dynamic>> items,
    String? paymentMethod,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: _getHeaders(),
      body: json.encode({'items': items, 'payment_method': paymentMethod}),
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getTransactions({
    int limit = 20,
    int offset = 0,
    String? status,
  }) async {
    String url = '$baseUrl/transactions?limit=$limit&offset=$offset';
    if (status != null) {
      url += '&status=$status';
    }

    final response = await http.get(Uri.parse(url), headers: _getHeaders());

    final result = _handleResponse(response);
    return result['data'] ?? [];
  }

  static Future<Map<String, dynamic>> getTransaction(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: _getHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateTransactionStatus({
    required String transactionId,
    required String status,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/transactions/$transactionId/status'),
      headers: _getHeaders(),
      body: json.encode({'status': status}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyQrCode(dynamic qrData) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      if (qrData is String) {
        final decoded = json.decode(qrData);
        return {'success': true, 'data': decoded};
      }
      return {'success': true, 'data': qrData};
    } catch (e) {
      return {
        'success': false,
        'error': 'Invalid QR format. Could not parse bill data.',
      };
    }
  }

  // Health check
  static Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(
      Uri.parse('$baseUrl/health'),
      headers: _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Analytics APIs
  static Future<Map<String, dynamic>> getCustomerSegmentation() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/segmentation'),
      headers: _getHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getStatistics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/statistics'),
      headers: _getHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMarketingCampaignAnalysis({
    String? csvPath,
  }) async {
    String url = '$baseUrl/analytics/marketing-campaign';
    if (csvPath != null) {
      url += '?path=${Uri.encodeComponent(csvPath)}';
    }

    final response = await http.get(Uri.parse(url), headers: _getHeaders());

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getLowStockAlerts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/low-stock'),
      headers: _getHeaders(),
    );

    final result = _handleResponse(response);
    return result['data'] ?? [];
  }

  /// Fetches product recommendations for the current user based on their purchase history
  /// (and optionally current cart). Requires auth; returns empty list for new users with no history.
  static Future<List<dynamic>> getRecommendations({
    List<String>? currentItems,
    int limit = 10,
  }) async {
    try {
      final query = <String>['limit=$limit'];
      if (currentItems != null && currentItems.isNotEmpty) {
        query.add(
          'current_items=${Uri.encodeComponent(currentItems.join(','))}',
        );
      }
      final url = '$baseUrl/analytics/recommendations?${query.join('&')}';

      final response = await http.get(Uri.parse(url), headers: _getHeaders());
      final result = _handleResponse(response);
      final data = result['data'];
      if (data is List) return data;
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getDynamicPricing({
    String? csvPath,
  }) async {
    String url = '$baseUrl/analytics/dynamic-pricing';
    if (csvPath != null) {
      url += '?path=${Uri.encodeComponent(csvPath)}';
    }

    final response = await http.get(Uri.parse(url), headers: _getHeaders());

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPricingSuggestion(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$id/pricing-suggestion'),
      headers: _getHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> applyPricingSuggestion(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products/$id/apply-pricing'),
      headers: _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Staff Management APIs
  static Future<List<Staff>> getStaff() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/staff'),
      headers: _getHeaders(),
    );

    final result = _handleResponse(response);
    final List<dynamic> data = result['data'] ?? [];
    return data.map((s) => Staff.fromJson(s)).toList();
  }

  static Future<Map<String, dynamic>> addStaff({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/staff'),
      headers: _getHeaders(),
      body: json.encode({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteStaff(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/auth/staff/$id'),
      headers: _getHeaders(),
    );

    return _handleResponse(response);
  }
}
