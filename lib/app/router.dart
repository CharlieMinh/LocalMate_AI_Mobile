import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dev/component_gallery_screen.dart';
import '../features/foundation/domain/destination.dart';
import 'app_shell.dart';
import '../features/planner/presentation/finalized_trip_view.dart';
import '../features/planner/presentation/planner_page.dart';
import '../core/widgets/widgets.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/navigation/payment_return_intent.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/account_pages.dart';
import '../features/auth/presentation/auth_pages.dart';
import '../features/discovery/presentation/discovery_pages.dart';
import '../features/discovery/presentation/metro_pages.dart';
import '../features/payments/presentation/payment_pages.dart';
import '../features/trips/presentation/trips_pages.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh();
  ref.listen(authProvider, (_, _) => refresh.changed());
  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authenticated = ref.read(authProvider).authenticated;
      if ((state.uri.path == '/private' ||
              state.uri.path == '/notifications') &&
          !authenticated) {
        return '/login';
      }
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
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(path: '/planner', builder: (_, _) => const PlannerPage()),
      GoRoute(
        path: '/planner/preview/:key',
        builder: (_, state) =>
            PlannerPreviewPage(localKey: state.pathParameters['key']!),
      ),
      GoRoute(
        path: '/private',
        builder: (_, _) => Scaffold(
          appBar: AppTopBar(
            title: ref.read(configProvider).mockOnly
                ? 'Phiên tài khoản mẫu'
                : 'Tài khoản của bạn',
          ),
          body: const SafeArea(
            top: false,
            child: AuthAccountPage(showHeader: false),
          ),
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
                Destination.trips => const TripsTab(),
              },
            ),
        ],
      ),
      GoRoute(
        path: '/trips/:id',
        builder: (_, state) => TripDetailPage(state.pathParameters['id']!),
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
          if (intent != null && !ref.read(configProvider).mockOnly) {
            return PaymentStatusPage(
              intent: intent,
              checkoutUrl: state.extra is Uri ? state.extra! as Uri : null,
            );
          }
          return _StatusPage(
            title: 'Quay lại ứng dụng',
            illustration: intent == null
                ? IllustrationKind.error
                : IllustrationKind.offline,
            heading: intent == null
                ? 'Liên kết chưa hợp lệ'
                : 'Chưa xác minh thanh toán',
            message: intent == null
                ? 'Không đọc được mã đơn hàng từ liên kết này.'
                : 'Bản offline không tra cứu đơn hàng và không xác nhận quyền sử dụng.',
          );
        },
      ),
    ],
    errorBuilder: (context, state) => const _StatusPage(
      title: 'LocalMate AI',
      illustration: IllustrationKind.emptySearch,
      heading: 'Không tìm thấy màn hình',
      message: 'Màn hình này chưa khả dụng.',
    ),
  );
  ref.onDispose(router.dispose);
  ref.onDispose(refresh.dispose);
  return router;
});

class _AuthRouterRefresh extends ChangeNotifier {
  void changed() => notifyListeners();
}

/// Full-page status (payment return, unknown route) with a way home.
class _StatusPage extends StatelessWidget {
  const _StatusPage({
    required this.title,
    required this.illustration,
    required this.heading,
    required this.message,
  });
  final String title;
  final IllustrationKind illustration;
  final String heading;
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: title),
    body: SafeArea(
      top: false,
      child: Center(
        child: SingleChildScrollView(
          child: AppStateView(
            illustration: illustration,
            title: heading,
            message: message,
            primaryAction: AppButton(
              label: 'Về trang chủ',
              icon: LucideIcons.house,
              onPressed: () => context.go('/home'),
            ),
          ),
        ),
      ),
    ),
  );
}
