import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/theme/app_theme.dart';
import 'providers.dart';
import 'router.dart';
import '../features/auth/application/auth_controller.dart';

class LocalMateApp extends ConsumerStatefulWidget {
  const LocalMateApp({super.key});
  @override
  ConsumerState<LocalMateApp> createState() => _LocalMateAppState();
}

class _LocalMateAppState extends ConsumerState<LocalMateApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(authProvider.notifier).checkExpiry();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(configProvider);
    return MaterialApp.router(
      title: 'LocalMate AI',
      debugShowCheckedModeBanner: false,
      theme: Brand.theme,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
