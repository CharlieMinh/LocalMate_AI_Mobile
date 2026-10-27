import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_failure.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/content_container.dart';
import '../../../shared/widgets/content_states.dart';
import '../../../shared/widgets/feedback_banner.dart';
import '../application/discovery_providers.dart';
import '../domain/discovery_models.dart';
import 'discovery_widgets.dart';

class MetroPage extends ConsumerStatefulWidget {
  const MetroPage({super.key});
  @override
  ConsumerState<MetroPage> createState() => _MetroPageState();
}

class _MetroPageState extends ConsumerState<MetroPage> {
  int from = 1, to = 2, view = 0;
  final query = TextEditingController();
  final scroll = ScrollController();
  ({int from, int to})? applied;

  @override
  void dispose() {
    query.dispose();
    scroll.dispose();
    super.dispose();
  }

  void changeView(int next) {
    FocusScope.of(context).unfocus();
    if (scroll.hasClients) scroll.jumpTo(0);
    setState(() => view = next);
  }

  Future<void> pickStation(
    List<Station> stations, {
    required bool origin,
  }) async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Brand.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _StationPickerSheet(
        stations: stations,
        title: origin ? 'Chọn ga đi' : 'Chọn ga đến',
        selected: origin ? from : to,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (origin) {
        from = result;
      } else {
        to = result;
      }
      applied = null;
    });
  }

  void useExample() => setState(() {
    from = 1;
    to = 2;
    applied = (from: 1, to: 2);
  });

  @override
  Widget build(BuildContext context) => ListView(
    controller: scroll,
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: EdgeInsets.zero,
    children: [
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
          final pending =
              view == 0 &&
              applied != null &&
              ref.watch(journeyProvider(applied!)).isLoading;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MetroOverview(count: stations.length),
              ContentContainer(
                verticalPadding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      expandedInsets: EdgeInsets.zero,
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.route_outlined),
                          label: Text('Hành trình'),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.train_outlined),
                          label: Text('Các ga'),
                        ),
                      ],
                      selected: {view},
                      onSelectionChanged: (selection) =>
                          changeView(selection.first),
                      style: const ButtonStyle(
                        minimumSize: WidgetStatePropertyAll(Size(48, 48)),
                        textStyle: WidgetStatePropertyAll(
                          TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (view == 0) ...[
                      const Text(
                        'Bạn muốn đến ga nào?',
                        style: BrandTypography.sectionTitle,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _StationField(
                                  label: 'Ga đi',
                                  station: stations
                                      .where((s) => s.order == from)
                                      .firstOrNull,
                                  onTap: () =>
                                      pickStation(stations, origin: true),
                                ),
                                const SizedBox(height: 12),
                                _StationField(
                                  label: 'Ga đến',
                                  station: stations
                                      .where((s) => s.order == to)
                                      .firstOrNull,
                                  onTap: () =>
                                      pickStation(stations, origin: false),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            tooltip: 'Đổi ga đi và ga đến',
                            onPressed: () => setState(() {
                              final previous = from;
                              from = to;
                              to = previous;
                              applied = null;
                            }),
                            icon: const Icon(Icons.swap_vert),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (from == to) ...[
                        const FeedbackBanner(
                          kind: FeedbackBannerKind.warning,
                          message: 'Chọn hai ga khác nhau.',
                        ),
                        const SizedBox(height: 16),
                      ],
                      FilledButton.icon(
                        onPressed: from == to || pending
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                setState(() => applied = (from: from, to: to));
                              },
                        icon: pending
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.route_outlined),
                        label: Text(
                          pending
                              ? 'Đang xem dữ liệu mẫu…'
                              : 'Xem hành trình mẫu',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (applied case final selection?)
                        _JourneyResult(
                          key: ValueKey(selection),
                          selection: selection,
                          onExample: useExample,
                          onStations: () => changeView(1),
                        )
                      else
                        const FeedbackBanner(
                          message: 'Bản offline hiện có ví dụ Bến Thành → Nhà hát Thành phố. Các ga khác vẫn có lịch tàu và địa điểm mẫu để tham khảo.',
                        ),
                    ] else
                      _catalog(stations),
                    const SizedBox(height: 24),
                    const Text(
                      'Dữ liệu mẫu offline · Không phải thông tin vận hành trực tiếp.',
                      style: BrandTypography.metadata,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ],
  );

  Widget _catalog(List<Station> stations) {
    final matching = _matchingStations(stations, query.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('metro-station-search'),
          controller: query,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Tìm tên hoặc số ga',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm ga',
                    onPressed: () => setState(query.clear),
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Khám phá quanh ga · ${matching.length}/${stations.length} ga',
          style: BrandTypography.metadata,
        ),
        const SizedBox(height: 8),
        if (matching.isEmpty) ...[
          const EmptyContent(
            icon: Icons.search_off,
            title: 'Không tìm thấy ga',
            message: 'Thử tên không dấu hoặc số ga từ 1 đến 14.',
          ),
          TextButton(
            onPressed: () => setState(query.clear),
            child: const Text('Xem tất cả ga'),
          ),
        ],
        for (final station in matching)
          _StationRow(
            station: station,
            onTap: () {
              FocusScope.of(context).unfocus();
              context.push('/stations/${station.order}');
            },
          ),
      ],
    );
  }
}

