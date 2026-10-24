import 'package:flutter/widgets.dart';

import 'previews/localmate_previews.dart';

/// Optional development entry point. Android builds still use lib/main.dart.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final query = Uri.base.queryParameters;
  final width = double.tryParse(query['width'] ?? '') ?? 412;
  final scale = double.tryParse(query['scale'] ?? '') ?? 1;
  runApp(
    LocalMateScreenPreview(
      route: query['screen'] ?? '/home',
      screenSize: Size(width.clamp(320, 768), 892),
      textScale: scale.clamp(1, 2),
    ),
  );
}
