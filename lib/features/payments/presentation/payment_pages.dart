import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/navigation/payment_return_intent.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/api_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/formatters.dart';
import '../../trips/application/trips_providers.dart';
import '../../trips/domain/trip_models.dart';
import '../data/payments_repository.dart';

String _vnd(double v) => '${formatVnd(v)}đ';

final _quoteProvider = FutureProvider.autoDispose.family<CheckoutQuote, String>(
  (ref, planCode) {
    final token = CancelToken();
    ref.onDispose(() => token.cancel('disposed'));
    return ref.watch(paymentsRepositoryProvider).quote(planCode, token);
  },
  retry: (_, _) => null,
);

/// Quote → PayOS order → checkout page in the browser → order status.
Future<void> startPlanCheckout(BuildContext context, SubscriptionPlan plan) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CheckoutSheet(plan),
    );

class _CheckoutSheet extends ConsumerStatefulWidget {
  const _CheckoutSheet(this.plan);
  final SubscriptionPlan plan;

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _pay() async {
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final intent = await ref
          .read(paymentsRepositoryProvider)
          .checkout(widget.plan.code);
      final opened = await ref.read(externalUrlOpenerProvider)(
        intent.checkoutUrl,
      );
      navigator.pop();
      unawaited(
        router.push(
          '/payment-return?orderId=${intent.orderId}&flow=subscription',
          extra: opened ? null : intent.checkoutUrl,
        ),
      );
    } on ApiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = apiErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = ref.watch(_quoteProvider(widget.plan.code));
    final text = context.textStyles;
    Widget row(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          Text(value, style: strong ? text.titleMedium : text.labelLarge),
        ],
      ),
    );
    final q = quote.asData?.value;
    return AppSheetBody(
      title: 'Nâng cấp ${widget.plan.name}',
      subtitle: 'Thanh toán an toàn qua PayOS (chuyển khoản / quét mã QR).',
      actions: [
        AppButton(
          buttonKey: const ValueKey('checkout-pay'),
          label: q == null ? 'Thanh toán' : 'Thanh toán ${_vnd(q.amount)}',
          icon: LucideIcons.creditCard,
          expand: true,
          loading: _busy,
          onPressed: q == null || _busy ? null : _pay,
        ),
      ],
      child: quote.when(
        skipLoadingOnRefresh: false,
        loading: () => const SkeletonBlock(height: AppSpacing.xxxl * 2),
        error: (e, _) => AppErrorState(
          compact: true,
          title: 'Chưa lấy được báo giá',
          message: e is ApiFailure ? apiErrorMessage(e) : 'Vui lòng thử lại.',
          onRetry: () => ref.invalidate(_quoteProvider(widget.plan.code)),
        ),
        data: (q) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row(
              q.type == 'Upgrade'
                  ? 'Giá gói'
                  : q.type == 'Renewal'
                  ? 'Gia hạn gói'
                  : 'Giá gói',
              _vnd(q.listPrice),
            ),
            if (q.creditAmount > 0)
              row('Trừ phần còn lại của gói cũ', '−${_vnd(q.creditAmount)}'),
            if (q.durationDays != null)
              row('Thời hạn', '${q.durationDays} ngày'),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            row('Cần thanh toán', _vnd(q.amount), strong: true),
            const SizedBox(height: AppSpacing.sm),
            const AppBanner(
              message: 'Trang thanh toán mở trong trình duyệt. Quyền lợi được kích hoạt sau khi LocalMate nhận xác nhận từ PayOS.',
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppBanner(kind: BannerKind.error, message: _error!),
            ],
          ],
        ),
      ),
    );
  }
}

/// `/payment-return?orderId&flow` in live builds: polls the order until it
/// leaves Pending. The return link itself is never treated as proof.
class PaymentStatusPage extends ConsumerStatefulWidget {
  const PaymentStatusPage({super.key, required this.intent, this.checkoutUrl});
  final PaymentReturnIntent intent;

  /// Set when the browser could not be opened automatically.
  final Uri? checkoutUrl;

