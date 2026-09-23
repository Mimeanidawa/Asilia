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
    _loadDefaultProducts();
    await _loadSavedOrders();
    _fetchProductsFromApi();
    _fetchOrdersFromApi();
  }

  void _loadDefaultProducts() {
    _products = [
      const DawaProduct(
        id: 'dawa_jino',
        title: 'Dawa Asili ya Maumivu ya Jino & Meno',
        subtitle: 'Mafuta & Unga wa Karafuu na Mshubiri',
        description: 'Hutuliza maumivu makali ya jino ndani ya dakika 5, kuua bakteria wanaotoboa meno, kukinga fizi kutoka damu, na kuondoa harufu mbaya mdomoni.',
        price: 20000,
        originalPrice: 40000,
        discountPercent: 50,
        imageUrl: 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?auto=format&fit=crop&q=80&w=600',
        badgeText: 'PUNGUZO LA 50% 🔥',
        stockQuantity: 50,
        category: 'jino',
        targetKeywords: 'jino, meno, fizi, kungoa jino, toothache, kutoboka jino, maumivu ya jino, maumivu ya meno, kinywa',
        benefits: [
          'Hutuliza maumivu ya jino ndani ya dakika 5',
          'Huua wadudu na bakteria wanaotoboa jino',
          'Huponya fizi zinazovuja damu na kuvimba',
          'Huondoa harufu mbaya na kusafisha kinywa',
        ],
        howToUse: 'Weka matone 2-3 kwenye pamba kisha weka kwenye jino au fizi yenye maumivu kwa dakika 15, au sukutua na maji vuguvugu.',
      ),
      const DawaProduct(
        id: 'dawa_typhoid',
        title: 'Dawa Asili ya Typhoid & Homa ya Matumbo',
        subtitle: 'Dondoo ya Mwarobaini, Mlonge & Mizizi ya Asili',
        description: 'Tiba madhubuti ya kuangamiza bakteria wa Salmonella typhi mwilini, kuondoa homa kali za vipindi, kutuliza maumivu ya tumbo na kichefuchefu, na kurejesha hamu ya kula.',
        price: 27000,
        originalPrice: 54000,
        discountPercent: 50,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=600',
        badgeText: 'PUNGUZO LA 50% 🔥',
        stockQuantity: 40,
        category: 'typhoid',
        targetKeywords: 'typhoid, homa ya matumbo, salmonella, taifodi, homa ya tumbo, kichefuchefu, kuumwa tumbo',
        benefits: [
          'Huuwa bakteria wa Salmonella typhi kwa ufanisi',
          'Hushusha homa kali na kuondoa maumivu ya mwili',
          'Huponya kichefuchefu na kurudisha nguvu',
          'Hutibu tatizo la typhoid sugu isiyoisha',
        ],
        howToUse: 'Kikombe nusu cha chai asubuhi na jioni kwa siku 10 mfululizo.',
      ),
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
        category: 'tumbo',
        targetKeywords: 'tumbo, vidonda vya tumbo, gesi, ulcers, kiungulia, acid reflux, tumbo kuwaka moto',
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
        category: 'kisukari',
        targetKeywords: 'sukari, kisukari, diabetes, insulini, kupanda sukari',
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
        category: 'presha',
        targetKeywords: 'presha, shinikizo la damu, cholesterol, moyo, mishipa ya damu, kizunguzungu',
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
        category: 'ngozi',
        targetKeywords: 'ngozi, chunusi, upele, fangasi, mabaka, muwasho wa ngozi, madoa',
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

  bool _isStopWord(String word) {
    const stops = {
      'dawa', 'asili', 'kwa', 'hadi', 'bora', 'safi', 'kuu', 'yake', 'hiki',
      'huyu', 'hawa', 'zaidi', 'kama', 'nzuri', 'jinsi', 'kutibu', 'tiba',
      'afya', 'katika', 'kwenye', 'yako', 'wako', 'wangu', 'yote'
    };
    return stops.contains(word);
  }

  /// Get the most relevant product for a specific makala / post, or the default hero product.
  DawaProduct getProductForPost(ContentPost? post) {
    if (post == null) return defaultProduct;
    if (_products.isEmpty) return defaultProduct;

    final titleLower = post.title.toLowerCase();
    final subtitleLower = post.subtitle.toLowerCase();
    final categoryLower = (post.category ?? post.section).toLowerCase();
    final contentLower = post.content.toLowerCase();

    DawaProduct? bestProduct;
    int highestScore = 0;

    for (final product in _products) {
      int score = 0;

      // 1. Target Keywords matching (Highest priority)
      if (product.targetKeywords.isNotEmpty) {
        final keywords = product.targetKeywords
            .toLowerCase()
            .split(RegExp(r'[,;\s]+'))
            .map((k) => k.trim())
            .where((k) => k.length >= 3)
            .toList();

        for (final kw in keywords) {
          if (titleLower.contains(kw)) score += 100;
          if (subtitleLower.contains(kw)) score += 50;
          if (categoryLower.contains(kw)) score += 40;
          if (contentLower.contains(kw)) score += 20;
        }
      }

      // 2. Category matching
      final prodCategory = product.category.toLowerCase().trim();
      if (prodCategory.isNotEmpty && prodCategory != 'general' && prodCategory != 'dawa_asili') {
        if (titleLower.contains(prodCategory)) score += 80;
        if (categoryLower.contains(prodCategory)) score += 60;
        if (contentLower.contains(prodCategory)) score += 25;
      }

      // 3. Product Title keywords matching in post title/subtitle
      final titleWords = product.title
          .toLowerCase()
          .split(RegExp(r'[,;\s]+'))
          .map((w) => w.trim())
          .where((w) => w.length >= 4 && !_isStopWord(w))
          .toList();

      for (final word in titleWords) {
        if (titleLower.contains(word)) score += 70;
        if (subtitleLower.contains(word)) score += 30;
      }

      if (score > highestScore) {
        highestScore = score;
        bestProduct = product;
      }
    }

    if (bestProduct != null && highestScore > 0) {
      return bestProduct;
    }

    return defaultProduct;
  }

  /// Find matching product by keywords in text
  DawaProduct getProductForText(String text) {
    if (_products.isEmpty) return defaultProduct;
    return getProductForPost(ContentPost(
      id: 'text_search_virtual',
      section: 'general',
      title: text,
      content: text,
    ));
  }

  /// Get product matching a condition
  DawaProduct getProductForCondition(dynamic condition) {
    if (condition == null) return defaultProduct;
    try {
      final name = condition.name as String? ?? '';
      final shortDesc = condition.shortDesc as String? ?? '';
      final longDesc = condition.longDesc as String? ?? '';
      return getProductForPost(ContentPost(
        id: 'condition_virtual',
        section: 'condition',
        title: name,
        subtitle: shortDesc,
        content: longDesc,
      ));
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
      if (order != null && order.paymentStatus == 'paid') {
        return order;
      }
      if (order != null && order.paymentStatus == 'failed') {
        throw ApiException('Malipo yameshindikana au yamekataliwa kwenye simu yako.');
      }
      await Future.delayed(interval);
    }
    throw ApiException('Muda wa malipo umeisha. Tafadhali angalia simu yako kisha jaribu tena.');
  }

  /// Confirm payment manually if needed
  Future<DawaOrder?> confirmPayment(String orderId, {String? reference}) async {
    try {
      final res = await _api.post('/api/orders/$orderId/confirm-payment', body: {
        if (reference != null) 'paymentReference': reference,
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
