import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/theme/app_theme.dart';
import 'providers.dart';
import 'router.dart';

class LocalMateApp extends ConsumerWidget {
  const LocalMateApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(configProvider);
    return MaterialApp.router(
      title: 'LocalMate AI',
      debugShowCheckedModeBanner: false,
      theme: Brand.theme,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
