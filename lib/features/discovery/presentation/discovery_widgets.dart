import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/ui_providers.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/api_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/formatters.dart';
import '../domain/discovery_models.dart';

/// Small honest tag shown on screens backed by fixture data (mock builds).
class OfflineNotice extends ConsumerWidget {
  const OfflineNotice({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(mockDataProvider)) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Align(
        alignment: Alignment.centerLeft,
        child: StatusChip(
          label: 'Dữ liệu minh họa',
          icon: LucideIcons.flaskConical,
        ),
      ),
    );
  }
}

class DiscoveryBody extends StatelessWidget {
  const DiscoveryBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.gutter),
    children: [
      Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const OfflineNotice(),
              ...children,
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
    child: Semantics(
      header: true,
      child: Text(title, style: context.textStyles.titleMedium),
    ),
  );
}

/// Maps an AsyncValue onto skeleton / data / error / offline states.
/// Error copy keeps the contract mapping (404 vs validation vs generic).
class DiscoveryAsync<T> extends ConsumerWidget {
  const DiscoveryAsync({
    super.key,
    required this.value,
    required this.retry,
    required this.data,
    this.loading,
    this.compact = false,
  });
  final AsyncValue<T> value;
  final VoidCallback retry;
  final Widget Function(T) data;

  /// Skeleton mirroring the loaded layout; defaults to generic blocks.
  final WidgetBuilder? loading;
  final bool compact;

  static String errorMessage(Object error, {bool mock = true}) {
    final failure = error is ApiFailure ? error : null;
    if (failure == null) return 'Chưa tải được dữ liệu. Vui lòng thử lại.';
    if (failure.status == 404 && failure.code == null) {
      return mock
          ? 'Dữ liệu chưa khả dụng trong bộ mẫu này.'
          : 'Dữ liệu không còn khả dụng.';
    }
    return apiErrorMessage(failure);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => value.when(
    skipLoadingOnRefresh: false,
    data: data,
    loading: () => loading?.call(context) ?? const _GenericSkeleton(),
    error: (error, stack) =>
        isOffline(ref) ||
            (error is ApiFailure && error.kind == FailureKind.offline)
        ? AppOfflineState(onRetry: retry, compact: compact)
        : AppErrorState(
            title: 'Không thể tải dữ liệu',
            message: errorMessage(error, mock: ref.watch(mockDataProvider)),
            onRetry: retry,
            compact: compact,
          ),
  );
}

class _GenericSkeleton extends StatelessWidget {
  const _GenericSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBlock(height: AppSpacing.lg, width: AppSizes.placeCardWidth),
        SizedBox(height: AppSpacing.md),
        SkeletonBlock(height: AppSizes.thumb, radius: AppRadius.md),
        SizedBox(height: AppSpacing.md),
        SkeletonBlock(height: AppSizes.thumb, radius: AppRadius.md),
      ],
    ),
  );
}

PlaceCategoryTone placeTone(String category) => switch (category) {
  'Cafe' => PlaceCategoryTone.cafe,
  'Food' => PlaceCategoryTone.food,
  'Culture' => PlaceCategoryTone.culture,
  'CheckIn' => PlaceCategoryTone.checkIn,
  _ => PlaceCategoryTone.other,
};

String categoryLabel(String category) => switch (category) {
  'Culture' => 'Văn hóa',
  'Cafe' => 'Cà phê',
  'Food' => 'Ẩm thực',
  'CheckIn' => 'Check-in',
  'Nature' => 'Thiên nhiên',
  _ => category,
};

/// Backend place categories (`master-data.placeCategories`).
const placeCategories = ['Cafe', 'Food', 'Culture', 'CheckIn'];

String? costLabel(Place p) {
  if (p.costMin == null || p.costMax == null) return null;
  if (p.costMin == 0 && p.costMax == 0) return 'Miễn phí';
  return '${formatVnd(p.costMin!)}đ – ${formatVnd(p.costMax!)}đ';
}

String durationLabel(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m phút';
  return m == 0 ? '$h giờ' : '$h giờ $m phút';
}

