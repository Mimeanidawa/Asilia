class AdminProduct {
  const AdminProduct({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.discountPercent,
    required this.imageUrl,
    required this.badgeText,
    required this.stockQuantity,
    required this.category,
    required this.benefits,
    this.howToUse = '',
    required this.isPublished,
    this.createdAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int price;
  final int originalPrice;
  final int discountPercent;
  final String imageUrl;
  final String badgeText;
  final int stockQuantity;
  final String category;
  final List<String> benefits;
  final String howToUse;
  final bool isPublished;
  final DateTime? createdAt;

  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    return AdminProduct(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      originalPrice: (json['originalPrice'] ?? json['original_price'] as num?)?.toInt() ?? 0,
      discountPercent: (json['discountPercent'] ?? json['discount_percent'] as num?)?.toInt() ?? 50,
      imageUrl: json['imageUrl'] ?? json['image_url'] as String? ?? '',
      badgeText: json['badgeText'] ?? json['badge_text'] as String? ?? 'PUNGUZO LA 50% 🔥',
      stockQuantity: (json['stockQuantity'] ?? json['stock_quantity'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'general',
      benefits: json['benefits'] is List
          ? (json['benefits'] as List).map((e) => e.toString()).toList()
          : [],
      howToUse: json['howToUse'] ?? json['how_to_use'] as String? ?? '',
      isPublished: json['isPublished'] ?? json['is_published'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'price': price,
        'originalPrice': originalPrice,
        'discountPercent': discountPercent,
        'imageUrl': imageUrl,
        'badgeText': badgeText,
        'stockQuantity': stockQuantity,
        'category': category,
        'benefits': benefits,
        'howToUse': howToUse,
        'isPublished': isPublished,
      };
}

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.receiptNumber,
    this.userId,
    required this.productId,
    required this.productTitle,
    required this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    this.transferFee = 12000,
    required this.totalAmount,
    required this.customerName,
    required this.customerPhone,
    required this.region,
    required this.district,
    required this.ward,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryStatus,
    this.trackingInfo = '',
    this.adminNotes = '',
    required this.createdAt,
  });

  final String id;
  final String receiptNumber;
  final String? userId;
  final String productId;
  final String productTitle;
  final String productImageUrl;
  final int unitPrice;
  final int quantity;
  final int transferFee;
  final int totalAmount;
  final String customerName;
  final String customerPhone;
  final String region;
  final String district;
  final String ward;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryStatus; // 'pending', 'on_transit', 'delivered'
  final String trackingInfo;
  final String adminNotes;
  final DateTime createdAt;

  int get itemsTotal => unitPrice * quantity;

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    return AdminOrder(
      id: json['id'] as String? ?? '',
      receiptNumber: json['receiptNumber'] ?? json['receipt_number'] as String? ?? '',
      userId: json['userId'] ?? json['user_id'] as String?,
      productId: json['productId'] ?? json['product_id'] as String? ?? '',
      productTitle: json['productTitle'] ?? json['product_title'] as String? ?? 'Dawa ya Asili',
      productImageUrl: json['productImageUrl'] ?? json['product_image_url'] as String? ?? '',
      unitPrice: (json['unitPrice'] ?? json['unit_price'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      transferFee: (json['transferFee'] ?? json['transfer_fee'] as num?)?.toInt() ?? 12000,
      totalAmount: (json['totalAmount'] ?? json['total_amount'] as num?)?.toInt() ?? 0,
      customerName: json['customerName'] ?? json['customer_name'] as String? ?? 'Mteja',
      customerPhone: json['customerPhone'] ?? json['customer_phone'] as String? ?? '',
      region: json['region'] as String? ?? 'Tanzania',
      district: json['district'] as String? ?? '',
      ward: json['ward'] as String? ?? '',
      paymentMethod: json['paymentMethod'] ?? json['payment_method'] as String? ?? 'M-Pesa',
      paymentStatus: json['paymentStatus'] ?? json['payment_status'] as String? ?? 'paid',
      deliveryStatus: json['deliveryStatus'] ?? json['delivery_status'] as String? ?? 'pending',
      trackingInfo: json['trackingInfo'] ?? json['tracking_info'] as String? ?? '',
      adminNotes: json['adminNotes'] ?? json['admin_notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
