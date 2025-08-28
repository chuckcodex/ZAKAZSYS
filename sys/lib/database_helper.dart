import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_system.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        full_name TEXT,
        business_name TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create product_categories table
    await db.execute('''
      CREATE TABLE product_categories (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        color TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        image_url TEXT,
        sku TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES product_categories (id) ON DELETE CASCADE
      )
    ''');

    // Create orders table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        total_amount REAL NOT NULL,
        tax_amount REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'completed',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create order_items table
    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        total_price REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_products_category ON products(category_id)');
    await db.execute('CREATE INDEX idx_products_user ON products(user_id)');
    await db.execute('CREATE INDEX idx_orders_user ON orders(user_id)');
    await db.execute('CREATE INDEX idx_orders_date ON orders(created_at)');
    await db.execute('CREATE INDEX idx_order_items_order ON order_items(order_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  // User operations
  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'id': user.id,
        'email': user.email,
        'full_name': user.fullName,
        'business_name': user.businessName,
        'created_at': user.createdAt.millisecondsSinceEpoch,
        'updated_at': user.updatedAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    
    if (maps.isNotEmpty) {
      final map = maps.first;
      return UserModel(
        id: map['id'] as String,
        email: map['email'] as String,
        fullName: map['full_name'] as String?,
        businessName: map['business_name'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
    }
    return null;
  }

  // Product Category operations
  Future<void> insertCategory(ProductCategory category) async {
    final db = await database;
    await db.insert('product_categories', category.toSqflite(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ProductCategory>> getCategories(String userId) async {
    final db = await database;
    final maps = await db.query(
      'product_categories',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => ProductCategory.fromSqflite(map)).toList();
  }

  Future<void> updateCategory(ProductCategory category) async {
    final db = await database;
    await db.update(
      'product_categories',
      category.toSqflite(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    final db = await database;
    await db.delete(
      'product_categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  // Product operations
  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert('products', product.toSqflite(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getProducts(String userId, {String? categoryId}) async {
    final db = await database;
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];
    
    if (categoryId != null) {
      whereClause += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    final maps = await db.query(
      'products',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((map) => Product.fromSqflite(map)).toList();
  }

  Future<Product?> getProductById(String productId) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (maps.isNotEmpty) {
      return Product.fromSqflite(maps.first);
    }
    return null;
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.toSqflite(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String productId) async {
    final db = await database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> updateProductStock(String productId, int newQuantity) async {
    final db = await database;
    await db.update(
      'products',
      {'stock_quantity': newQuantity, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Order operations
  Future<void> insertOrder(Order order) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Insert order
      await txn.insert('orders', order.toSqflite());
      
      // Insert order items
      for (final item in order.items) {
        await txn.insert('order_items', item.toSqflite());
      }
      
      // Update product stock
      for (final item in order.items) {
        final product = await getProductById(item.productId);
        if (product != null) {
          final newStock = product.stockQuantity - item.quantity;
          await txn.update(
            'products',
            {
              'stock_quantity': newStock,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }
      }
    });
  }

  Future<List<Order>> getOrders(String userId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];
    
    if (startDate != null) {
      whereClause += ' AND created_at >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    
    if (endDate != null) {
      whereClause += ' AND created_at <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final orderMaps = await db.query(
      'orders',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    List<Order> orders = [];
    for (final orderMap in orderMaps) {
      final order = Order.fromSqflite(orderMap);
      
      // Get order items
      final itemMaps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [order.id],
      );
      
      final items = itemMaps.map((map) => OrderItem.fromSqflite(map)).toList();
      
      orders.add(Order(
        id: order.id,
        userId: order.userId,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        totalAmount: order.totalAmount,
        taxAmount: order.taxAmount,
        discountAmount: order.discountAmount,
        paymentMethod: order.paymentMethod,
        status: order.status,
        items: items,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
      ));
    }

    return orders;
  }

  Future<Order?> getOrderById(String orderId) async {
    final db = await database;
    
    final orderMaps = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
    if (orderMaps.isEmpty) return null;
    
    final order = Order.fromSqflite(orderMaps.first);
    
    // Get order items
    final itemMaps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [order.id],
    );
    
    final items = itemMaps.map((map) => OrderItem.fromSqflite(map)).toList();
    
    return Order(
      id: order.id,
      userId: order.userId,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      totalAmount: order.totalAmount,
      taxAmount: order.taxAmount,
      discountAmount: order.discountAmount,
      paymentMethod: order.paymentMethod,
      status: order.status,
      items: items,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );
  }

  // Analytics queries
  Future<Map<String, dynamic>> getSalesAnalytics(String userId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];
    
    if (startDate != null) {
      whereClause += ' AND created_at >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    
    if (endDate != null) {
      whereClause += ' AND created_at <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_orders,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as average_order_value,
        SUM(tax_amount) as total_tax,
        SUM(discount_amount) as total_discount
      FROM orders 
      WHERE $whereClause
    ''', whereArgs);

    return result.first;
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('order_items');
    await db.delete('orders');
    await db.delete('products');
    await db.delete('product_categories');
    await db.delete('users');
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}