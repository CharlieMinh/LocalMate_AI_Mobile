import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dev/component_gallery_screen.dart';
import '../features/foundation/domain/destination.dart';
import '../features/planner/presentation/planner_page.dart';
import '../shared/widgets/content_states.dart';
import '../shared/widgets/brand_header.dart';
import '../shared/theme/layout_tokens.dart';
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

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final largeText = LayoutTokens.usesLargeText(textScaler);
    final index = Destination.values.indexWhere(
      (destination) => destination.path == path,
    );
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && index != 0) context.go('/home');
      },
      child: Scaffold(
        appBar: index <= 0
            ? BrandHeader(onAccount: () => context.go('/account'))
            : AppBar(
                title: Text(switch (Destination.values[index]) {
                  Destination.metro => 'Ga Metro',
                  Destination.trips => 'Lịch trình cá nhân',
                  _ => Destination.values[index].label,
                }),
                actions: [
                  if (path == '/trips' || path == '/explore')
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IconButton.filledTonal(
                        tooltip: 'Tạo lịch trình mẫu',
                        onPressed: () => context.push('/planner'),
                        icon: Icon(
                          path == '/trips'
                              ? Icons.add
                              : Icons.auto_awesome_outlined,
                        ),
                      ),
                    ),
                ],
              ),
        body: SafeArea(top: false, bottom: false, child: child),
        bottomNavigationBar: SafeArea(
          top: false,
          child: NavigationBar(
            height: LayoutTokens.navigationHeightFor(textScaler),
            labelTextStyle: largeText
                ? WidgetStateProperty.resolveWith(
                    (states) =>
                        (Theme.of(context).navigationBarTheme.labelTextStyle
                                    ?.resolve(states) ??
                                const TextStyle())
                            .copyWith(
                              fontSize: 11,
                              height: 1.2,
                              letterSpacing: 0,
                            ),
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
