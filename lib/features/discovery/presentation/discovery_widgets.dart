import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_failure.dart';
import '../../../shared/formatters.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/content_states.dart';
import '../../../shared/widgets/feedback_banner.dart';
import '../domain/discovery_models.dart';

class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Text(
      'M3 OFFLINE · Dữ liệu minh họa, chưa kết nối Backend.',
      style: TextStyle(
        color: Brand.navy,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );
}

class DiscoveryBody extends StatelessWidget {
  const DiscoveryBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const OfflineNotice(),
              ...children,
              const SizedBox(height: 24),
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
    padding: const EdgeInsets.only(top: 20, bottom: 12),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Brand.ink,
        ),
      ),
    ),
  );
}

class DiscoveryAsync<T> extends StatelessWidget {
  const DiscoveryAsync({
    super.key,
    required this.value,
    required this.retry,
    required this.data,
  });
  final AsyncValue<T> value;
  final VoidCallback retry;
  final Widget Function(T) data;
  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: false,
    data: data,
    loading: () => const LoadingContent(),
    error: (error, stack) {
      final failure = error is ApiFailure ? error : null;
      return ErrorContent(
        onRetry: retry,
        message: failure?.status == 404
            ? 'Dữ liệu chưa khả dụng trong bộ mẫu này.'
            : failure?.kind == FailureKind.validation
            ? failure!.fields.values.expand((e) => e).join('\n')
            : 'Chưa tải được dữ liệu mẫu. Vui lòng thử lại.',
      );
    },
  );
}

