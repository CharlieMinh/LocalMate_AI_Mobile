import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../domain/destination.dart';
import '../application/foundation_provider.dart';

class FoundationPage extends ConsumerWidget {
  const FoundationPage({super.key, required this.destination});
  final Destination destination;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    key: ValueKey(destination.path),
    padding: const EdgeInsets.all(Brand.space),
    children: [
      Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2D6),
                  borderRadius: BorderRadius.circular(Brand.radius),
                ),
                child: Text(
                  '${ref.watch(foundationProvider).milestone} · Bản nền tảng · Chưa kết nối Backend',
                  style: const TextStyle(
                    color: Color(0xFF704900),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Icon(destination.icon, size: 48, color: Brand.navy),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                child: Text(
                  destination.heading,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 12),
              Text(destination.description),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 12),
              if (destination == Destination.home) ...[
                Text(
                  'Đi theo nhịp riêng',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Địa điểm, Metro và lịch trình trong cùng một trải nghiệm Android.',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.go('/explore'),
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Mở Khám phá'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/metro'),
                  icon: const Icon(Icons.train_outlined),
                  label: const Text('Mở Metro'),
                ),
              ] else ...[
                const Icon(Icons.cloud_off_outlined, color: Brand.muted),
                const SizedBox(height: 12),
                const Text(
                  'Chức năng sẽ có ở mốc tích hợp tương ứng. Bản này không gửi yêu cầu mạng.',
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ],
  );
}
