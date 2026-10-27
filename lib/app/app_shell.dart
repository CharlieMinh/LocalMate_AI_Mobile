import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/widgets/widgets.dart';
import '../features/foundation/domain/destination.dart';
import 'ui_providers.dart';

/// Bottom-tab scaffold. Redesigned tabs render their own (large-title or
/// brand) header; the rest still get a compact top bar from here.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.path, required this.child});

  final String path;
  final Widget child;

  static const _ownHeader = {Destination.home, Destination.explore};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = Destination.values.indexWhere((d) => d.path == path);
    final current = index < 0 ? Destination.home : Destination.values[index];
    final offline = isOffline(ref);
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && index != 0) context.go(Destination.home.path);
      },
      child: Scaffold(
        appBar: _ownHeader.contains(current)
            ? null
            : AppTopBar(
                title: switch (current) {
                  Destination.metro => 'Ga Metro',
                  Destination.trips => 'Lịch trình của tôi',
                  _ => current.label,
                },
                showBack: false,
                actions: [
                  if (current == Destination.trips)
                    AppIconButton(
                      icon: LucideIcons.plus,
                      tooltip: 'Tạo lịch trình mẫu',
                      variant: AppIconButtonVariant.tonal,
                      onPressed: () => context.push('/planner'),
                    ),
                ],
              ),
        body: Column(
          children: [
            if (offline) const SafeArea(bottom: false, child: OfflineBanner()),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: offline,
                child: child,
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          selectedIndex: index < 0 ? 0 : index,
          onSelected: (next) => context.go(Destination.values[next].path),
          destinations: [
            for (final d in Destination.values)
              AppNavDestination(label: d.label, icon: d.icon),
          ],
        ),
      ),
    );
  }
}
