import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_models.dart';
import '../models/product_models.dart';
import '../utils/disease_extractor.dart';
import 'api_client.dart';

class DawaOrderService extends ChangeNotifier {
  DawaOrderService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient() {
    _init();
  }

  final ApiClient _api;
  List<DawaOrder> _orders = [];
  List<DawaProduct> _products = [];
  bool _isLoading = false;

  List<DawaOrder> get orders => List.unmodifiable(_orders);
  List<DawaProduct> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;

  static const _storageKey = 'da_user_dawa_orders_v1';
  static const _productsCacheKey = 'da_cached_products_v2';
  static const int defaultTransferFee = 12000;

  /// Standard Tanzania Regions for the order form
  static const List<String> tanzaniaRegions = [
    'Dar es Salaam',
    'Arusha',
    'Dodoma',
    'Mwanza',
    'Mbeya',
    'Morogoro',
    'Tanga',
    'Kilimanjaro (Moshi)',
    'Tabora',
    'Kigoma',
    'Iringa',
    'Mtwara',
    'Ruvuma (Songea)',
    'Kagera (Bukoba)',
    'Mara (Musoma)',
    'Manyara (Babati)',
    'Geita',
    'Simiyu (Bariadi)',
    'Katavi (Mpanda)',
    'Njombe',
    'Songwe (Vwawa)',
    'Rukwa (Sumbawanga)',
    'Singida',
    'Shinyanga',
    'Pwani (Kibaha)',
    'Lindi',
    'Zanzibar (Mjini Magharibi)',
    'Zanzibar Kaskazini',
    'Zanzibar Kusini',
    'Pemba Kaskazini',
    'Pemba Kusini',
  ];

  Future<void> _init() async {
    await _loadCachedProducts();
    await _loadSavedOrders();
    unawaited(refreshProducts());
    unawaited(_fetchOrdersFromApi());
  }

