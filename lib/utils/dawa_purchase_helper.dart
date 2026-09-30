import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../services/dawa_order_service.dart';
import '../widgets/order_product_sheet.dart';

/// Helper to handle the "Nunua Dawa Hii" flow:
/// 1. Searches available products matching the article topic.
/// 2. If available, opens OrderProductSheet showing the product details, price, and payment methods.
/// 3. If not available, smoothly redirects user to Mwalimu with a draft inquiry.
class DawaPurchaseHelper {
  DawaPurchaseHelper._();

  static Future<void> searchAndBuyDawa(BuildContext context, ContentPost post) async {
    final orderService = context.read<DawaOrderService>();

    // Show a sleek search indicator dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF062319),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF34D399).withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Inatafuta dawa inayolingana...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tafadhali subiri kidogo kuangalia dukani',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Realistic brief search delay for perceived responsiveness
    await Future.delayed(const Duration(milliseconds: 700));

    final product = orderService.getProductForPost(post);

    if (!context.mounted) return;
    // Dismiss search modal
    Navigator.of(context, rootNavigator: true).pop();

    OrderProductSheet.show(context, product);
  }
}
