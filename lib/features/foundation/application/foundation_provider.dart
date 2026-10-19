import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/foundation_repository.dart';

final foundationProvider = Provider<FoundationStatus>(
  (ref) => const FoundationRepository().status,
);