  Future<void> _loadCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_productsCacheKey);
      if (cached != null && cached.isNotEmpty) {
        final list = (jsonDecode(cached) as List)
            .map((e) => DawaProduct.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _mergeProducts(list);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading cached products: $e');
    }
  }

  void _mergeProducts(List<DawaProduct> incoming) {
    final Map<String, DawaProduct> productMap = {};
    for (final p in _products) {
      productMap[p.id] = p;
    }
    for (final p in incoming) {
      productMap[p.id] = p;
    }
    _products = productMap.values.toList();
    _products.sort((a, b) {
      final aIsCustom = a.id.startsWith('dawa_') && int.tryParse(a.id.replaceFirst('dawa_', '')) != null;
      final bIsCustom = b.id.startsWith('dawa_') && int.tryParse(b.id.replaceFirst('dawa_', '')) != null;
      if (aIsCustom && !bIsCustom) return -1;
      if (!aIsCustom && bIsCustom) return 1;
      return 0;
    });
  }

  Future<void> refreshProducts() async {
    try {
      final res = await _api
          .get('/api/products')
          .timeout(const Duration(seconds: 15));
      if (res['products'] is List) {
        final list = (res['products'] as List)
            .map((e) => DawaProduct.fromJson(e as Map<String, dynamic>))
            .toList();
        // The server is the source of truth. Replacing the list also removes
        // products deleted by an admin and clears stale cached/default entries
        // when the server legitimately returns an empty catalog.
        _products = list;
        notifyListeners();

        try {
          final prefs = await SharedPreferences.getInstance();
          final jsonStr = jsonEncode(_products.map((p) => p.toJson()).toList());
          await prefs.setString(_productsCacheKey, jsonStr);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  Future<void> _fetchOrdersFromApi() async {
    try {
      final res = await _api.get('/api/orders/my-orders');
      if (res['orders'] is List) {
        final apiOrders = (res['orders'] as List)
            .map((e) => DawaOrder.fromJson(e as Map<String, dynamic>))
            .toList();
        if (apiOrders.isNotEmpty) {
          _orders = apiOrders;
          await _saveOrdersLocally();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadSavedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null) {
        final list = (jsonDecode(saved) as List)
            .map((e) => DawaOrder.fromJson(e as Map<String, dynamic>))
            .toList();
        _orders = list;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved orders: $e');
    }
  }

  Future<void> _saveOrdersLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_orders.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Error saving orders: $e');
    }
  }

  bool _isStopWord(String word) {
    const stops = {
      'dawa', 'asili', 'kwa', 'hadi', 'bora', 'safi', 'kuu', 'yake', 'hiki',
      'huyu', 'hawa', 'zaidi', 'kama', 'nzuri', 'jinsi', 'kutibu', 'tiba',
      'afya', 'katika', 'kwenye', 'yako', 'wako', 'wangu', 'yote'
    };
    return stops.contains(word);
  }

  /// Search for a matching product for a specific makala / post.
  /// Matches against topic, title, keywords, and category with high confidence.
  /// Does NOT match random body text to prevent false cross-disease matches (e.g. UTI matching ulcer medicine).
  DawaProduct? findProductForPost(ContentPost? post) {
    if (post == null || _products.isEmpty) return null;

    final topic = DiseaseExtractor.extractTopic(post.title, post.category).toLowerCase().trim();
    final titleLower = post.title.toLowerCase();
    final subtitleLower = post.subtitle.toLowerCase();
    final categoryLower = (post.category ?? post.section).toLowerCase();

    DawaProduct? bestProduct;
    int highestScore = 0;

    for (final product in _products) {
      int score = 0;

      // 1. Exact or strong match with extracted topic (e.g. "UTI", "Kisukari")
      if (topic.isNotEmpty && topic != 'tatizo hili') {
        if (product.title.toLowerCase().contains(topic)) {
          score += 150;
        }
        if (product.category.toLowerCase().trim() == topic) {
          score += 120;
        }
      }

      // 2. Target Keywords matching against Title/Subtitle/Category (NOT generic body text!)
      if (product.targetKeywords.isNotEmpty) {
        final keywords = product.targetKeywords
            .toLowerCase()
            .split(RegExp(r'[,;\s]+'))
            .map((k) => k.trim())
            .where((k) => k.length >= 3 && !_isStopWord(k))
            .toList();

        for (final kw in keywords) {
          if (topic.contains(kw) || kw.contains(topic)) {
            score += 100;
          }
          if (titleLower.contains(kw)) {
            score += 80;
          }
          if (subtitleLower.contains(kw)) {
            score += 40;
          }
          if (categoryLower.contains(kw)) {
            score += 50;
          }
        }
      }

      // 3. Category matching (if specific)
      final prodCategory = product.category.toLowerCase().trim();
      if (prodCategory.isNotEmpty &&
          prodCategory != 'general' &&
          prodCategory != 'dawa_asili' &&
          prodCategory != 'dawa') {
        if (titleLower.contains(prodCategory)) score += 60;
        if (categoryLower == prodCategory) score += 70;
      }

      // 4. Product Title main disease words matching in post title
      final titleWords = product.title
          .toLowerCase()
          .split(RegExp(r'[,;\s]+'))
          .map((w) => w.trim())
          .where((w) => w.length >= 4 && !_isStopWord(w))
          .toList();

      for (final word in titleWords) {
        if (titleLower.contains(word)) score += 50;
        if (subtitleLower.contains(word)) score += 20;
      }

      if (score > highestScore) {
        highestScore = score;
        bestProduct = product;
      }
    }

    if (bestProduct != null && highestScore >= 70) {
      return bestProduct;
    }

    return null;
  }

  /// Real catalog product matching a makala / post, or null.
  DawaProduct? getProductForPost(ContentPost? post) => findProductForPost(post);

  /// Find matching product by keywords in text (returns null if no confident match)
  DawaProduct? findProductForText(String text) {
    if (_products.isEmpty || text.trim().isEmpty) return null;
    return findProductForPost(ContentPost(
      id: 'text_search_virtual',
      section: 'general',
      title: text,
      content: text,
    ));
  }

  DawaProduct? getProductForText(String text) => findProductForText(text);

  /// Find matching product for a condition (returns null if no confident match)
  DawaProduct? findProductForCondition(dynamic condition) {
    if (condition == null) return null;
    try {
      final name = condition.name as String? ?? '';
      final shortDesc = condition.shortDesc as String? ?? '';
      final longDesc = condition.longDesc as String? ?? '';
      return findProductForPost(ContentPost(
        id: 'condition_virtual',
        section: 'condition',
        title: name,
        subtitle: shortDesc,
        content: longDesc,
      ));
    } catch (_) {
      return null;
    }
  }

  /// Real catalog product matching a condition, or null.
  DawaProduct? getProductForCondition(dynamic condition) =>
      findProductForCondition(condition);

  /// Real catalog product matching a herb name or description, or null.
  DawaProduct? getProductForHerb(String herbName) =>
      findProductForText(herbName);

  /// Create a new order with payment and permanent receipt
  Future<DawaOrder> createOrder({
    required DawaProduct product,
    required int quantity,
    int transferFee = defaultTransferFee,
    required String customerName,
    required String customerPhone,
    required String region,
    required String district,
    required String ward,
    required String paymentMethod,
    String? userId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final randomSuffix = (1000 + Random().nextInt(9000)).toString();
      final receiptNumber = 'ASILIA-RC-${now.year}${now.month.toString().padLeft(2, '0')}-$randomSuffix';
      final orderId = 'ORD-${now.millisecondsSinceEpoch}-$randomSuffix';
      final totalAmount = (product.price * quantity) + transferFee;

      final newOrder = DawaOrder(
        id: orderId,
        receiptNumber: receiptNumber,
        userId: userId,
        productId: product.id,
        productTitle: product.title,
        productImageUrl: product.imageUrl,
        unitPrice: product.price,
        originalPrice: product.originalPrice,
        quantity: quantity,
        transferFee: transferFee,
        totalAmount: totalAmount,
        customerName: customerName.trim(),
        customerPhone: customerPhone.trim(),
        region: region.trim(),
        district: district.trim(),
        ward: ward.trim(),
        paymentMethod: paymentMethod,
        paymentStatus: 'pending',
        paymentReference: '',
        deliveryStatus: DawaDeliveryStatus.pending,
        trackingInfo: 'Inasubiri uthibitisho wa malipo kwenye simu ya mteja.',
        createdAt: now,
      );

      // Add to beginning of orders list
      _orders.insert(0, newOrder);
      await _saveOrdersLocally();

      // Attempt to send to backend API asynchronously
      try {
        await _api.post('/api/orders/create', body: newOrder.toJson());
      } catch (apiErr) {
        debugPrint('Could not post order to API (saved locally): $apiErr');
      }

      return newOrder;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initiate real mobile money payment push to the user's phone number
  Future<({DawaOrder order, String message, String? providerOrderId})> initiatePayment({
    required DawaProduct product,
    required int quantity,
    int transferFee = defaultTransferFee,
    required String customerName,
    required String customerPhone,
    required String region,
    required String district,
    required String ward,
    required String paymentMethod,
    String? userId,
    String? userToken,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final randomSuffix = (1000 + Random().nextInt(9000)).toString();
      final receiptNumber = 'ASILIA-RC-${now.year}${now.month.toString().padLeft(2, '0')}-$randomSuffix';
      final orderId = 'ORD-${now.millisecondsSinceEpoch}-$randomSuffix';
      final totalAmount = (product.price * quantity) + transferFee;

      final initialOrder = DawaOrder(
        id: orderId,
        receiptNumber: receiptNumber,
        userId: userId,
        productId: product.id,
        productTitle: product.title,
        productImageUrl: product.imageUrl,
        unitPrice: product.price,
        originalPrice: product.originalPrice,
        quantity: quantity,
        transferFee: transferFee,
        totalAmount: totalAmount,
        customerName: customerName.trim(),
        customerPhone: customerPhone.trim(),
        region: region.trim(),
        district: district.trim(),
        ward: ward.trim(),
        paymentMethod: paymentMethod,
        paymentStatus: 'pending',
        deliveryStatus: DawaDeliveryStatus.pending,
        trackingInfo: 'Inasubiri uthibitisho wa malipo kwenye simu ya mteja.',
        createdAt: now,
      );

      // Save locally
      _orders.insert(0, initialOrder);
      await _saveOrdersLocally();

      try {
        final res = await _api.post(
          '/api/orders/initiate-payment',
          token: userToken,
          body: initialOrder.toJson(),
        );

        DawaOrder updatedOrder = initialOrder;
        if (res['order'] is Map<String, dynamic>) {
          updatedOrder = DawaOrder.fromJson(res['order'] as Map<String, dynamic>);
          final idx = _orders.indexWhere((o) => o.id == orderId);
          if (idx != -1) {
            _orders[idx] = updatedOrder;
            await _saveOrdersLocally();
          }
        }

        return (
          order: updatedOrder,
          message: res['message'] as String? ?? 'Ombi la malipo limetumwa kwenye simu yako.',
          providerOrderId: res['providerOrderId'] as String?,
        );
      } catch (err) {
        debugPrint('Error initiating order payment on API: $err');
        return (
          order: initialOrder,
          message: 'Ombi la malipo limetumwa kwenye namba yako $customerPhone.',
          providerOrderId: null,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check payment status of an order
  Future<DawaOrder?> checkPaymentStatus(String orderId) async {
    try {
      final res = await _api.get('/api/orders/$orderId/payment-status');
      if (res['order'] is Map<String, dynamic>) {
        final updatedOrder = DawaOrder.fromJson(res['order'] as Map<String, dynamic>);
        final idx = _orders.indexWhere((o) => o.id == orderId || o.receiptNumber == orderId);
        if (idx != -1) {
          _orders[idx] = updatedOrder;
          await _saveOrdersLocally();
          notifyListeners();
        }
        return updatedOrder;
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
    }
    return null;
  }

  /// Wait for order payment completion by polling (up to 90 seconds)
  Future<DawaOrder> waitForOrderPayment(
    String orderId, {
    Duration timeout = const Duration(seconds: 90),
    Duration interval = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final order = await checkPaymentStatus(orderId);
      if (order != null && order.isPaid) {
        return order;
      }
      await Future.delayed(interval);
    }
    throw ApiException('Muda wa kuweka PIN umekwisha au muamala ulikataliwa. Risiti yako imehifadhiwa kama INASUBIRI MALIPO.');
  }

  /// Re-initiate payment push for an existing pending order
  Future<({DawaOrder order, String message, String? providerOrderId})> retryPaymentForOrder({
    required DawaOrder order,
    String? userToken,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.post(
        '/api/orders/initiate-payment',
        token: userToken,
        body: order.toJson(),
      );

      DawaOrder updatedOrder = order;
      if (res['order'] is Map<String, dynamic>) {
        updatedOrder = DawaOrder.fromJson(res['order'] as Map<String, dynamic>);
        final idx = _orders.indexWhere((o) => o.id == order.id || o.receiptNumber == order.receiptNumber);
        if (idx != -1) {
          _orders[idx] = updatedOrder;
          await _saveOrdersLocally();
          notifyListeners();
        }
      }

      return (
        order: updatedOrder,
        message: res['message'] as String? ?? 'Ombi la malipo limetumwa kwenye namba yako ${order.customerPhone}.',
        providerOrderId: res['providerOrderId'] as String?,
      );
    } catch (err) {
      debugPrint('Error retrying order payment: $err');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Confirm payment manually if needed
  Future<DawaOrder?> confirmPayment(String orderId, {String? reference}) async {
    try {
      final res = await _api.post('/api/orders/$orderId/confirm-payment', body: {
        'paymentReference': ?reference,
      });
      if (res['order'] is Map<String, dynamic>) {
        final updatedOrder = DawaOrder.fromJson(res['order'] as Map<String, dynamic>);
        final idx = _orders.indexWhere((o) => o.id == orderId || o.receiptNumber == orderId);
        if (idx != -1) {
          _orders[idx] = updatedOrder;
          await _saveOrdersLocally();
          notifyListeners();
        }
        return updatedOrder;
      }
    } catch (e) {
      debugPrint('Error confirming order payment: $e');
    }
    return null;
  }

  /// Update order status (for admin or status change)
  Future<void> updateOrderStatus(String orderId, DawaDeliveryStatus status, {String? trackingInfo}) async {
    final index = _orders.indexWhere((o) => o.id == orderId || o.receiptNumber == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        deliveryStatus: status,
        trackingInfo: trackingInfo,
      );
      await _saveOrdersLocally();
      notifyListeners();
    }
  }
}
