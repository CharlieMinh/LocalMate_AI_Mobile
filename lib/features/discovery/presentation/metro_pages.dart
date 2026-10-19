import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/content_states.dart';
import '../application/discovery_providers.dart';
import '../domain/discovery_models.dart';
import 'discovery_widgets.dart';

class MetroPage extends ConsumerStatefulWidget {
  const MetroPage({super.key});
  @override
  ConsumerState<MetroPage> createState() => _MetroPageState();
}

class _MetroPageState extends ConsumerState<MetroPage> {
  int from = 1, to = 2;
  ({int from, int to})? applied;
  @override
  Widget build(BuildContext context) => DiscoveryBody(
    children: [
      Text(
        'Dọc tuyến Metro số 1',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text('Bến Thành – Bến xe Suối Tiên'),
      const Text(
        '14 ga · Thứ tự theo source Backend. Không có thông tin tàu trực tiếp.',
      ),
      DiscoveryAsync(
        value: ref.watch(stationsProvider),
        retry: () => ref.invalidate(stationsProvider),
        data: (stations) {
          if (stations.isEmpty) {
            return const EmptyContent(
              title: 'Chưa có ga Metro',
              message: 'Hãy thử lại sau.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Xem hành trình'),
              DropdownButtonFormField<int>(
                initialValue: from,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ga đi',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final s in stations)
                    DropdownMenuItem(
                      value: s.order,
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() {
                  from = value!;
                  applied = null;
                }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: to,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ga đến',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final s in stations)
                    DropdownMenuItem(
                      value: s.order,
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() {
                  to = value!;
                  applied = null;
                }),
              ),
              const SizedBox(height: 12),
              if (from == to) const Text('Chọn hai ga khác nhau.'),
              FilledButton.icon(
                onPressed: from == to
                    ? null
                    : () => setState(() => applied = (from: from, to: to)),
                icon: const Icon(Icons.route_outlined),
                label: const Text('Xem hành trình mẫu'),
              ),
              if (applied != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: DiscoveryAsync(
                    value: ref.watch(journeyProvider(applied!)),
                    retry: () => ref.invalidate(journeyProvider(applied!)),
                    data: (journey) => JourneyView(journey),
                  ),
                ),
              const SectionTitle('Chọn ga để khám phá'),
              for (final s in stations)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: CircleAvatar(child: Text('${s.order}')),
                  title: Text(s.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/stations/${s.order}'),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class JourneyView extends StatelessWidget {
  const JourneyView(this.journey, {super.key});
  final MetroJourney journey;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${journey.from} → ${journey.to}',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      Text(
        '${journey.minutes} phút · ${journey.stopCount} chặng (ước tính mẫu)',
      ),
      ScheduleView(journey.schedule),
      if (journey.schedule.showExact)
        for (final t in journey.trips)
          Text(
            '${t.departure.substring(0, 5)} → ${t.arrival.substring(0, 5)} (lịch mẫu)',
          )
      else if (journey.schedule.precision == 'Headway' &&
          journey.schedule.withinPeriod)
        for (final h in journey.headways)
          Text(
            '${h.from.substring(0, 5)}–${h.to.substring(0, 5)}: khoảng ${h.minutes} phút/chuyến',
          ),
    ],
  );
}

class StationDetailPage extends ConsumerWidget {
  const StationDetailPage(this.order, {super.key});
  final int order;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết ga')),
    body: SafeArea(
      child: DiscoveryBody(
        children: [
          DiscoveryAsync(
            value: ref.watch(stationsProvider),
            retry: () => ref.invalidate(stationsProvider),
            data: (stations) {
              final matching = stations.where((s) => s.order == order);
              if (matching.isEmpty) {
                return const EmptyContent(
                  title: 'Không tìm thấy ga',
                  message: 'Ga chưa có trong dữ liệu.',
                );
              }
              final s = matching.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.train_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Ga ${s.name}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text('Ga số ${s.order} · Tuyến Metro số 1'),
                  const SizedBox(height: 12),
                  MapsPreviewButton(
                    MapsUrlBuilder.directions(s.latitude, s.longitude),
                  ),
                  const SectionTitle('Lịch tàu tham khảo'),
                  DiscoveryAsync(
                    value: ref.watch(departuresProvider(order)),
                    retry: () => ref.invalidate(departuresProvider(order)),
                    data: ScheduleView.new,
                  ),
                  const SectionTitle('Địa điểm quanh ga'),
                  DiscoveryAsync(
                    value: ref.watch(clustersProvider),
                    retry: () => ref.invalidate(clustersProvider),
                    data: (clusters) {
                      final places = clusters
                          .where((c) => c.stationId == s.id)
                          .expand((c) => c.places)
                          .toList();
                      return places.isEmpty
                          ? const EmptyContent(
                              title: 'Chưa có địa điểm quanh ga',
                              message: 'Không có trong bộ dữ liệu mẫu.',
                            )
                          : Column(
                              children: places.map(PlaceTile.new).toList(),
                            );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
