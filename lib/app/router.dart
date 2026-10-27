import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dev/component_gallery_screen.dart';
import '../features/foundation/domain/destination.dart';
import 'app_shell.dart';
import '../features/planner/presentation/finalized_trip_view.dart';
import '../features/planner/presentation/planner_page.dart';
import '../shared/widgets/content_states.dart';
import '../core/navigation/payment_return_intent.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/auth_pages.dart';
import '../features/discovery/presentation/discovery_pages.dart';
import '../features/discovery/presentation/metro_pages.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh();
  ref.listen(authProvider, (_, _) => refresh.changed());
  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authenticated = ref.read(authProvider).authenticated;
      if (state.uri.path == '/private' && !authenticated) return '/login';
      if (state.uri.path == '/login' && authenticated) return '/private';
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/home'),
      if (kDebugMode)
        GoRoute(
          path: '/dev/gallery',
          builder: (_, _) => const ComponentGalleryScreen(),
        ),
      if (kDebugMode)
        GoRoute(
          path: '/dev/finalized',
          builder: (_, _) => const FinalizedTripPreviewScreen(),
        ),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/planner', builder: (_, _) => const PlannerPage()),
      GoRoute(
        path: '/planner/preview/:key',
        builder: (_, state) =>
            PlannerPreviewPage(localKey: state.pathParameters['key']!),
      ),
      GoRoute(
        path: '/private',
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Phiên tài khoản mẫu')),
          body: const SafeArea(child: AuthAccountPage()),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(path: state.uri.path, child: child),
        routes: [
          for (final destination in Destination.values)
            GoRoute(
              path: destination.path,
              builder: (_, _) => switch (destination) {
                Destination.account => const AuthAccountPage(),
                Destination.home => const DiscoveryHomePage(),
                Destination.explore => const ExplorePage(),
                Destination.metro => const MetroPage(),
                Destination.trips => const PlannerEntryPage(),
              },
            ),
        ],
      ),
      GoRoute(
        path: '/places/:id',
        builder: (_, state) => PlaceDetailPage(state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/curated/:id',
        builder: (_, state) => CuratedDetailPage(state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/stations/:order',
        builder: (_, state) => StationDetailPage(
          int.tryParse(state.pathParameters['order']!) ?? -1,
        ),
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
  ref.onDispose(refresh.dispose);
  return router;
});

class _AuthRouterRefresh extends ChangeNotifier {
  void changed() => notifyListeners();
}
