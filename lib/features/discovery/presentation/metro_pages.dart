import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/ui_providers.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/discovery_providers.dart';
import '../domain/discovery_models.dart';
import 'discovery_widgets.dart';
import 'station_picker.dart';

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
    final result = await showStationPicker(
      context: context,
      stations: stations,
      title: origin ? 'Chọn ga đi' : 'Chọn ga đến',
      selected: origin ? from : to,
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

  void swap() => setState(() {
    final previous = from;
    from = to;
    to = previous;
    applied = null;
  });

  @override
  Widget build(BuildContext context) => CustomScrollView(
    controller: scroll,
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    slivers: [
      const AppLargeTitleBar(title: 'Ga Metro', showBack: false),
      SliverToBoxAdapter(
        child: DiscoveryAsync(
          value: ref.watch(stationsProvider),
          retry: () => ref.invalidate(stationsProvider),
          loading: (_) => const _MetroSkeleton(),
          data: (stations) {
            if (stations.isEmpty) {
              return const AppEmptyState(
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
                _Gutter(child: _MetroOverview(count: stations.length)),
                const SizedBox(height: AppSpacing.lg),
                _Gutter(
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    expandedInsets: EdgeInsets.zero,
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        icon: Icon(LucideIcons.route, size: AppSizes.icon),
                        label: Text('Hành trình'),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: Icon(LucideIcons.trainFront, size: AppSizes.icon),
                        label: Text('Các ga'),
                      ),
                    ],
                    selected: {view},
                    onSelectionChanged: (selection) =>
                        changeView(selection.first),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (view == 0)
                  _Gutter(child: _journey(stations, pending))
                else
                  _catalog(stations),
                const SizedBox(height: AppSpacing.xl),
                _Gutter(
                  child: Text(
                    'Dữ liệu mẫu offline · Không phải thông tin vận hành trực tiếp.',
                    style: context.textStyles.bodySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            );
          },
        ),
      ),
    ],
  );

  Widget _journey(List<Station> stations, bool pending) {
    Station? find(int order) =>
        stations.where((s) => s.order == order).firstOrNull;
    final origin = find(from);
    final destination = find(to);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Bạn muốn đến ga nào?',
            style: context.textStyles.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  StationField(
                    inkKey: const ValueKey('metro-origin'),
                    label: 'Ga đi',
                    value: origin?.name ?? 'Chưa chọn ga',
                    order: origin?.order,
                    onTap: () => pickStation(stations, origin: true),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StationField(
                    inkKey: const ValueKey('metro-destination'),
                    label: 'Ga đến',
                    value: destination?.name ?? 'Chưa chọn ga',
                    order: destination?.order,
                    onTap: () => pickStation(stations, origin: false),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppIconButton(
              icon: LucideIcons.arrowUpDown,
              tooltip: 'Đổi ga đi và ga đến',
              variant: AppIconButtonVariant.tonal,
              onPressed: swap,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (from == to) ...[
          const AppBanner(
            kind: BannerKind.warning,
            message: 'Chọn hai ga khác nhau.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppButton(
          label: pending ? 'Đang xem dữ liệu mẫu…' : 'Xem hành trình mẫu',
          icon: LucideIcons.route,
          loading: pending,
          expand: true,
          onPressed: from == to || pending
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  setState(() => applied = (from: from, to: to));
                },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (applied case final selection?)
          _JourneyResult(
            key: ValueKey(selection),
            selection: selection,
            onExample: useExample,
            onStations: () => changeView(1),
          )
        else
          const AppBanner(
            message: 'Bản offline hiện có ví dụ Bến Thành – Nhà hát Thành phố. Các ga khác vẫn có lịch tàu và địa điểm mẫu để tham khảo.',
          ),
      ],
    );
  }

  Widget _catalog(List<Station> stations) {
    final matching = matchingStations(stations, query.text);
    void open(int order) {
      FocusScope.of(context).unfocus();
      context.push('/stations/$order');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MetroLineDiagram(
          stations: [
            for (final s in stations) MetroStop(order: s.order, name: s.name),
          ],
          onSelect: (s) => open(s.order),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Gutter(
          child: AppSearchBar(
            fieldKey: const Key('metro-station-search'),
            hint: 'Tìm tên hoặc số ga',
            controller: query,
            onChanged: (_) => setState(() {}),
            onClear: () => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Gutter(
          child: Text(
            'Khám phá quanh ga · ${matching.length}/${stations.length} ga',
            style: context.textStyles.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (matching.isEmpty)
          AppEmptyState(
            compact: true,
            title: 'Không tìm thấy ga',
            message: 'Thử tên không dấu hoặc số ga từ 1 đến 14.',
            actionLabel: 'Xem tất cả ga',
            onAction: () => setState(query.clear),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Column(
            children: [
              for (var i = 0; i < matching.length; i++)
                StaggeredEntrance(
                  index: i,
                  child: StationTile(
                    title: matching[i].name,
                    subtitle: 'Lịch tàu & địa điểm quanh ga',
                    leading: StationBadge(order: matching[i].order),
                    onTap: () => open(matching[i].order),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Gutter extends StatelessWidget {
  const _Gutter({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

class _MetroSkeleton extends StatelessWidget {
  const _MetroSkeleton();

  @override
  Widget build(BuildContext context) => const _Gutter(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonBlock(height: AppSpacing.xxxl * 2, radius: AppRadius.lg),
        SizedBox(height: AppSpacing.lg),
        SkeletonBlock(height: AppSizes.minTouchTarget, radius: AppRadius.md),
        SizedBox(height: AppSpacing.xl),
        SkeletonBlock(height: AppSizes.thumb, radius: AppRadius.md),
        SizedBox(height: AppSpacing.sm),
        SkeletonBlock(height: AppSizes.thumb, radius: AppRadius.md),
      ],
    ),
  );
}

class _MetroOverview extends ConsumerWidget {
  const _MetroOverview({required this.count});
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = context.appColors;
    final text = context.textStyles;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [app.heroStart, app.heroEnd],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: AppSizes.avatar,
              height: AppSizes.avatar,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: app.onHero,
                borderRadius: AppRadius.control,
              ),
              child: Text(
                '1',
                style: text.titleLarge?.copyWith(color: app.heroStart),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bến Thành – Suối Tiên',
                    style: text.titleMedium?.copyWith(color: app.onHero),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Tuyến Metro số 1 · $count ga'
                    '${ref.watch(mockDataProvider) ? ' · Offline' : ''}',
                    style: text.bodySmall?.copyWith(color: app.onHero),
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
        loading: () => const Column(
          children: [
            SkeletonBlock(height: AppSpacing.xxxl * 2, radius: AppRadius.lg),
            SizedBox(height: AppSpacing.md),
            SkeletonBlock(height: AppSpacing.xxxl, radius: AppRadius.md),
          ],
        ),
        error: (error, _) => error is ApiFailure && error.status == 404
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppBanner(
                    kind: BannerKind.warning,
                    title: 'Cặp ga này chưa có hành trình mẫu',
                    message: 'Không có thời gian di chuyển hay giờ tàu đã xác minh cho lựa chọn này. Bạn có thể xem ví dụ có sẵn hoặc lịch tham khảo tại từng ga.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.secondary(
                    label: 'Dùng ví dụ Bến Thành – Nhà hát Thành phố',
                    icon: LucideIcons.route,
                    onPressed: onExample,
                  ),
                  AppButton.ghost(
                    label: 'Xem lịch tại từng ga',
                    onPressed: onStations,
                  ),
                ],
              )
            : isOffline(ref)
            ? AppOfflineState(
                compact: true,
                onRetry: () => ref.invalidate(journeyProvider(selection)),
              )
            : AppErrorState(
                compact: true,
                title: 'Không thể tải hành trình',
                message: 'Chưa tải được hành trình mẫu. Lựa chọn ga vẫn được giữ nguyên.',
                onRetry: () => ref.invalidate(journeyProvider(selection)),
              ),
        data: JourneyView.new,
      );
}

/// Journey summary: board/alight stations on a rail, duration, then the
/// schedule with its precision rules.
class JourneyView extends StatelessWidget {
  const JourneyView(this.journey, {super.key});
  final MetroJourney journey;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final app = context.appColors;
    final text = context.textStyles;
    return Column(
      key: const ValueKey('metro-journey-result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: scheme.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Semantics(
              container: true,
              label:
                  'Hành trình từ ${journey.from} đến ${journey.to}, ${journey.minutes} phút',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _JourneyStop(name: journey.from, label: 'Lên tàu'),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.md),
                      child: SizedBox(
                        height: AppSpacing.xl,
                        child: Row(
                          children: [
                            Container(
                              width: AppSizes.railWidth * 2,
                              color: app.metroLine,
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Text(
                                '${journey.minutes} phút · ${journey.stopCount} chặng (ước tính mẫu)',
                                style: text.labelMedium?.copyWith(
                                  color: app.metroLine,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _JourneyStop(name: journey.to, label: 'Xuống tàu'),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ScheduleView(journey.schedule),
        if (journey.schedule.showExact && journey.trips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in journey.trips)
                StatusChip(
                  label:
                      '${t.departure.substring(0, 5)} – ${t.arrival.substring(0, 5)} (lịch mẫu)',
                  kind: StatusKind.info,
                ),
            ],
          ),
        ] else if (journey.schedule.precision == 'Headway' &&
            journey.schedule.withinPeriod)
          for (final h in journey.headways)
            HeadwayRow(from: h.from, to: h.to, minutes: h.minutes),
      ],
    );
  }
}

class _JourneyStop extends StatelessWidget {
  const _JourneyStop({required this.name, required this.label});
  final String name;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: AppSpacing.xl + AppSpacing.xs,
        height: AppSpacing.xl + AppSpacing.xs,
        decoration: BoxDecoration(
          color: context.colors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: context.appColors.metroLine,
            width: AppSizes.railWidth,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.textStyles.bodySmall),
            Text(name, style: context.textStyles.titleSmall),
          ],
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
    appBar: const AppTopBar(title: 'Chi tiết ga'),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DiscoveryAsync(
            value: ref.watch(stationsProvider),
            retry: () => ref.invalidate(stationsProvider),
            loading: (_) => const _MetroSkeleton(),
            data: (stations) {
              final matching = stations.where((s) => s.order == order);
              if (matching.isEmpty) {
                return const AppEmptyState(
                  title: 'Không tìm thấy ga',
                  message: 'Ga chưa có trong dữ liệu.',
                );
              }
              final s = matching.first;
              final app = context.appColors;
              final text = context.textStyles;
              return _Gutter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.card,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [app.heroStart, app.heroEnd],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TUYẾN SỐ 1 · GA ${s.order}/${stations.length}',
                              style: text.labelSmall?.copyWith(
                                color: app.onHero,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Semantics(
                              header: true,
                              child: Text(
                                'Ga ${s.name}',
                                style: text.headlineSmall?.copyWith(
                                  color: app.onHero,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Lịch tàu và khám phá địa điểm quanh ga',
                              style: text.bodySmall?.copyWith(
                                color: app.onHero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MapsPreviewButton(
                      MapsUrlBuilder.directions(s.latitude, s.longitude),
                      expand: true,
                    ),
                    const SectionTitle('Lịch tàu tham khảo'),
                    DiscoveryAsync(
                      value: ref.watch(departuresProvider(order)),
                      retry: () => ref.invalidate(departuresProvider(order)),
                      compact: true,
                      data: ScheduleView.new,
                    ),
                    const SectionTitle('Địa điểm quanh ga'),
                    DiscoveryAsync(
                      value: ref.watch(clustersProvider),
                      retry: () => ref.invalidate(clustersProvider),
                      compact: true,
                      loading: (_) => const PlaceCardsSkeleton(),
                      data: (clusters) {
                        final places = flattenClusters(
                          clusters.where((c) => c.stationId == s.id).toList(),
                        );
                        return places.isEmpty
                            ? const AppEmptyState(
                                compact: true,
                                title: 'Chưa có địa điểm quanh ga',
                                message: 'Không có trong bộ dữ liệu mẫu.',
                              )
                            : PlaceGrid(places);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const OfflineNotice(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