class _MetroOverview extends StatelessWidget {
  const _MetroOverview({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Brand.infoSurface,
    child: ContentContainer(
      verticalPadding: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1679C5),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              '1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bến Thành – Suối Tiên',
                  style: BrandTypography.sectionTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tuyến Metro số 1 · $count ga · Offline',
                  style: BrandTypography.metadata,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _JourneyResult extends ConsumerWidget {
  const _JourneyResult({
    super.key,
    required this.selection,
    required this.onExample,
    required this.onStations,
  });
  final ({int from, int to}) selection;
  final VoidCallback onExample, onStations;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(journeyProvider(selection))
      .when(
        skipLoadingOnRefresh: false,
        loading: () => const LoadingContent(label: 'Đang xem hành trình mẫu…'),
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error is ApiFailure && error.status == 404) ...[
              const FeedbackBanner(
                kind: FeedbackBannerKind.warning,
                title: 'Cặp ga này chưa có hành trình mẫu',
                message: 'Không có thời gian di chuyển hay giờ tàu đã xác minh cho lựa chọn này. Bạn có thể xem ví dụ có sẵn hoặc lịch tham khảo tại từng ga.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onExample,
                icon: const Icon(Icons.route_outlined),
                label: const Text('Dùng ví dụ Bến Thành → Nhà hát Thành phố'),
              ),
              TextButton(
                onPressed: onStations,
                child: const Text('Xem lịch tại từng ga'),
              ),
            ] else
              ErrorContent(
                message: 'Chưa tải được hành trình mẫu. Lựa chọn ga vẫn được giữ nguyên.',
                onRetry: () => ref.invalidate(journeyProvider(selection)),
              ),
          ],
        ),
        data: JourneyView.new,
      );
}