String distanceLabel(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';

Object placeHeroTag(String id) => 'place-image-$id';

/// A place plus the station it was listed under (clusters carry the
/// station at group level, details carry it on the place).
typedef PlaceEntry = ({Place place, String? stationName, int? stationOrder});

List<PlaceEntry> flattenClusters(List<StationCluster> clusters) {
  final seen = <String>{};
  return [
    for (final c in clusters)
      for (final p in c.places)
        if (seen.add(p.id))
          (
            place: p,
            stationName: p.stationName ?? c.stationName,
            stationOrder: p.stationOrder ?? c.stationOrder,
          ),
  ];
}

List<PlaceEntry> placeEntries(List<Place> places) => [
  for (final p in places)
    (place: p, stationName: p.stationName, stationOrder: p.stationOrder),
];

class DiscoveryPlaceCard extends ConsumerWidget {
  const DiscoveryPlaceCard(this.entry, {super.key, this.width});
  final PlaceEntry entry;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = entry.place;
    return PlaceCard(
      key: ValueKey('place-card-${p.id}'),
      width: width,
      name: p.name,
      categoryLabel: categoryLabel(p.category),
      tone: placeTone(p.category),
      stationName: entry.stationName == null ? null : 'Ga ${entry.stationName}',
      stationOrder: entry.stationOrder,
      imageUrl: ref.watch(remoteImagesProvider) ? p.imageUrl : null,
      heroTag: placeHeroTag(p.id),
      onTap: () => context.push('/places/${Uri.encodeComponent(p.id)}'),
    );
  }
}

/// Responsive grid (2 columns on phones, 3 on tablets). Rows size to their
/// content so large text never clips a card.
class PlaceGrid extends StatelessWidget {
  const PlaceGrid(this.entries, {super.key, this.animate = true});
  final List<PlaceEntry> entries;
  final bool animate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = AppSpacing.md;
      const tablet = 600.0;
      final columns = constraints.maxWidth >= tablet ? 3 : 2;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var i = 0; i < entries.length; i++)
            SizedBox(
              width: width,
              child: animate
                  ? StaggeredEntrance(
                      index: i,
                      child: DiscoveryPlaceCard(entries[i]),
                    )
                  : DiscoveryPlaceCard(entries[i]),
            ),
        ],
      );
    },
  );
}

/// Placeholder cards shown while place lists load.
class PlaceCardsSkeleton extends StatelessWidget {
  const PlaceCardsSkeleton({super.key, this.horizontal = false});
  final bool horizontal;

  static const _count = 4;

  @override
  Widget build(BuildContext context) {
    Widget card(int i) => PlaceCard(
      width: horizontal ? AppSizes.placeCardWidth : null,
      name: 'Tên địa điểm đang tải',
      categoryLabel: 'Danh mục',
      tone: PlaceCategoryTone.values[i % PlaceCategoryTone.values.length],
      stationName: 'Ga Metro',
    );
    return AppSkeleton(
      enabled: true,
      child: horizontal
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _count; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    card(i),
                  ],
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, c) {
                final width = (c.maxWidth - AppSpacing.md) / 2;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (var i = 0; i < _count; i++)
                      SizedBox(width: width, child: card(i)),
                  ],
                );
              },
            ),
    );
  }
}

