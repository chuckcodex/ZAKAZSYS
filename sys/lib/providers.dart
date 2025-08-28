import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'database_helper.dart';
import 'supabase_service.dart';

// Auth Provider
class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> signUp(String email, String password, {
    String? fullName,
    String? businessName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabaseService.signUp(
        email,
        password,
        fullName: fullName,
        businessName: businessName,
      );

      if (response.user != null) {
        _currentUser = UserModel(
          id: response.user!.id,
          email: email,
          fullName: fullName,
          businessName: businessName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
    return false;
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabaseService.signIn(email, password);
      
      if (response.user != null) {
        final dbHelper = DatabaseHelper();
        _currentUser = await dbHelper.getUserById(response.user!.id);
        
        if (_currentUser == null) {
          // Create user profile if not exists
          _currentUser = UserModel(
            id: response.user!.id,
            email: email,
            fullName: response.user!.userMetadata?['full_name'],
            businessName: response.user!.userMetadata?['business_name'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await dbHelper.insertUser(_currentUser!);
        }
        
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
    return false;
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _supabaseService.signOut();
      _currentUser = null;
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  Future<void> loadCurrentUser() async {
    if (await _supabaseService.isSignedIn()) {
      final user = _supabaseService.currentUser;
      if (user != null) {
        final dbHelper = DatabaseHelper();
        _currentUser = await dbHelper.getUserById(user.id);
        notifyListeners();
      }
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}

// Category Provider
class CategoryProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SupabaseService _supabaseService = SupabaseService();
  final Uuid _uuid = const Uuid();

  List<ProductCategory> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCategories(String userId) async {
    _setLoading(true);
    try {
      _categories = await _dbHelper.getCategories(userId);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  Future<bool> createCategory({
    required String userId,
    required String name,
    String? description,
    String? color,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final category = ProductCategory(
        id: _uuid.v4(),
        userId: userId,
        name: name,
        description: description,
        color: color,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supabaseService.createCategory(category);
      _categories.add(category);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateCategory(ProductCategory category) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedCategory = ProductCategory(
        id: category.id,
        userId: category.userId,
        name: category.name,
        description: category.description,
        color: category.color,
        createdAt: category.createdAt,
        updatedAt: DateTime.now(),
      );

      await _supabaseService.updateCategory(updatedCategory);
      
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabaseService.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}

// Product Provider
class ProductProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SupabaseService _supabaseService = SupabaseService();
  final Uuid _uuid = const Uuid();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Product> getProductsByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  Future<void> loadProducts(String userId, {String? categoryId}) async {
    _setLoading(true);
    try {
      _products = await _dbHelper.getProducts(userId, categoryId: categoryId);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  Future<bool> createProduct({
    required String userId,
    required String categoryId,
    required String name,
    String? description,
    required double price,
    required int stockQuantity,
    String? imageUrl,
    String? sku,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final product = Product(
        id: _uuid.v4(),
        userId: userId,
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
        stockQuantity: stockQuantity,
        imageUrl: imageUrl,
        sku: sku,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supabaseService.createProduct(product);
      _products.add(product);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedProduct = Product(
        id: product.id,
        userId: product.userId,
        categoryId: product.categoryId,
        name: product.name,
        description: product.description,
        price: product.price,
        stockQuantity: product.stockQuantity,
        imageUrl: product.imageUrl,
        sku: product.sku,
        isActive: product.isActive,
        createdAt: product.createdAt,
        updatedAt: DateTime.now(),
      );

      await _supabaseService.updateProduct(updatedProduct);
      
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabaseService.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}

// Cart Provider
class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  String? _customerName;
  String? _customerPhone;
  double _taxRate = 0.0;
  double _discountAmount = 0.0;

  List<CartItem> get items => _items;
  String? get customerName => _customerName;
  String? get customerPhone => _customerPhone;
  double get taxRate => _taxRate;
  double get discountAmount => _discountAmount;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  
  double get taxAmount => subtotal * _taxRate / 100;
  
  double get total => subtotal + taxAmount - _discountAmount;

  bool get isEmpty => _items.isEmpty;

  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex != -1) {
      _items[existingIndex] = CartItem(
        product: product,
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _items[index] = CartItem(
        product: _items[index].product,
        quantity: quantity,
      );
      notifyListeners();
    }
  }

  void setCustomerInfo({String? name, String? phone}) {
    _customerName = name;
    _customerPhone = phone;
    notifyListeners();
  }

  void setTaxRate(double rate) {
    _taxRate = rate;
    notifyListeners();
  }

  void setDiscount(double amount) {
    _discountAmount = amount;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _customerName = null;
    _customerPhone = null;
    _taxRate = 0.0;
    _discountAmount = 0.0;
    notifyListeners();
  }
}

// Order Provider
class OrderProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SupabaseService _supabaseService = SupabaseService();
  final Uuid _uuid = const Uuid();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadOrders(String userId, {DateTime? startDate, DateTime? endDate}) async {
    _setLoading(true);
    try {
      _orders = await _dbHelper.getOrders(userId, startDate: startDate, endDate: endDate);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  Future<bool> createOrder({
    required String userId,
    required List<CartItem> cartItems,
    String? customerName,
    String? customerPhone,
    double taxAmount = 0,
    double discountAmount = 0,
    required String paymentMethod,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final orderId = _uuid.v4();
      final now = DateTime.now();
      
      final orderItems = cartItems.map((cartItem) => OrderItem(
        id: _uuid.v4(),
        orderId: orderId,
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        unitPrice: cartItem.product.price,
        quantity: cartItem.quantity,
        totalPrice: cartItem.totalPrice,
      )).toList();

      final totalAmount = orderItems.fold(0.0, (sum, item) => sum + item.totalPrice) + taxAmount - discountAmount;

      final order = Order(
        id: orderId,
        userId: userId,
        customerName: customerName,
        customerPhone: customerPhone,
        totalAmount: totalAmount,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        paymentMethod: paymentMethod,
        items: orderItems,
        createdAt: now,
        updatedAt: now,
      );

      await _supabaseService.createOrder(order);
      _orders.insert(0, order);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>> getSalesAnalytics(String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _dbHelper.getSalesAnalytics(userId, startDate: startDate, endDate: endDate);
    } catch (e) {
      _setError(e.toString());
      return {};
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}