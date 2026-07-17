import 'api_client.dart';

enum PaymentType { content, premium }

enum PaymentChannel {
  mpesa('MPESA', 'M-Pesa'),
  airtelMoney('AIRTEL_MONEY', 'Airtel Money'),
  tigoPesa('TIGO_PESA', 'Mixx by Yas'),
  haloPesa('HALOPESA', 'HaloPesa');

  const PaymentChannel(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.phone,
    this.contentId,
    this.title,
    this.reference,
    this.transid,
  });

  final String id;
  final String type;
  final int amount;
  final String status;
  final String phone;
  final String? contentId;
  final String? title;
  final String? reference;
  final String? transid;

  bool get isSuccess => status == 'success';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
    id: json['id'] as String,
    type: json['type'] as String,
    amount: json['amount'] as int? ?? 0,
    status: json['status'] as String? ?? 'pending',
    phone: json['phone'] as String? ?? '',
    contentId: json['contentId'] as String?,
    title: json['title'] as String?,
    reference: json['reference'] as String?,
    transid: json['transid'] as String?,
  );
}

class PaymentInitResponse {
  const PaymentInitResponse({
    required this.payment,
    required this.message,
    this.alreadyPurchased = false,
    this.alreadyActive = false,
  });

  final PaymentRecord payment;
  final String message;
  final bool alreadyPurchased;
  final bool alreadyActive;
}

class PaymentStatusResponse {
  const PaymentStatusResponse({
    required this.payment,
    this.purchasedContentIds = const [],
    this.isPremiumActive = false,
  });

  final PaymentRecord payment;
  final List<String> purchasedContentIds;
  final bool isPremiumActive;
}

class PaymentService {
  PaymentService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<PaymentInitResponse> initiate({
    required PaymentType type,
    required String phone,
    required PaymentChannel channel,
    required String token,
    String? contentId,
  }) async {
    final data = await _api.post(
      '/api/payments/initiate',
      token: token,
      body: {
        'type': type == PaymentType.premium ? 'premium' : 'content',
        'phone': phone,
        'channel': channel.apiValue,
        if (contentId != null) 'contentId': contentId,
      },
    );

    if (data['alreadyPurchased'] == true || data['alreadyActive'] == true) {
      return PaymentInitResponse(
        payment: PaymentRecord(
          id: 'skip',
          type: type == PaymentType.premium ? 'premium' : 'content',
          amount: 0,
          status: 'success',
          phone: phone,
          contentId: contentId,
        ),
        message: data['alreadyPurchased'] == true
            ? 'Tayari umelipia makala hii'
            : 'Premium yako bado inaendelea',
        alreadyPurchased: data['alreadyPurchased'] == true,
        alreadyActive: data['alreadyActive'] == true,
      );
    }

    return PaymentInitResponse(
      payment: PaymentRecord.fromJson(data['payment'] as Map<String, dynamic>),
      message: data['message'] as String? ?? 'Ombi la malipo limetumwa',
    );
  }

  Future<PaymentStatusResponse> checkStatus({
    required String paymentId,
    required String token,
  }) async {
    final data = await _api.get(
      '/api/payments/$paymentId/status',
      token: token,
    );
    return PaymentStatusResponse(
      payment: PaymentRecord.fromJson(data['payment'] as Map<String, dynamic>),
      purchasedContentIds: List<String>.from(
        data['purchasedContentIds'] as List? ?? [],
      ),
      isPremiumActive: data['isPremiumActive'] as bool? ?? false,
    );
  }

  Future<PaymentStatusResponse> waitForCompletion({
    required String paymentId,
    required String token,
    Duration timeout = const Duration(seconds: 90),
    Duration interval = const Duration(seconds: 3),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      final status = await checkStatus(paymentId: paymentId, token: token);
      if (status.payment.isSuccess) return status;
      if (status.payment.isFailed) {
        throw ApiException('Malipo yameshindikana. Jaribu tena.');
      }
      await Future.delayed(interval);
    }
    throw ApiException(
      'Muda wa malipo umeisha. Angalia simu yako na jaribu tena.',
    );
  }
}
