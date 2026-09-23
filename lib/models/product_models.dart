class DawaProduct {
  const DawaProduct({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.description,
    required this.price,
    required this.originalPrice,
    this.discountPercent = 50,
    required this.imageUrl,
    this.badgeText = 'PUNGUZO LA HADI 50% 🔥',
    this.stockQuantity = 100,
    this.category = 'dawa_asili',
    this.benefits = const [],
    this.howToUse = '',
    this.isAvailable = true,
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
  final bool isAvailable;

  int get savings => originalPrice - price;

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
        'isAvailable': isAvailable,
      };

  factory DawaProduct.fromJson(Map<String, dynamic> json) => DawaProduct(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        description: json['description'] as String? ?? '',
        price: (json['price'] as num?)?.toInt() ?? 25000,
        originalPrice: (json['originalPrice'] as num?)?.toInt() ?? 50000,
        discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 50,
        imageUrl: json['imageUrl'] as String? ?? '',
        badgeText: json['badgeText'] as String? ?? 'PUNGUZO LA HADI 50% 🔥',
        stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 100,
        category: json['category'] as String? ?? 'dawa_asili',
        benefits: (json['benefits'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        howToUse: json['howToUse'] as String? ?? '',
        isAvailable: json['isAvailable'] as bool? ?? true,
      );
}

enum DawaDeliveryStatus { pending, onTransit, delivered }

class DawaOrder {
  const DawaOrder({
    required this.id,
    required this.receiptNumber,
    this.userId,
    required this.productId,
    required this.productTitle,
    required this.productImageUrl,
    required this.unitPrice,
    required this.originalPrice,
    this.quantity = 1,
    required this.totalAmount,
    required this.customerName,
    required this.customerPhone,
    required this.region,
    required this.district,
    required this.ward,
    this.paymentMethod = 'M-Pesa',
    this.paymentStatus = 'paid',
    this.paymentReference = '',
    this.deliveryStatus = DawaDeliveryStatus.pending,
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
  final int originalPrice;
  final int quantity;
  final int totalAmount;
  final String customerName;
  final String customerPhone;
  final String region;
  final String district;
  final String ward;
  final String paymentMethod;
  final String paymentStatus;
  final String paymentReference;
  final DawaDeliveryStatus deliveryStatus;
  final String trackingInfo;
  final String adminNotes;
  final DateTime createdAt;

  String get deliveryStatusLabel {
    switch (deliveryStatus) {
      case DawaDeliveryStatus.pending:
        return 'Inasubiri Maandalizi';
      case DawaDeliveryStatus.onTransit:
        return 'Iko Safarini';
      case DawaDeliveryStatus.delivered:
        return 'Imepokelewa';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiptNumber': receiptNumber,
        'userId': userId,
        'productId': productId,
        'productTitle': productTitle,
        'productImageUrl': productImageUrl,
        'unitPrice': unitPrice,
        'originalPrice': originalPrice,
        'quantity': quantity,
        'totalAmount': totalAmount,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'region': region,
        'district': district,
        'ward': ward,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'paymentReference': paymentReference,
        'deliveryStatus': deliveryStatus.name,
        'trackingInfo': trackingInfo,
        'adminNotes': adminNotes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DawaOrder.fromJson(Map<String, dynamic> json) => DawaOrder(
        id: json['id'] as String,
        receiptNumber: json['receiptNumber'] as String,
        userId: json['userId'] as String?,
        productId: json['productId'] as String,
        productTitle: json['productTitle'] as String,
        productImageUrl: json['productImageUrl'] as String? ?? '',
        unitPrice: (json['unitPrice'] as num).toInt(),
        originalPrice: (json['originalPrice'] as num?)?.toInt() ?? (json['unitPrice'] as num).toInt() * 2,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        totalAmount: (json['totalAmount'] as num).toInt(),
        customerName: json['customerName'] as String,
        customerPhone: json['customerPhone'] as String,
        region: json['region'] as String,
        district: json['district'] as String,
        ward: json['ward'] as String,
        paymentMethod: json['paymentMethod'] as String? ?? 'M-Pesa',
        paymentStatus: json['paymentStatus'] as String? ?? 'paid',
        paymentReference: json['paymentReference'] as String? ?? '',
        deliveryStatus: DawaDeliveryStatus.values.firstWhere(
          (e) => e.name == json['deliveryStatus'],
          orElse: () => DawaDeliveryStatus.pending,
        ),
        trackingInfo: json['trackingInfo'] as String? ?? '',
        adminNotes: json['adminNotes'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  DawaOrder copyWith({
    DawaDeliveryStatus? deliveryStatus,
    String? trackingInfo,
    String? adminNotes,
  }) {
    return DawaOrder(
      id: id,
      receiptNumber: receiptNumber,
      userId: userId,
      productId: productId,
      productTitle: productTitle,
      productImageUrl: productImageUrl,
      unitPrice: unitPrice,
      originalPrice: originalPrice,
      quantity: quantity,
      totalAmount: totalAmount,
      customerName: customerName,
      customerPhone: customerPhone,
      region: region,
      district: district,
      ward: ward,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      paymentReference: paymentReference,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      trackingInfo: trackingInfo ?? this.trackingInfo,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt,
    );
  }
}
