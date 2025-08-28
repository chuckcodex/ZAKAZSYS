import 'package:equatable/equatable.dart';

// User Model
class UserModel extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? businessName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.businessName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      businessName: json['business_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'business_name': businessName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, email, fullName, businessName, createdAt, updatedAt];
}

// Product Category Model
class ProductCategory extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductCategory({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      color: json['color'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSqflite() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'color': color,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ProductCategory.fromSqflite(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      description: map['description'],
      color: map['color'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, userId, name, description, color, createdAt, updatedAt];
}

// Product Model
class Product extends Equatable {
  final String id;
  final String userId;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final String? imageUrl;
  final String? sku;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    this.imageUrl,
    this.sku,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      stockQuantity: json['stock_quantity'],
      imageUrl: json['image_url'],
      sku: json['sku'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'stock_quantity': stockQuantity,
      'image_url': imageUrl,
      'sku': sku,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSqflite() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'stock_quantity': stockQuantity,
      'image_url': imageUrl,
      'sku': sku,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Product.fromSqflite(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      userId: map['user_id'],
      categoryId: map['category_id'],
      name: map['name'],
      description: map['description'],
      price: (map['price'] as num).toDouble(),
      stockQuantity: map['stock_quantity'],
      imageUrl: map['image_url'],
      sku: map['sku'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
        id, userId, categoryId, name, description, price,
        stockQuantity, imageUrl, sku, isActive, createdAt, updatedAt
      ];
}

// Order Model
class Order extends Equatable {
  final String id;
  final String userId;
  final String? customerName;
  final String? customerPhone;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final String paymentMethod;
  final String status;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.userId,
    this.customerName,
    this.customerPhone,
    required this.totalAmount,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.paymentMethod,
    this.status = 'completed',
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'],
      status: json['status'] ?? 'completed',
      items: (json['items'] as List?)?.map((e) => OrderItem.fromJson(e)).toList() ?? [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_amount': totalAmount,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSqflite() {
    return {
      'id': id,
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_amount': totalAmount,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Order.fromSqflite(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      userId: map['user_id'],
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
      totalAmount: (map['total_amount'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'],
      status: map['status'] ?? 'completed',
      items: const [], // Items loaded separately
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
        id, userId, customerName, customerPhone, totalAmount,
        taxAmount, discountAmount, paymentMethod, status, items, createdAt, updatedAt
      ];
}

// Order Item Model
class OrderItem extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double totalPrice;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'],
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'total_price': totalPrice,
    };
  }

  Map<String, dynamic> toSqflite() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'total_price': totalPrice,
    };
  }

  factory OrderItem.fromSqflite(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      unitPrice: (map['unit_price'] as num).toDouble(),
      quantity: map['quantity'],
      totalPrice: (map['total_price'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, orderId, productId, productName, unitPrice, quantity, totalPrice];
}

// Cart Item Model (for temporary cart storage)
class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}