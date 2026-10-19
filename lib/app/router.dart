import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/foundation/domain/destination.dart';
import '../features/foundation/presentation/foundation_page.dart';
import '../shared/widgets/content_states.dart';
import '../core/navigation/payment_return_intent.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/home'),
      // M1 never establishes an authenticated session; private routes remain closed.
      GoRoute(path: '/private', redirect: (_, _) => '/account'),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(path: state.uri.path, child: child),
        routes: [
          for (final destination in Destination.values)
            GoRoute(
              path: destination.path,
              builder: (_, _) => FoundationPage(destination: destination),
            ),
        ],
      ),
      GoRoute(
        path: '/payment-return',
        builder: (context, state) {
          final intent = PaymentReturnIntent.parseInternal(state.uri);
          return Scaffold(
            appBar: AppBar(title: const Text('Quay lại ứng dụng')),
            body: SafeArea(
              child: SingleChildScrollView(
                child: EmptyContent(
                  title: intent == null
                      ? 'Liên kết chưa hợp lệ'
                      : 'Chưa xác minh thanh toán',
                  message: 'Bản M1 không tra cứu đơn hàng và không xác nhận quyền sử dụng.',
                ),
              ),
            ),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('LocalMate AI')),
      body: SafeArea(
        child: ErrorContent(
          message: 'Màn hình này chưa khả dụng.',
          onRetry: () => context.go('/home'),
        ),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 15.6;
    final index = Destination.values.indexWhere(
      (destination) => destination.path == path,
    );
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && index != 0) context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/brand/logo.jpg',
                width: 36,
                height: 36,
                semanticLabel: 'Logo LocalMate AI',
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text('LocalMate AI', overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        body: SafeArea(top: false, bottom: false, child: child),
        bottomNavigationBar: SafeArea(
          top: false,
          child: NavigationBar(
            height: largeText ? 112 : 80,
            labelTextStyle: largeText
                ? const WidgetStatePropertyAll(
                    TextStyle(fontSize: 11, height: 1.2),
                  )
                : null,
            selectedIndex: index < 0 ? 0 : index,
            onDestinationSelected: (next) =>
                context.go(Destination.values[next].path),
            destinations: [
              for (final destination in Destination.values)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  label: largeText
                      ? destination.label.replaceAll(' ', '\n')
                      : destination.label,
                  tooltip: destination.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
