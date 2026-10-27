import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/formatters.dart';
import '../../discovery/data/station_fixture_data.dart';
import '../application/planner_controller.dart';
import '../data/offline_planner_repository.dart';
import '../domain/planner_criteria.dart';
import 'planner_format.dart';

/// Draft itinerary ("Lịch trình nháp") for the current local preview.
class PlannerPreviewPage extends ConsumerWidget {
  const PlannerPreviewPage({super.key, required this.localKey});
  final String localKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(plannerProvider).preview;
    final valid = preview != null && preview.localKey == localKey;
    void adjust() => context.canPop() ? context.pop() : context.go('/planner');
    return Scaffold(
      appBar: AppTopBar(
        title: 'Lịch trình nháp',
        actions: [
          if (valid)
            AppIconButton(
              icon: LucideIcons.trainFront,
              tooltip: 'Ga Metro',
              onPressed: () => context.push('/metro'),
            ),
        ],
      ),
      bottomNavigationBar: valid
          ? AppBottomActionBar(
              flex: const [2, 3],
              children: [
                AppButton.secondary(
                  label: 'Điều chỉnh',
                  icon: LucideIcons.slidersHorizontal,
                  onPressed: adjust,
                ),
                AppButton(
                  label: 'Chốt lịch trình',
                  icon: LucideIcons.check,
                  onPressed: () => showFinalizeSheet(context),
                ),
              ],
            )
          : null,
      body: SafeArea(
        top: false,
        child: valid
            ? ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm,
                  AppSpacing.gutter,
                  AppSpacing.xxl,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.maxContentWidth,
                      ),
                      child: OfflinePreviewContent(preview: preview),
                    ),
                  ),
                ],
              )
            : Center(
                child: SingleChildScrollView(
                  child: AppEmptyState(
                    illustration: IllustrationKind.error,
                    title: 'Bản mẫu không còn khả dụng',
                    message: 'Phiên hoặc thao tác đã thay đổi. Quay lại để tạo preview mới.',
                    actionLabel: 'Tạo lại lịch trình',
                    actionIcon: LucideIcons.sparkles,
                    onAction: () => context.go('/planner'),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Confirmation before finalizing. Offline previews cannot be finalized,
/// so the sheet explains why instead of faking success.
Future<void> showFinalizeSheet(
  BuildContext context,
) => showAppBottomSheet<void>(
  context: context,
  title: 'Chốt lịch trình?',
  scrollable: true,
  builder: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Sau khi chốt, các điểm dừng được khóa và lưu vào Lịch trình của tôi. '
        'Bạn vẫn có thể đánh dấu đã ghé và đánh giá chuyến đi.',
        style: context.textStyles.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      const AppBanner(
        kind: BannerKind.warning,
        icon: LucideIcons.lock,
        title: 'Chưa khả dụng ở bản offline',
        message: 'Chốt lịch trình cần đăng nhập và kết nối máy chủ. Bản mẫu này chưa được lưu.',
      ),
    ],
  ),
  actions: [
    const AppButton(
      label: 'Xác nhận chốt',
      icon: LucideIcons.check,
      expand: true,
      onPressed: null,
    ),
    Builder(
      builder: (c) => AppButton.ghost(
        label: 'Để sau',
        expand: true,
        onPressed: () => Navigator.of(c).pop(),
      ),
    ),
  ],
);

class OfflinePreviewContent extends StatelessWidget {
  const OfflinePreviewContent({super.key, required this.preview});
  final OfflineDraftPreview preview;

  String get originName {
    final origin = preview.criteria.origin;
    if (origin is StationOrigin) {
      for (final station in stationSeed) {
        if (station['Order'] == origin.order) return station['Name'] as String;
      }
    }
    return 'điểm xuất phát';
  }

  DateTime stopTime(int index) => preview.start.add(
    Duration(
      minutes:
          index *
          preview.criteria.durationHours *
          60 ~/
          preview.sampleStops.length,
    ),
  );

  bool _nextDay(DateTime value) =>
      value.year != preview.start.year ||
      value.month != preview.start.month ||
      value.day != preview.start.day;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = context.textStyles;
    final c = preview.criteria;
    final note = normalizePlannerNote(c.note);
    final stops = preview.sampleStops;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusChip(
              label: 'Bản mẫu offline',
              kind: StatusKind.draft,
              icon: LucideIcons.pencil,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(
            'Quanh ga $originName · ${c.durationHours} giờ',
            style: text.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${formatVietnameseDate(preview.start)} · xuất phát ${clockLabel(preview.start)} · giờ Việt Nam',
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _MetaPill(LucideIcons.timer, '${c.durationHours} giờ đã chọn'),
            _MetaPill(LucideIcons.mapPin, '${stops.length} điểm dừng mẫu'),
            _MetaPill(
              LucideIcons.wallet,
              'Tối đa ${formatVnd(c.budgetMax)} VND / người',
            ),
            _MetaPill(
              travelModeIcon(c.travelMode),
              travelModeLabel(c.travelMode),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.appColors.metroLineContainer,
            borderRadius: AppRadius.control,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: AppSizes.icon,
                  color: context.appColors.metroLine,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Khung giờ minh họa: ${clockLabel(preview.start)} – ${clockLabel(preview.end)}'
                    '${preview.endsNextDay ? ' (ngày hôm sau)' : ''}',
                    style: text.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppBanner(
          kind: BannerKind.warning,
          message: 'Xem lại từng điểm dừng trước khi chốt lịch trình.',
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(
          title: 'Lịch trình theo giờ',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < stops.length; i++) ...[
          StaggeredEntrance(
            index: i,
            child: TimelineStop(
              index: i + 1,
              isFirst: i == 0,
              isLast: i == stops.length - 1,
              time: clockLabel(stopTime(i)),
              timeNote:
                  '${_nextDay(stopTime(i)) ? '(ngày hôm sau) ' : ''}· mốc minh họa',
              title: stops[i],
              subtitle: 'Dừng tham quan minh họa · ước tính mẫu 0 VND',
              tone: PlaceCategoryTone.other,
            ),
          ),
          if (i + 1 < stops.length)
            const TimelineConnector(
              label: 'Thứ tự di chuyển minh họa · chưa tối ưu tuyến',
            ),
        ],
        if (note != null) ...[
          const SizedBox(height: AppSpacing.lg),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: AppRadius.control,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.pencil,
                    size: AppSizes.iconSm,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Ghi chú của bạn: $note',
                      style: text.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton.secondary(
          label: 'Ga Metro & liên kết chỉ đường',
          icon: LucideIcons.trainFront,
          expand: true,
          onPressed: () => context.push('/metro'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Bản xem trước tạm thời, không phải kết quả AI hay Draft đã lưu. '
          'Giá và thứ tự chỉ minh họa. Chưa kết nối Backend. Không có Trip ID, lưu hay chốt.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: AppRadius.chip,
      border: Border.all(color: context.colors.outline),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + AppSpacing.xxs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppSizes.iconSm,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(child: Text(label, style: context.textStyles.labelMedium)),
        ],
      ),
    ),
  );
}
