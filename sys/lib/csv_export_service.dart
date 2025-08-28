import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'database_helper.dart';

class CSVExportService {
  static final CSVExportService _instance = CSVExportService._internal();
  factory CSVExportService() => _instance;
  CSVExportService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  final DateFormat _fileNameFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');

  // Export orders to CSV
  Future<String?> exportOrdersToCSV({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? customFileName,
  }) async {
    try {
      // Request storage permission
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      // Get orders data
      final orders = await _dbHelper.getOrders(userId, startDate: startDate, endDate: endDate);
      
      if (orders.isEmpty) {
        throw Exception('No orders found for the selected period');
      }

      // Prepare CSV data
      final csvData = _prepareOrdersCSVData(orders);

      // Generate file name
      final fileName = customFileName ?? _generateFileName('orders_export', 'csv');

      // Write CSV file
      final filePath = await _writeCSVFile(csvData, fileName);
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to export orders: $e');
    }
  }

  // Export order items to CSV (detailed view)
  Future<String?> exportOrderItemsToCSV({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? customFileName,
  }) async {
    try {
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      final orders = await _dbHelper.getOrders(userId, startDate: startDate, endDate: endDate);
      
      if (orders.isEmpty) {
        throw Exception('No orders found for the selected period');
      }

      // Prepare detailed CSV data
      final csvData = _prepareOrderItemsCSVData(orders);

      final fileName = customFileName ?? _generateFileName('order_items_export', 'csv');
      final filePath = await _writeCSVFile(csvData, fileName);
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to export order items: $e');
    }
  }

  // Export sales summary to CSV
  Future<String?> exportSalesSummaryToCSV({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? customFileName,
  }) async {
    try {
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      final orders = await _dbHelper.getOrders(userId, startDate: startDate, endDate: endDate);
      final analytics = await _dbHelper.getSalesAnalytics(userId, startDate: startDate, endDate: endDate);
      
      if (orders.isEmpty) {
        throw Exception('No sales data found for the selected period');
      }

      // Prepare summary CSV data
      final csvData = _prepareSalesSummaryCSVData(orders, analytics);

      final fileName = customFileName ?? _generateFileName('sales_summary', 'csv');
      final filePath = await _writeCSVFile(csvData, fileName);
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to export sales summary: $e');
    }
  }

  // Export products to CSV
  Future<String?> exportProductsToCSV({
    required String userId,
    String? customFileName,
  }) async {
    try {
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      final products = await _dbHelper.getProducts(userId);
      final categories = await _dbHelper.getCategories(userId);
      
      if (products.isEmpty) {
        throw Exception('No products found');
      }

      // Create category lookup map
      final categoryMap = {for (var cat in categories) cat.id: cat.name};

      // Prepare products CSV data
      final csvData = _prepareProductsCSVData(products, categoryMap);

      final fileName = customFileName ?? _generateFileName('products_export', 'csv');
      final filePath = await _writeCSVFile(csvData, fileName);
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to export products: $e');
    }
  }

  // Share CSV file
  Future<void> shareCSVFile(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'POS System Export',
        text: 'Here is your exported data from the POS system.',
      );
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  // Prepare orders CSV data
  List<List<dynamic>> _prepareOrdersCSVData(List<Order> orders) {
    final List<List<dynamic>> csvData = [];
    
    // Headers
    csvData.add([
      'Order ID',
      'Date',
      'Customer Name',
      'Customer Phone',
      'Total Items',
      'Subtotal',
      'Tax Amount',
      'Discount Amount',
      'Total Amount',
      'Payment Method',
      'Status'
    ]);

    // Data rows
    for (final order in orders) {
      final totalItems = order.items.fold(0, (sum, item) => sum + item.quantity);
      final subtotal = order.totalAmount - order.taxAmount + order.discountAmount;
      
      csvData.add([
        order.id,
        _dateFormat.format(order.createdAt),
        order.customerName ?? 'Walk-in Customer',
        order.customerPhone ?? '',
        totalItems,
        subtotal.toStringAsFixed(2),
        order.taxAmount.toStringAsFixed(2),
        order.discountAmount.toStringAsFixed(2),
        order.totalAmount.toStringAsFixed(2),
        order.paymentMethod,
        order.status,
      ]);
    }

    return csvData;
  }

  // Prepare order items CSV data
  List<List<dynamic>> _prepareOrderItemsCSVData(List<Order> orders) {
    final List<List<dynamic>> csvData = [];
    
    // Headers
    csvData.add([
      'Order ID',
      'Order Date',
      'Customer Name',
      'Product Name',
      'Unit Price',
      'Quantity',
      'Item Total',
      'Payment Method'
    ]);

    // Data rows
    for (final order in orders) {
      for (final item in order.items) {
        csvData.add([
          order.id,
          _dateFormat.format(order.createdAt),
          order.customerName ?? 'Walk-in Customer',
          item.productName,
          item.unitPrice.toStringAsFixed(2),
          item.quantity,
          item.totalPrice.toStringAsFixed(2),
          order.paymentMethod,
        ]);
      }
    }

    return csvData;
  }