class _StationField extends StatelessWidget {
  const _StationField({
    required this.label,
    required this.station,
    required this.onTap,
  });
  final String label;
  final Station? station;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label: ${station?.name ?? 'Chưa chọn ga'}',
    excludeSemantics: true,
    onTap: onTap,
    child: Material(
      color: Brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Brand.secondaryBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey(label == 'Ga đi' ? 'metro-origin' : 'metro-destination'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: BrandTypography.metadata),
                    const SizedBox(height: 4),
                    Text(
                      station?.name ?? 'Chưa chọn ga',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Brand.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more, size: 20, color: Brand.navy),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StationPickerSheet extends StatefulWidget {
  const _StationPickerSheet({
    required this.stations,
    required this.title,
    required this.selected,
  });
  final List<Station> stations;
  final String title;
  final int selected;
  @override
  State<_StationPickerSheet> createState() => _StationPickerSheetState();
}

class _StationPickerSheetState extends State<_StationPickerSheet> {
  final query = TextEditingController();
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matching = _matchingStations(widget.stations, query.text);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .8,
        minChildSize: .5,
        maxChildSize: .95,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: BrandTypography.sectionTitle,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng chọn ga',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('metro-picker-search'),
                controller: query,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm tên hoặc số ga',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm ga',
                          onPressed: () => setState(query.clear),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: controller,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  if (matching.isEmpty)
                    const EmptyContent(
                      icon: Icons.search_off,
                      title: 'Không tìm thấy ga',
                      message: 'Thử tên không dấu hoặc số ga từ 1 đến 14.',
                    ),
                  for (final station in matching)
                    _StationRow(
                      station: station,
                      selected: station.order == widget.selected,
                      picking: true,
                      onTap: () => Navigator.pop(context, station.order),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationRow extends StatelessWidget {
  const _StationRow({
    required this.station,
    required this.onTap,
    this.selected = false,
    this.picking = false,
  });
  final Station station;
  final VoidCallback onTap;
  final bool selected, picking;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? Brand.infoSurface : Brand.surface,
    child: ListTile(
      selected: selected,
      tileColor: selected ? Brand.infoSurface : Brand.surface,
      selectedTileColor: Brand.infoSurface,
      shape: const Border(bottom: BorderSide(color: Brand.line)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: selected ? Brand.navy : Brand.infoSurface,
        foregroundColor: selected ? Colors.white : Brand.navy,
        child: Text(
          '${station.order}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        station.name,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Brand.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        picking
            ? 'Ga số ${station.order} · Tuyến số 1'
            : 'Lịch tàu & địa điểm quanh ga',
        style: BrandTypography.metadata,
      ),
      trailing: Icon(
        selected
            ? Icons.check_circle
            : picking
            ? Icons.circle_outlined
            : Icons.chevron_right,
        size: 20,
        color: Brand.navy,
      ),
      onTap: onTap,
    ),
  );
}

List<Station> _matchingStations(List<Station> stations, String input) {
  final keyword = _stationSearchKey(input);
  return stations
      .where(
        (station) =>
            keyword.isEmpty ||
            _stationSearchKey(station.name).contains(keyword) ||
            station.order.toString() == keyword,
      )
      .toList();
}

String _stationSearchKey(String input) {
  var result = input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final group in groups.entries) {
    result = result.replaceAll(RegExp('[${group.value}]'), group.key);
  }
  return result;
}

class JourneyView extends StatelessWidget {
  const JourneyView(this.journey, {super.key});
  final MetroJourney journey;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Divider(height: 24, color: Brand.line),
      Text(
        '${journey.from} → ${journey.to}',
        style: BrandTypography.sectionTitle,
      ),
      const SizedBox(height: 8),
      Text(
        '${journey.minutes} phút · ${journey.stopCount} chặng (ước tính mẫu)',
        style: BrandTypography.body,
      ),
      const SizedBox(height: 16),
      ScheduleView(journey.schedule),
      if (journey.schedule.showExact)
        for (final t in journey.trips)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${t.departure.substring(0, 5)} → ${t.arrival.substring(0, 5)} (lịch mẫu)',
              style: BrandTypography.body,
            ),
          )
      else if (journey.schedule.precision == 'Headway' &&
          journey.schedule.withinPeriod)
        for (final h in journey.headways)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${h.from.substring(0, 5)}–${h.to.substring(0, 5)}: khoảng ${h.minutes} phút/chuyến',
              style: BrandTypography.body,
            ),
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
      top: false,
      child: ListView(
        padding: EdgeInsets.zero,
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
                  ColoredBox(
                    color: Brand.infoSurface,
                    child: ContentContainer(
                      verticalPadding: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TUYẾN SỐ 1 · GA ${s.order}/${stations.length}',
                            style: BrandTypography.metadata.copyWith(
                              color: Brand.navy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ga ${s.name}',
                            style: BrandTypography.screenTitle,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Lịch tàu và khám phá địa điểm quanh ga',
                            style: BrandTypography.body,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ContentContainer(
                    verticalPadding: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MapsPreviewButton(
                          MapsUrlBuilder.directions(s.latitude, s.longitude),
                        ),
                        const SectionTitle('Lịch tàu tham khảo'),
                        DiscoveryAsync(
                          value: ref.watch(departuresProvider(order)),
                          retry: () =>
                              ref.invalidate(departuresProvider(order)),
                          data: ScheduleView.new,
                        ),
                        const SectionTitle('Địa điểm quanh ga'),
                        DiscoveryAsync(
                          value: ref.watch(clustersProvider),
                          retry: () => ref.invalidate(clustersProvider),
                          data: (clusters) {
                            final places = flattenClusters(
                              clusters
                                  .where((c) => c.stationId == s.id)
                                  .toList(),
                            );
                            return places.isEmpty
                                ? const EmptyContent(
                                    icon: Icons.place_outlined,
                                    title: 'Chưa có địa điểm quanh ga',
                                    message: 'Không có trong bộ dữ liệu mẫu.',
                                  )
                                : PlaceGrid(places);
                          },
                        ),
                        const SizedBox(height: 16),
                        const OfflineNotice(),
                      ],
                    ),
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