class PlaceMedia extends StatelessWidget {
  const PlaceMedia(this.url, {super.key, this.height = 160, this.category});
  final String? url;
  final double height;
  final String? category;
  @override
  Widget build(BuildContext context) {
    // M3 has no licensed place imagery; even supplied URLs stay offline.
    final icon = switch (category) {
      'Culture' => Icons.museum_outlined,
      'Cafe' => Icons.local_cafe_outlined,
      'Food' => Icons.restaurant_outlined,
      'Nature' => Icons.park_outlined,
      _ => Icons.location_on_outlined,
    };
    return Semantics(
      image: true,
      label: 'Chưa có ảnh địa điểm',
      child: ExcludeSemantics(
        child: Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8ECF7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 40, color: Brand.navy),
                  const SizedBox(height: 8),
                  const Text(
                    'Chưa có ảnh địa điểm',
                    style: TextStyle(color: Brand.navy),
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

String categoryLabel(String category) => switch (category) {
  'Culture' => 'Văn hóa',
  'Cafe' => 'Cà phê',
  'Food' => 'Ẩm thực',
  'Nature' => 'Thiên nhiên',
  _ => category,
};
String? costLabel(Place p) => p.costMin == null || p.costMax == null
    ? null
    : '${formatVnd(p.costMin!)} – ${formatVnd(p.costMax!)} đ (ước tính mẫu)';

class PlaceTile extends StatelessWidget {
  const PlaceTile(this.place, {super.key, this.compact = false});
  final Place place;
  final bool compact;
  @override
  Widget build(BuildContext context) => compact
      ? _compact(context)
      : Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFDCE2ED)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () =>
                  context.push('/places/${Uri.encodeComponent(place.id)}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlaceMedia(
                    place.imageUrl,
                    height: compact ? 106 : 160,
                    category: place.category,
                  ),
                  Padding(
                    padding: EdgeInsets.all(compact ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!compact)
                          Text(
                            categoryLabel(place.category),
                            style: const TextStyle(
                              color: Brand.navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          place.name,
                          style: compact
                              ? const TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Brand.ink,
                                  fontWeight: FontWeight.w700,
                                )
                              : Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (compact)
                          Text(
                            categoryLabel(place.category),
                            style: const TextStyle(fontSize: 11),
                          ),
                        if (!compact) Text(place.address),
                        if (place.stationName != null)
                          Text(
                            'Ga ${place.stationName}',
                            style: compact
                                ? const TextStyle(
                                    fontSize: 11,
                                    color: Brand.navy,
                                  )
                                : null,
                          ),
                        if (!compact && costLabel(place) != null)
                          Text(costLabel(place)!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

  Widget _compact(BuildContext context) => Card(
    key: ValueKey('place-card-${place.id}'),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push('/places/${Uri.encodeComponent(place.id)}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlaceMedia(place.imageUrl, height: 108, category: place.category),
          Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.textScalerOf(context).scale(12) *
                        19 /
                        12 *
                        2,
                  ),
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 19 / 12,
                      fontWeight: FontWeight.w700,
                      color: Brand.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  categoryLabel(place.category),
                  style: BrandTypography.metadata,
                ),
                if (place.stationName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.train_outlined,
                          size: 14,
                          color: Brand.navy,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Ga ${place.stationName}',
                          style: const TextStyle(
                            fontSize: 11,
                            height: 18 / 11,
                            fontWeight: FontWeight.w600,
                            color: Brand.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Two columns with intrinsic row heights so large text never clips a card.
class PlaceGrid extends StatelessWidget {
  const PlaceGrid(this.places, {super.key});
  final List<Place> places;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 12.0;
      final width = (constraints.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final place in places)
            SizedBox(width: width, child: PlaceTile(place, compact: true)),
        ],
      );
    },
  );
}

class CuratedTile extends StatelessWidget {
  const CuratedTile(this.trip, {super.key});
  final CuratedTrip trip;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OutlinedButton(
      onPressed: () => context.push('/curated/${Uri.encodeComponent(trip.id)}'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('${trip.durationMinutes} phút · Lịch trình mẫu'),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

class MapsPreviewButton extends StatelessWidget {
  const MapsPreviewButton(this.uri, {super.key});
  final Uri? uri;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    icon: const Icon(Icons.map_outlined),
    label: const Text('Xem liên kết Google Maps'),
    onPressed: uri == null
        ? null
        : () => showModalBottomSheet<void>(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            backgroundColor: Brand.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  20 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Chỉ đường Google Maps',
                            style: BrandTypography.sectionTitle,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đóng',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bản offline chỉ xem URL, không mở Google Maps.',
                      style: BrandTypography.body,
                    ),
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Brand.canvas,
                        border: Border.all(color: Brand.line),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          uri.toString(),
                          style: BrandTypography.metadata,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Đóng'),
                    ),
                  ],
                ),
              ),
            ),
          ),
  );
}

class ScheduleView extends StatelessWidget {
  const ScheduleView(this.schedule, {super.key});
  final MetroSchedule schedule;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FeedbackBanner(
        kind: schedule.withinPeriod
            ? FeedbackBannerKind.info
            : FeedbackBannerKind.warning,
        title: schedule.estimated
            ? 'Lịch tàu ước tính · Không phải trực tiếp'
            : 'Lịch mẫu · Không phải trực tiếp',
        message: !schedule.withinPeriod
            ? 'Ngoài khoảng hiệu lực. Không sử dụng để đón tàu.'
            : schedule.precision == 'Headway'
            ? 'Giãn cách là khoảng thời gian giữa các chuyến, không phải giờ tàu xuất bến chính xác.'
            : schedule.showExact
            ? 'Giờ dưới đây thuộc bộ dữ liệu mẫu, không phải cập nhật vận hành.'
            : 'Chưa đủ dữ liệu để xác định thời gian tàu chạy.',
      ),
      const SizedBox(height: 12),
      Text(
        'Ngày dữ liệu mẫu: ${schedule.date} (giờ Việt Nam)',
        style: BrandTypography.metadata,
      ),
      for (final direction in schedule.directions)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Brand.surface,
              border: Border.all(color: Brand.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.train_outlined,
                        size: 20,
                        color: Brand.navy,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hướng ${direction.toward}',
                          style: BrandTypography.choice.copyWith(
                            fontSize: 14,
                            color: Brand.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Brand.line),
                  if (schedule.showExact)
                    Text(
                      direction.departures.isEmpty
                          ? 'Chưa có chuyến.'
                          : direction.departures
                                .map((t) => t.substring(0, 5))
                                .join(' · '),
                      style: BrandTypography.body,
                    )
                  else if (schedule.precision == 'Headway' &&
                      schedule.withinPeriod) ...[
                    if (direction.headways.isEmpty)
                      const Text(
                        'Chưa có thông tin giãn cách trong bộ mẫu này.',
                        style: BrandTypography.body,
                      ),
                    for (final h in direction.headways)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '${h.from.substring(0, 5)}–${h.to.substring(0, 5)}: khoảng ${h.minutes} phút/chuyến',
                          style: BrandTypography.body.copyWith(fontSize: 14),
                        ),
                      ),
                  ] else
                    const Text(
                      'Chưa đủ dữ liệu lịch tàu để hiển thị.',
                      style: BrandTypography.body,
                    ),
                ],
              ),
            ),
          ),
        ),
      ExpansionTile(
        backgroundColor: Brand.canvas,
        collapsedBackgroundColor: Brand.canvas,
        textColor: Brand.ink,
        collapsedTextColor: Brand.ink,
        iconColor: Brand.navy,
        collapsedIconColor: Brand.navy,
        tilePadding: EdgeInsets.zero,
        title: const Text(
          'Thông tin bộ dữ liệu',
          style: BrandTypography.choice,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Độ chính xác: ${schedule.precision}',
                    style: BrandTypography.metadata,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hiệu lực: ${schedule.effectiveFrom} – ${schedule.effectiveTo ?? 'chưa có ngày kết thúc'}',
                    style: BrandTypography.metadata,
                  ),
                  if (schedule.notice != null) ...[
                    const SizedBox(height: 8),
                    Text(schedule.notice!, style: BrandTypography.metadata),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
