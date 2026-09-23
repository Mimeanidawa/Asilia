import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_models.dart';
import '../models/product_models.dart';
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
    _loadDefaultProducts();
    await _loadSavedOrders();
    _fetchProductsFromApi();
    _fetchOrdersFromApi();
  }

  void _loadDefaultProducts() {
    _products = [
      const DawaProduct(
        id: 'dawa_tumbo',
        title: 'Dawa Asili ya Vidonda vya Tumbo & Gesi',
        subtitle: 'Mchanganyiko maalum wa Mshubiri & Mizizi ya Asili',
        description: 'Tiba madhubuti ya vidonda vya tumbo sugu (peptic ulcers), kiungulia, gesi kujaa tumboni, na kurekebisha tindikali (acid reflux).',
        price: 25000,
        originalPrice: 50000,
        discountPercent: 50,
        imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=600',
        badgeText: 'PUNGUZO LA 50% 🔥',
        stockQuantity: 45,
        benefits: [
          'Huponya vidonda vya tumbo kuanzia siku 7 za mwanzo',
          'Huondoa kiungulia kikali na kutapika maji machungu',
          'Hulainisha kuta za tumbo na kusawazisha tindikali',
          'Inafaa kwa watoto na watu wazima (100% asilia)',
        ],
        howToUse: 'Kijiko 1 cha chakula kwenye maji vuguvugu asubuhi kabla ya kula na usiku kabla ya kulala.',
      ),
      const DawaProduct(
        id: 'dawa_kisukari',
        title: 'Mchanganyiko wa Asili wa Kudhibiti Kisukari',
        subtitle: 'Magome na Majani ya Mwarobaini & Mlonge',
        description: 'Tiba asilia ya kusaidia kongosho kuzalisha homoni ya insulini, kusafisha damu, na kudhibiti viwango vya juu vya sukari.',
        price: 30000,
        originalPrice: 60000,
        discountPercent: 50,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=600',
        badgeText: 'PUNGUZO LA 50% 🔥',
        stockQuantity: 30,
        benefits: [
          'Hushusha sukari na kuweka kiwango thabiti',
          'Huondoa uchovu mwingi na kizunguzungu',
          'Hulinda macho na mafigo dhidi ya madhara ya sukari',
        ],
        howToUse: 'Kikombe nusu asubuhi na jioni kwa siku 14 mfululizo.',
      ),
      const DawaProduct(
        id: 'dawa_presha',
        title: 'Dawa ya Kusafisha Mishipa & Presha ya Juu',
        subtitle: 'Mvuke na Dondoo ya Kitunguu Saumu & Tangawizi',
        description: 'Huongeza upenyaji wa damu, kuyeyusha mafuta mabaya (cholesterol), na kushusha shinikizo la damu kwenye mishipa ya moyo.',
        price: 28000,
        originalPrice: 56000,
        discountPercent: 50,
        imageUrl: 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?auto=format&fit=crop&q=80&w=600',
        badgeText: 'PUNGUZO LA 50% 🔥',
        stockQuantity: 25,
        benefits: [
          'Hushusha presha na kupunguza maumivu ya kisogo',
          'Huyeyusha cholesterol na kusafisha damu',
          'Huleta utulivu mzito wa mapigo ya moyo',
        ],
        howToUse: 'Kijiko 1 asubuhi kwenye chai au maji ya vuguvugu.',
      ),
      const DawaProduct(
        id: 'dawa_ngozi',
        title: 'Mafuta & Sabuni ya Asili ya Ngozi na Chunusi',
        subtitle: 'Mshubiri, Mwarobaini & Manjano Safi',
        description: 'Huondoa chunusi sugu, vipele, muwasho wa ngozi, fangasi, mabaka meusi, na kurejesha ngozi kuwa nyororo na yenye mng’ao.',
        price: 20000,
        originalPrice: 40000,
        discountPercent: 50,
        imageUrl: 'https://images.unsplash.com/photo-1608248597359-598d1a100a73?auto=format&fit=crop&q=80&w=600',
        badgeText: 'PUNGUZO LA 50% 🔥',
        stockQuantity: 60,
        benefits: [
          'Hukausha chunusi ndani ya masaa 48',
          'Huondoa madoa na makovu ya zamani',
          'Hutibu fangasi sugu na kuwasha kwa ngozi',
        ],
        howToUse: 'Paka mara 2 kwa siku baada ya kuosha uso au eneo lililoathirika.',
      ),
    ];
  }

  Future<void> _fetchProductsFromApi() async {
    try {
      final res = await _api.get('/api/products');
      if (res['products'] is List) {
        final list = (res['products'] as List)
            .map((e) => DawaProduct.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _products = list;
          notifyListeners();
        }
      }
    } catch (_) {}
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

  /// Safely get default product
  DawaProduct get defaultProduct => _products.isNotEmpty
      ? _products.first
      : const DawaProduct(
          id: 'dawa_tumbo',
          title: 'Dawa Asili ya Vidonda vya Tumbo & Gesi',
          subtitle: 'Mchanganyiko maalum wa Mshubiri & Mizizi ya Asili',
          description: 'Tiba madhubuti ya vidonda vya tumbo sugu (peptic ulcers), kiungulia, gesi kujaa tumboni, na kurekebisha tindikali.',
          price: 25000,
          originalPrice: 50000,
          discountPercent: 50,
          imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=600',
          badgeText: 'PUNGUZO LA 50% 🔥',
          stockQuantity: 45,
          benefits: [
            'Huponya vidonda vya tumbo kuanzia siku 7 za mwanzo',
            'Huondoa kiungulia kikali na kutapika maji machungu',
            'Hulainisha kuta za tumbo na kusawazisha tindikali',
            'Inafaa kwa watoto na watu wazima (100% asilia)',
          ],
        );

  /// Find matching product by keywords in text
  DawaProduct getProductForText(String text) {
    if (_products.isEmpty) return defaultProduct;
    final lower = text.toLowerCase();
    if (lower.contains('sukari') || lower.contains('kisukari')) {
      return _products.firstWhere((p) => p.id == 'dawa_kisukari', orElse: () => defaultProduct);
    }
    if (lower.contains('presha') || lower.contains('damu') || lower.contains('moyo')) {
      return _products.firstWhere((p) => p.id == 'dawa_presha', orElse: () => defaultProduct);
    }
    if (lower.contains('ngozi') || lower.contains('chunusi') || lower.contains('upele') || lower.contains('fangasi')) {
      return _products.firstWhere((p) => p.id == 'dawa_ngozi', orElse: () => defaultProduct);
    }
    return _products.firstWhere((p) => p.id == 'dawa_tumbo', orElse: () => defaultProduct);
  }

  /// Get the most relevant product for a specific makala / post, or the default hero product.
  DawaProduct getProductForPost(ContentPost? post) {
    if (post == null) return defaultProduct;
    final combined = '${post.title} ${post.subtitle} ${post.category ?? ''} ${post.content}';
    return getProductForText(combined);
  }

  /// Get product matching a condition
  DawaProduct getProductForCondition(dynamic condition) {
    if (condition == null) return defaultProduct;
    try {
      final name = condition.name as String? ?? '';
      final shortDesc = condition.shortDesc as String? ?? '';
      final longDesc = condition.longDesc as String? ?? '';
      return getProductForText('$name $shortDesc $longDesc');
    } catch (_) {
      return defaultProduct;
    }
  }

  /// Get product matching a herb name or description
  DawaProduct getProductForHerb(String herbName) {
    return getProductForText(herbName);
  }

  /// Create a new order with payment and permanent receipt
  Future<DawaOrder> createOrder({
    required DawaProduct product,
    required int quantity,
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
      final totalAmount = product.price * quantity;

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
        totalAmount: totalAmount,
        customerName: customerName.trim(),
        customerPhone: customerPhone.trim(),
        region: region.trim(),
        district: district.trim(),
        ward: ward.trim(),
        paymentMethod: paymentMethod,
        paymentStatus: 'paid',
        paymentReference: 'PAY-${now.millisecondsSinceEpoch}',
        deliveryStatus: DawaDeliveryStatus.pending,
        trackingInfo: 'Agizo lako limethibitishwa. Linaandaliwa kwa ajili ya usafirishaji kwenda $region, $district.',
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