  // Prepare sales summary CSV data
  List<List<dynamic>> _prepareSalesSummaryCSVData(List<Order> orders, Map<String, dynamic> analytics) {
    final List<List<dynamic>> csvData = [];
    
    // Summary section
    csvData.add(['SALES SUMMARY REPORT']);
    csvData.add(['Generated on:', _dateFormat.format(DateTime.now())]);
    csvData.add([]);
    
    // Analytics
    csvData.add(['ANALYTICS']);
    csvData.add(['Total Orders:', analytics['total_orders'] ?? 0]);
    csvData.add(['Total Revenue:', '${(analytics['total_revenue'] ?? 0).toStringAsFixed(2)}']);
    csvData.add(['Average Order Value:', '${(analytics['average_order_value'] ?? 0).toStringAsFixed(2)}']);
    csvData.add(['Total Tax Collected:', '${(analytics['total_tax'] ?? 0).toStringAsFixed(2)}']);
    csvData.add(['Total Discounts Given:', '${(analytics['total_discount'] ?? 0).toStringAsFixed(2)}']);
    csvData.add([]);

    // Daily sales breakdown
    final dailySales = _groupOrdersByDate(orders);
    csvData.add(['DAILY SALES BREAKDOWN']);
    csvData.add(['Date', 'Orders Count', 'Total Revenue']);
    
    for (final entry in dailySales.entries) {
      final dayOrders = entry.value;
      final dayRevenue = dayOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
      csvData.add([
        entry.key,
        dayOrders.length,
        dayRevenue.toStringAsFixed(2),
      ]);
    }
    csvData.add([]);

    // Payment methods breakdown
    final paymentMethods = _groupOrdersByPaymentMethod(orders);
    csvData.add(['PAYMENT METHODS BREAKDOWN']);
    csvData.add(['Payment Method', 'Orders Count', 'Total Amount']);
    
    for (final entry in paymentMethods.entries) {
      final methodOrders = entry.value;
      final methodRevenue = methodOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
      csvData.add([
        entry.key,
        methodOrders.length,
        methodRevenue.toStringAsFixed(2),
      ]);
    }
    csvData.add([]);

    // Top products
    final topProducts = _getTopProducts(orders);
    csvData.add(['TOP SELLING PRODUCTS']);
    csvData.add(['Product Name', 'Quantity Sold', 'Total Revenue']);
    
    for (final product in topProducts.take(10)) {
      csvData.add([
        product['name'],
        product['quantity'],
        product['revenue'].toStringAsFixed(2),
      ]);
    }

    return csvData;
  }

  // Prepare products CSV data
  List<List<dynamic>> _prepareProductsCSVData(List<Product> products, Map<String, String> categoryMap) {
    final List<List<dynamic>> csvData = [];
    
    // Headers
    csvData.add([
      'Product ID',
      'Name',
      'Category',
      'Description',
      'Price',
      'Stock Quantity',
      'SKU',
      'Is Active',
      'Created Date',
      'Updated Date'
    ]);

    // Data rows
    for (final product in products) {
      csvData.add([
        product.id,
        product.name,
        categoryMap[product.categoryId] ?? 'Unknown Category',
        product.description ?? '',
        product.price.toStringAsFixed(2),
        product.stockQuantity,
        product.sku ?? '',
        product.isActive ? 'Yes' : 'No',
        _dateFormat.format(product.createdAt),
        _dateFormat.format(product.updatedAt),
      ]);
    }

    return csvData;
  }

  // Helper methods
  Map<String, List<Order>> _groupOrdersByDate(List<Order> orders) {
    final Map<String, List<Order>> grouped = {};
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    for (final order in orders) {
      final dateKey = dateFormat.format(order.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(order);
    }
    
    return Map.fromEntries(grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  Map<String, List<Order>> _groupOrdersByPaymentMethod(List<Order> orders) {
    final Map<String, List<Order>> grouped = {};
    
    for (final order in orders) {
      grouped.putIfAbsent(order.paymentMethod, () => []).add(order);
    }
    
    return grouped;
  }

  List<Map<String, dynamic>> _getTopProducts(List<Order> orders) {
    final Map<String, Map<String, dynamic>> productStats = {};
    
    for (final order in orders) {
      for (final item in order.items) {
        if (productStats.containsKey(item.productName)) {
          productStats[item.productName]!['quantity'] += item.quantity;
          productStats[item.productName]!['revenue'] += item.totalPrice;
        } else {
          productStats[item.productName] = {
            'name': item.productName,
            'quantity': item.quantity,
            'revenue': item.totalPrice,
          };
        }
      }
    }
    
    final sortedProducts = productStats.values.toList()
      ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
    
    return sortedProducts;
  }

  // File operations
  Future<String> _writeCSVFile(List<List<dynamic>> csvData, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      
      final csvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csvString);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to write CSV file: $e');
    }
  }

  String _generateFileName(String prefix, String extension) {
    final timestamp = _fileNameFormat.format(DateTime.now());
    return '${prefix}_$timestamp.$extension';
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status == PermissionStatus.granted;
    }
    return true; // iOS doesn't need explicit storage permission for app documents
  }

  // Utility method to get file size in human readable format
  Future<String> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown size';
    }
  }

  // Clean up old export files (optional)
  Future<void> cleanupOldExports({int maxAgeInDays = 30}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.csv')) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Handle cleanup errors silently
      print('Error cleaning up old exports: $e');
    }
  }
}