  @override
  ConsumerState<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends ConsumerState<PaymentStatusPage> {
  static const _maxWait = Duration(minutes: 15);
  final _cancel = CancelToken();
  final _started = DateTime.now();
  Timer? _timer;
  PaymentOrder? _order;
  ApiFailure? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cancel.cancel('disposed');
    super.dispose();
  }

  Future<void> _check() async {
    _timer?.cancel();
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final order = await ref
          .read(paymentsRepositoryProvider)
          .order(widget.intent.orderId, widget.intent.flow, _cancel);
      if (!mounted) return;
      setState(() {
        _order = order;
        _error = null;
      });
      if (order.status == 'Paid') {
        AppHaptics.success();
        ref
          ..invalidate(subscriptionProvider)
          ..invalidate(plansProvider);
      }
    } on ApiFailure catch (e) {
      if (!mounted || e.kind == FailureKind.cancelled) return;
      setState(() => _error = e);
    } finally {
      if (mounted) {
        setState(() => _checking = false);
        final waiting = _order?.pending ?? _error?.isTransport ?? false;
        if (waiting && DateTime.now().difference(_started) < _maxWait) {
          _timer = Timer(ref.read(paymentPollIntervalProvider), _check);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final error = _error;
    final url = widget.checkoutUrl;
    final Widget body;
    if (order == null && error == null) {
      body = const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (order == null) {
      body = AppErrorState(
        title: 'Chưa kiểm tra được đơn hàng',
        message: apiErrorMessage(error!),
        onRetry: _checking ? null : _check,
      );
    } else {
      final home = AppButton.secondary(
        label: 'Về Tài khoản',
        icon: LucideIcons.user,
        onPressed: () => context.go('/account'),
      );
      body = switch (order.status) {
        'Paid' => AppStateView(
          illustration: IllustrationKind.success,
          title: 'Thanh toán thành công',
          message:
              'Đã nhận ${_vnd(order.amount)}. Gói mới đã được kích hoạt cho tài khoản của bạn.',
          primaryAction: AppButton(
            label: 'Xem gói của tôi',
            icon: LucideIcons.crown,
            onPressed: () => context.go('/account'),
          ),
        ),
        'Pending' => AppStateView(
          illustration: IllustrationKind.success,
          art: const _WaitingArt(),
          title: 'Đang chờ thanh toán',
          message:
              'Hoàn tất ${_vnd(order.amount)} trên trang PayOS. Màn hình này tự cập nhật khi LocalMate nhận được xác nhận.',
          primaryAction: url == null
              ? AppButton(
                  label: 'Kiểm tra lại',
                  icon: LucideIcons.refreshCw,
                  loading: _checking,
                  onPressed: _checking ? null : _check,
                )
              : AppButton(
                  label: 'Mở trang thanh toán',
                  icon: LucideIcons.externalLink,
                  onPressed: () => ref.read(externalUrlOpenerProvider)(url),
                ),
          secondaryAction: home,
        ),
        'ReviewRequired' => AppStateView(
          illustration: IllustrationKind.error,
          title: 'Đơn hàng cần kiểm tra',
          message: 'Khoản thanh toán chưa khớp với đơn. Đội ngũ LocalMate sẽ kiểm tra; bạn không cần thanh toán lại.',
          primaryAction: home,
        ),
        _ => AppStateView(
          illustration: IllustrationKind.error,
          title: order.status == 'Expired'
              ? 'Đơn thanh toán đã hết hạn'
              : 'Thanh toán chưa thành công',
          message:
              'Bạn chưa bị trừ tiền cho đơn này. Hãy tạo đơn mới khi sẵn sàng.',
          primaryAction: home,
        ),
      };
    }
    return Scaffold(
      appBar: const AppTopBar(title: 'Thanh toán'),
      body: SafeArea(
        top: false,
        child: Center(child: SingleChildScrollView(child: body)),
      ),
    );
  }
}

/// Pending payment art, same footprint as the state illustrations. Static
/// on purpose: the page polls quietly and the retry button shows progress.
class _WaitingArt extends StatelessWidget {
  const _WaitingArt();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: AppSpacing.xxxl * 3,
        height: AppSpacing.xxxl * 3,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          LucideIcons.hourglass,
          size: AppSpacing.xxxl,
          color: scheme.primary,
        ),
      ),
    );
  }
}
