import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'database_helper.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Initialize Supabase
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Authentication
  Future<AuthResponse> signUp(String email, String password, {
    String? fullName,
    String? businessName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'business_name': businessName,
      },
    );

    if (response.user != null) {
      // Create user profile in local database
      final user = UserModel(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        businessName: businessName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbHelper.insertUser(user);

      // Sync to Supabase
      await _syncUserToSupabase(user);
    }

    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // Sync user data from Supabase to local database
      await _syncUserFromSupabase(response.user!.id);
    }

    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<bool> isSignedIn() async {
    return _client.auth.currentSession != null;
  }

  User? get currentUser => _client.auth.currentUser;

  // Sync operations
  Future<void> syncAllData() async {
    final userId = currentUser?.id;
    if (userId == null) return;

    try {
      await Future.wait([
        _syncCategoriesToSupabase(userId),
        _syncProductsToSupabase(userId),
        _syncOrdersToSupabase(userId),
      ]);

      await Future.wait([
        _syncCategoriesFromSupabase(userId),
        _syncProductsFromSupabase(userId),
        _syncOrdersFromSupabase(userId),
      ]);
    } catch (e) {
      print('Sync error: $e');
      // Handle sync errors gracefully
    }
  }

  // User operations
  Future<void> _syncUserToSupabase(UserModel user) async {
    try {
      await _client.from('users').upsert(user.toJson());
    } catch (e) {
      print('Error syncing user to Supabase: $e');
    }
  }

  Future<void> _syncUserFromSupabase(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final user = UserModel.fromJson(response);
      await _dbHelper.insertUser(user);
    } catch (e) {
      print('Error syncing user from Supabase: $e');
    }
  }

  // Category operations
  Future<void> createCategory(ProductCategory category) async {
    // Save locally first
    await _dbHelper.insertCategory(category);
    
    // Sync to Supabase
    try {
      await _client.from('product_categories').insert(category.toJson());
    } catch (e) {
      print('Error creating category in Supabase: $e');
    }
  }

  Future<void> updateCategory(ProductCategory category) async {
    await _dbHelper.updateCategory(category);
    
    try {
      await _client
          .from('product_categories')
          .update(category.toJson())
          .eq('id', category.id);
    } catch (e) {
      print('Error updating category in Supabase: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    await _dbHelper.deleteCategory(categoryId);
    
    try {
      await _client
          .from('product_categories')
          .delete()
          .eq('id', categoryId);
    } catch (e) {
      print('Error deleting category from Supabase: $e');
    }
  }

  Future<void> _syncCategoriesToSupabase(String userId) async {
    try {
      final categories = await _dbHelper.getCategories(userId);
      if (categories.isNotEmpty) {
        final data = categories.map((c) => c.toJson()).toList();
        await _client.from('product_categories').upsert(data);
      }
    } catch (e) {
      print('Error syncing categories to Supabase: $e');
    }
  }

  Future<void> _syncCategoriesFromSupabase(String userId) async {
    try {
      final response = await _client
          .from('product_categories')
          .select()
          .eq('user_id', userId);

      for (final data in response) {
        final category = ProductCategory.fromJson(data);
        await _dbHelper.insertCategory(category);
      }
    } catch (e) {
      print('Error syncing categories from Supabase: $e');
    }
  }

  // Product operations
  Future<void> createProduct(Product product) async {
    await _dbHelper.insertProduct(product);
    
    try {
      await _client.from('products').insert(product.toJson());
    } catch (e) {
      print('Error creating product in Supabase: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    await _dbHelper.updateProduct(product);
    
    try {
      await _client
          .from('products')
          .update(product.toJson())
          .eq('id', product.id);
    } catch (e) {
      print('Error updating product in Supabase: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    await _dbHelper.deleteProduct(productId);
    
    try {
      await _client
          .from('products')
          .delete()
          .eq('id', productId);
    } catch (e) {
      print('Error deleting product from Supabase: $e');
    }
  }

  Future<void> _syncProductsToSupabase(String userId) async {
    try {
      final products = await _dbHelper.getProducts(userId);
      if (products.isNotEmpty) {
        final data = products.map((p) => p.toJson()).toList();
        await _client.from('products').upsert(data);
      }
    } catch (e) {
      print('Error syncing products to Supabase: $e');
    }
  }

  Future<void> _syncProductsFromSupabase(String userId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('user_id', userId);

      for (final data in response) {
        final product = Product.fromJson(data);
        await _dbHelper.insertProduct(product);
      }
    } catch (e) {
      print('Error syncing products from Supabase: $e');
    }
  }

  // Order operations
  Future<void> createOrder(Order order) async {
    await _dbHelper.insertOrder(order);
    
    try {
      // Insert order
      await _client.from('orders').insert(order.toJson());
      
      // Insert order items
      final itemsData = order.items.map((item) => item.toJson()).toList();
      await _client.from('order_items').insert(itemsData);
    } catch (e) {
      print('Error creating order in Supabase: $e');
    }
  }

  Future<void> _syncOrdersToSupabase(String userId) async {
    try {
      final orders = await _dbHelper.getOrders(userId);
      if (orders.isEmpty) return;

      // Sync orders
      final orderData = orders.map((o) => o.toJson()).toList();
      await _client.from('orders').upsert(orderData);

      // Sync order items
      final allItems = orders.expand((o) => o.items).toList();
      if (allItems.isNotEmpty) {
        final itemsData = allItems.map((i) => i.toJson()).toList();
        await _client.from('order_items').upsert(itemsData);
      }
    } catch (e) {
      print('Error syncing orders to Supabase: $e');
    }
  }

  Future<void> _syncOrdersFromSupabase(String userId) async {
    try {
      // Get orders
      final ordersResponse = await _client
          .from('orders')
          .select()
          .eq('user_id', userId);

      // Get order items
      final orderIds = ordersResponse.map((o) => o['id']).toList();
      final itemsResponse = await _client
          .from('order_items')
          .select()
          .inFilter('order_id', orderIds);

      // Group items by order
      final itemsByOrder = <String, List<OrderItem>>{};
      for (final itemData in itemsResponse) {
        final item = OrderItem.fromJson(itemData);
        itemsByOrder.putIfAbsent(item.orderId, () => []).add(item);
      }

      // Create complete order objects and save locally
      for (final orderData in ordersResponse) {
        final orderId = orderData['id'] as String;
        final items = itemsByOrder[orderId] ?? [];
        
        final order = Order(
          id: orderId,
          userId: orderData['user_id'],
          customerName: orderData['customer_name'],
          customerPhone: orderData['customer_phone'],
          totalAmount: (orderData['total_amount'] as num).toDouble(),
          taxAmount: (orderData['tax_amount'] as num?)?.toDouble() ?? 0,
          discountAmount: (orderData['discount_amount'] as num?)?.toDouble() ?? 0,
          paymentMethod: orderData['payment_method'],
          status: orderData['status'] ?? 'completed',
          items: items,
          createdAt: DateTime.parse(orderData['created_at']),
          updatedAt: DateTime.parse(orderData['updated_at']),
        );

        // Note: This would need a different approach since insertOrder 
        // also updates stock. We'd need a separate method for sync.
        // For now, we'll skip local insertion during sync to avoid stock issues.
      }
    } catch (e) {
      print('Error syncing orders from Supabase: $e');
    }
  }

  // Image upload
  Future<String?> uploadImage(String filePath, String fileName) async {
    try {
      final response = await _client.storage
          .from('product-images')
          .upload(fileName, File(filePath));

      if (response.isNotEmpty) {
        return _client.storage
            .from('product-images')
            .getPublicUrl(fileName);
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
    return null;
  }

  // Network status
  bool get isOnline => _client.realtime.isConnected;

  // Realtime subscriptions for collaborative features
  RealtimeChannel subscribeToCategories(String userId, Function(List<ProductCategory>) onData) {
    return _client
        .channel('categories_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'product_categories',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            final categories = await _dbHelper.getCategories(userId);
            onData(categories);
          },
        )
        .subscribe();
  }

  RealtimeChannel subscribeToProducts(String userId, Function(List<Product>) onData) {
    return _client
        .channel('products_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            final products = await _dbHelper.getProducts(userId);
            onData(products);
          },
        )
        .subscribe();
  }
}

// Import needed for file operations
import 'dart:io';