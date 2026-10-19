enum PurchaseFlow { subscription, singleItinerary }

/// Untrusted navigation hint, never payment or entitlement evidence.
class PaymentReturnIntent {
  const PaymentReturnIntent({required this.orderId, required this.flow});
  final String orderId;
  final PurchaseFlow flow;
  static PaymentReturnIntent? parseInternal(Uri uri) {
    if (uri.hasScheme || uri.hasAuthority || uri.path != '/payment-return') {
      return null;
    }
    final ids = uri.queryParametersAll['orderId'];
    final flows = uri.queryParametersAll['flow'];
    if (ids?.length != 1 || flows?.length != 1) return null;
    final id = ids!.single;
    if (!RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(id) ||
        id == '00000000-0000-0000-0000-000000000000') {
      return null;
    }
    final flow = switch (flows!.single) {
      'subscription' => PurchaseFlow.subscription,
      'single' => PurchaseFlow.singleItinerary,
      _ => null,
    };
    return flow == null ? null : PaymentReturnIntent(orderId: id, flow: flow);
  }
}