class CuratedTile extends StatelessWidget {
  const CuratedTile(this.trip, {super.key});
  final CuratedTrip trip;
  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = context.textStyles;
    final meta = [
      durationLabel(trip.durationMinutes),
      if (trip.items.isNotEmpty) '${trip.items.length} điểm dừng',
      if (trip.stationName != null) 'Ga ${trip.stationName}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: scheme.outline),
        ),
        child: Pressable(
          onTap: () => context.push('/curated/${Uri.encodeComponent(trip.id)}'),
          semanticLabel: '${trip.title}, lịch trình mẫu, $meta',
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: AppSizes.avatar,
                    height: AppSizes.avatar,
                    decoration: BoxDecoration(
                      color: context.appColors.metroLineContainer,
                      borderRadius: AppRadius.control,
                    ),
                    child: Icon(
                      LucideIcons.route,
                      color: context.appColors.metroLine,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip.title, style: text.titleSmall),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(meta, style: text.bodySmall),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: AppSizes.icon,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Planner call-to-action card used at the end of discovery lists.
class PlannerPromoCard extends ConsumerWidget {
  const PlannerPromoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(mockDataProvider)
        ? 'để xem lịch trình mẫu.'
        : 'để tạo lịch trình riêng.';
    final scheme = context.colors;
    final text = context.textStyles;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            context.appColors.metroLineContainer,
          ],
        ),
      ),
      child: Pressable(
        onTap: () => context.push('/planner'),
        haptic: true,
        semanticLabel:
            'Dành một buổi cho chính mình. Chọn điểm xuất phát và thời gian rảnh $goal',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: AppSizes.avatar,
                  height: AppSizes.avatar,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.sparkles, color: scheme.onPrimary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dành một buổi cho chính mình',
                        style: text.titleSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Chọn điểm xuất phát và thời gian rảnh $goal',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.arrowRight, color: scheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Live builds open Google Maps; the mock build only shows the link.
class MapsPreviewButton extends ConsumerWidget {
  const MapsPreviewButton(this.uri, {super.key, this.expand = false});
  final Uri? uri;
  final bool expand;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await ref.read(externalUrlOpenerProvider)(uri!);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Chưa mở được Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppButton.secondary(
    label: ref.watch(mockDataProvider)
        ? 'Xem liên kết Google Maps'
        : 'Chỉ đường bằng Google Maps',
    icon: LucideIcons.map,
    expand: expand,
    onPressed: uri == null
        ? null
        : !ref.watch(mockDataProvider)
        ? () => _open(context, ref)
        : () => showAppBottomSheet<void>(
            context: context,
            title: 'Chỉ đường Google Maps',
            builder: (sheetContext) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bản offline chỉ xem URL, không mở Google Maps.',
                  style: sheetContext.textStyles.bodyMedium?.copyWith(
                    color: sheetContext.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: sheetContext.colors.surfaceContainer,
                    borderRadius: AppRadius.control,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SelectableText(
                      uri.toString(),
                      style: sheetContext.textStyles.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Builder(
                builder: (c) => AppButton(
                  label: 'Đóng',
                  icon: LucideIcons.check,
                  expand: true,
                  onPressed: () => Navigator.of(c).pop(),
                ),
              ),
            ],
          ),
  );
}

class ScheduleView extends ConsumerWidget {
  const ScheduleView(this.schedule, {super.key});
  final MetroSchedule schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mock = ref.watch(mockDataProvider);
    final scheme = context.colors;
    final app = context.appColors;
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBanner(
          kind: schedule.withinPeriod ? BannerKind.info : BannerKind.warning,
          title: schedule.estimated
              ? 'Lịch tàu ước tính · Không phải trực tiếp'
              : mock
              ? 'Lịch mẫu · Không phải trực tiếp'
              : 'Lịch dự kiến · Không phải trực tiếp',
          message: !schedule.withinPeriod
              ? 'Ngoài khoảng hiệu lực. Không sử dụng để đón tàu.'
              : schedule.precision == 'Headway'
              ? 'Giãn cách là khoảng thời gian giữa các chuyến, không phải giờ tàu xuất bến chính xác.'
              : schedule.showExact
              ? (mock
                    ? 'Giờ dưới đây thuộc bộ dữ liệu mẫu, không phải cập nhật vận hành.'
                    : 'Giờ dưới đây là lịch dự kiến, có thể lệch so với vận hành thực tế.')
              : 'Chưa đủ dữ liệu để xác định thời gian tàu chạy.',
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          mock
              ? 'Ngày dữ liệu mẫu: ${schedule.date} (giờ Việt Nam)'
              : 'Lịch áp dụng ngày ${schedule.date} (giờ Việt Nam)',
          style: text.bodySmall,
        ),
        for (final direction in schedule.directions)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(color: scheme.outline),
                borderRadius: AppRadius.card,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: app.metroLineContainer,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(AppRadius.xs),
                            ),
                          ),
                          child: Icon(
                            LucideIcons.trainFront,
                            size: AppSizes.iconSm,
                            color: app.metroLine,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Hướng ${direction.toward}',
                            style: text.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.xl),
                    if (schedule.showExact)
                      direction.departures.isEmpty
                          ? Text('Chưa có chuyến.', style: text.bodyMedium)
                          : Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                for (final t in direction.departures)
                                  StatusChip(
                                    label: t.substring(0, 5),
                                    kind: StatusKind.info,
                                  ),
                              ],
                            )
                    else if (schedule.precision == 'Headway' &&
                        schedule.withinPeriod) ...[
                      if (direction.headways.isEmpty)
                        Text(
                          mock
                              ? 'Chưa có thông tin giãn cách trong bộ mẫu này.'
                              : 'Chưa có thông tin giãn cách.',
                          style: text.bodyMedium,
                        ),
                      for (final h in direction.headways)
                        HeadwayRow(from: h.from, to: h.to, minutes: h.minutes),
                    ] else
                      Text(
                        'Chưa đủ dữ liệu lịch tàu để hiển thị.',
                        style: text.bodyMedium,
                      ),
                  ],
                ),
              ),
            ),
          ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text('Thông tin bộ dữ liệu', style: text.labelLarge),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Độ chính xác: ${schedule.precision}',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Hiệu lực: ${schedule.effectiveFrom} – ${schedule.effectiveTo ?? 'chưa có ngày kết thúc'}',
                        style: text.bodySmall,
                      ),
                      if (schedule.notice != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(schedule.notice!, style: text.bodySmall),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "06:00–08:00: khoảng 8 phút/chuyến" with a clock icon.
class HeadwayRow extends StatelessWidget {
  const HeadwayRow({
    super.key,
    required this.from,
    required this.to,
    required this.minutes,
  });
  final String from;
  final String to;
  final int minutes;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Icon(
          LucideIcons.clock,
          size: AppSizes.iconSm,
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '${from.substring(0, 5)}–${to.substring(0, 5)}: khoảng $minutes phút/chuyến',
            style: context.textStyles.bodyMedium,
          ),
        ),
      ],
    ),
  );
}
