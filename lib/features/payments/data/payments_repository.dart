import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/navigation/payment_return_intent.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';

Map<String, Object?> _map(Object? raw) {
  if (raw is! Map) throw const FormatException('Expected a JSON object');
  return Map<String, Object?>.from(raw);
}

double _num(Object? v) => v is num ? v.toDouble() : 0;
DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// `GET /subscription/checkout-quote`.
class CheckoutQuote {
  const CheckoutQuote({
    required this.planCode,
    required this.type,
    required this.listPrice,
    required this.creditAmount,
    required this.amount,
    this.durationDays,
  });
  final String planCode;

  /// `Purchase`, `Renewal` or `Upgrade`.
  final String type;
  final double listPrice;

  /// Value carried over from the current paid plan.
  final double creditAmount;
  final double amount;
  final int? durationDays;

  factory CheckoutQuote.fromJson(Object? raw) {
    final j = _map(raw);
    return CheckoutQuote(
      planCode: j['planCode']! as String,
      type: (j['type'] as String?) ?? 'Purchase',
      listPrice: _num(j['listPrice']),
      creditAmount: _num(j['creditAmount']),
      amount: _num(j['amount']),
      durationDays: (j['durationDays'] as num?)?.toInt(),
    );
  }
}

/// `PaymentIntentResponse`, also carried by 409 "pending order" problems.
class PaymentIntent {
  const PaymentIntent({
    required this.orderId,
    required this.checkoutUrl,
    required this.amount,
    this.expiresAt,
  });
  final String orderId;
  final Uri checkoutUrl;
  final double amount;
  final DateTime? expiresAt;

  /// Only https PayOS links from the server are opened.
  static PaymentIntent? tryParse(Map<String, Object?> j) {
    final id = j['orderId'];
    final url = j['checkoutUrl'] is String
        ? Uri.tryParse(j['checkoutUrl']! as String)
        : null;
    if (id is! String ||
        url == null ||
        url.scheme != 'https' ||
        !url.hasAuthority) {
      return null;
    }
    return PaymentIntent(
      orderId: id,
      checkoutUrl: url,
      amount: _num(j['amount']),
      expiresAt: _date(j['expiresAt']),
    );
  }

  factory PaymentIntent.fromJson(Object? raw) =>
      tryParse(_map(raw)) ??
      (throw const FormatException('Invalid payment intent'));
}

/// Order status while the user pays.
class PaymentOrder {
  const PaymentOrder({
    required this.orderId,
    required this.status,
    required this.amount,
    this.expiresAt,
    this.paidAt,
  });
  final String orderId;

  /// `Pending`, `Paid`, `Failed`, `Expired` or `ReviewRequired`.
  final String status;
  final double amount;
  final DateTime? expiresAt;
  final DateTime? paidAt;

  bool get pending => status == 'Pending';

  factory PaymentOrder.fromJson(Object? raw) {
    final j = _map(raw);
    return PaymentOrder(
      orderId: j['orderId']! as String,
      status: j['status']! as String,
      amount: _num(j['amount']),
      expiresAt: _date(j['expiresAt']),
      paidAt: _date(j['paidAt']),
    );
  }
}

/// Codes whose 409 body carries the still-open order to resume.
const _resumable = {'pending_order_exists', 'another_pending_order'};

class PaymentsRepository {
  const PaymentsRepository(this.client);
  final ApiClient client;

  Future<CheckoutQuote> quote(String planCode, CancelToken token) => client.get(
    '/subscription/checkout-quote',
    CheckoutQuote.fromJson,
    cancelToken: token,
    query: {'planCode': planCode},
  );

  /// Creates a PayOS order, or returns the user's open one for this plan.
  Future<PaymentIntent> checkout(String planCode) async {
    try {
      return await client.post('/subscription/checkout', {
        'planCode': planCode,
      }, PaymentIntent.fromJson);
    } on ApiFailure catch (error) {
      final open = _resumable.contains(error.code)
          ? PaymentIntent.tryParse(error.details)
          : null;
      if (open != null) return open;
      rethrow;
    }
  }

  Future<PaymentOrder> order(
    String orderId,
    PurchaseFlow flow,
    CancelToken token,
  ) => client.get(
    switch (flow) {
      PurchaseFlow.subscription =>
        '/subscription/orders/${Uri.encodeComponent(orderId)}',
      PurchaseFlow.singleItinerary =>
        '/itinerary-purchases/orders/${Uri.encodeComponent(orderId)}',
    },
    PaymentOrder.fromJson,
    cancelToken: token,
  );
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>(
  (ref) => PaymentsRepository(ref.watch(apiProvider)),
);

/// Opens a URL outside the app (PayOS checkout). Overridden in tests.
final externalUrlOpenerProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Poll interval while an order is pending.
final paymentPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 3),
);
