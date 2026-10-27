import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/api_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/formatters.dart';
import '../../auth/application/auth_controller.dart';
import '../../discovery/presentation/discovery_widgets.dart';
import '../../planner/data/planner_response_dtos.dart';
import '../../planner/domain/planner_criteria.dart';
import '../../planner/presentation/finalized_trip_view.dart';
import '../../planner/presentation/planner_format.dart';
import '../../planner/presentation/planner_page.dart';
import '../application/trips_providers.dart';
import '../domain/trip_models.dart';

String _tripTitle(String? station, int hours) => station == null
    ? 'Lịch trình $hours giờ'
    : 'Quanh ga $station · $hours giờ';

String _dateLabel(String? plannedDate) {
  final date = plannedDate == null ? null : parsePlannerDate(plannedDate);
  return date == null ? 'Chưa chọn ngày' : longVietnameseDate(date);
}

String _hhmm(String? time) =>
    time == null || time.length < 5 ? '--:--' : time.substring(0, 5);

String _vnd(double amount) => '${formatVnd(amount)}đ';

/// Trips tab: saved trips from the backend in live builds; the offline
/// explainer otherwise.
class TripsTab extends ConsumerWidget {
  const TripsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(liveBackendProvider)) return const PlannerEntryPage();
    final auth = ref.watch(authProvider);
    if (!auth.authenticated) {
      return Center(
        child: SingleChildScrollView(
          child: AppEmptyState(
            illustration: IllustrationKind.noTrips,
            title: 'Đăng nhập để xem lịch trình',
            message: 'Lịch trình bạn tạo và đã chốt được lưu theo tài khoản.',
            actionLabel: 'Đăng nhập',
            actionIcon: LucideIcons.logIn,
            onAction: () => context.go('/login'),
          ),
        ),
      );
    }
    final trips = ref.watch(myTripsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(myTripsProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          AppSpacing.xxl,
        ),
        children: [
          DiscoveryAsync<List<MyTrip>>(
            value: trips,
            retry: () => ref.invalidate(myTripsProvider),
            loading: (_) => const Column(
              children: [
                SkeletonBlock(
                  height: AppSpacing.xxxl * 2,
                  radius: AppRadius.lg,
                ),
                SizedBox(height: AppSpacing.md),
                SkeletonBlock(
                  height: AppSpacing.xxxl * 2,
                  radius: AppRadius.lg,
                ),
              ],
            ),
            data: (items) {
              if (items.isEmpty) return const PlannerEntryPage();
              final drafts = items.where((t) => !t.finalized).toList();
              final finals = items.where((t) => t.finalized).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (finals.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Đã chốt',
                      subtitle: '${finals.length} lịch trình',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < finals.length; i++)
                      StaggeredEntrance(index: i, child: _TripCard(finals[i])),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (drafts.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Bản nháp',
                      subtitle: '${drafts.length} lịch trình',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < drafts.length; i++)
                      StaggeredEntrance(index: i, child: _TripCard(drafts[i])),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard(this.trip);
  final MyTrip trip;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = context.textStyles;
    final title = _tripTitle(trip.stationName, trip.durationHours);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: scheme.outline),
        ),
        child: Pressable(
          onTap: () => context.push('/trips/${Uri.encodeComponent(trip.id)}'),
          semanticLabel:
              '$title, ${trip.finalized ? 'đã chốt' : 'bản nháp'}, ${_dateLabel(trip.plannedDate)}',
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusChip(
                    label: trip.finalized ? 'Đã chốt' : 'Bản nháp',
                    kind: trip.finalized
                        ? StatusKind.finalized
                        : StatusKind.draft,
                    icon: trip.finalized
                        ? LucideIcons.circleCheck
                        : LucideIcons.pencil,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(title, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(_dateLabel(trip.plannedDate), style: text.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _Meta(LucideIcons.mapPin, '${trip.itemCount} điểm dừng'),
                      _Meta(
                        LucideIcons.wallet,
                        'Khoảng ${_vnd(trip.estimatedBudget)} / người',
                      ),
                    ],
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

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: AppSizes.iconSm, color: context.colors.onSurfaceVariant),
      const SizedBox(width: AppSpacing.xs),
      Flexible(child: Text(label, style: context.textStyles.labelMedium)),
    ],
  );
}

TravelLeg? _legOf(PlannerLegDto? leg) {
  if (leg == null) return null;
  final mode = switch (leg.mode) {
    'Metro' => TravelMode.metro,
    'Motorbike' => TravelMode.motorbike,
    _ => TravelMode.walking,
  };
  final metro = mode == TravelMode.metro;
  return TravelLeg(
    mode: mode,
    minutes: leg.totalMinutes,
    estimated: leg.isEstimated ?? metro,
    boardStation: metro ? leg.boardStation?.name : null,
    alightStation: metro ? leg.alightStation?.name : null,
    detail: metro
        ? [
            if (leg.stopCount != null) '${leg.stopCount} ga',
            if (leg.waitMinutes != null) 'chờ khoảng ${leg.waitMinutes} phút',
          ].join(' · ')
        : leg.fallback == 'metro_unavailable'
        ? 'Metro không khả dụng lúc này'
        : null,
  );
}

/// `/trips/:id`: a saved trip. Drafts can be finalized; finalized trips
/// track visited stops.
class TripDetailPage extends ConsumerWidget {
  const TripDetailPage(this.id, {super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripDetailProvider(id));
    final draft = trip.asData?.value.status == 'Draft';
    return Scaffold(
      appBar: AppTopBar(
        title: trip.asData == null
            ? 'Lịch trình'
            : draft
            ? 'Lịch trình nháp'
            : 'Lịch trình đã chốt',
        actions: [
          AppIconButton(
            icon: LucideIcons.trainFront,
            tooltip: 'Ga Metro',
            onPressed: () => context.push('/metro'),
          ),
        ],
      ),
      bottomNavigationBar: draft
          ? AppBottomActionBar(
              children: [
                AppButton(
                  label: 'Chốt lịch trình',
                  icon: LucideIcons.check,
                  onPressed: () => _finalize(context, ref),
                ),
              ],
            )
          : null,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(tripDetailProvider(id).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              AppSpacing.xxl,
            ),
            children: [
              DiscoveryAsync<TripGenerationResponseDto>(
                value: trip,
                retry: () => ref.invalidate(tripDetailProvider(id)),
                data: (t) => t.status == 'Draft'
                    ? _DraftView(t)
                    : FinalizedTripView(
                        title: _tripTitle(
                          t.startStation?.name ?? t.stationName,
                          t.durationHours,
                        ),
                        dateLine:
                            '${_dateLabel(t.plannedDate)} · xuất phát ${_hhmm(t.startTime)}',
                        stops: [
                          for (final item in t.items)
                            FinalizedStop(
                              id: item.itemId,
                              time: _hhmm(item.scheduledTime),
                              title: item.placeName,
                              subtitle:
                                  '${categoryLabel(item.category)} · dừng ${item.estimatedDurationMinutes} phút',
                              tone: placeTone(item.category),
                              visited: item.isVisited,
                              nextDay: item.isNextDay,
                              leg: item.orderIndex == 0
                                  ? null
                                  : _legOf(item.leg),
                            ),
                        ],
                        onToggleVisited: (stop) => _toggle(context, ref, stop),
                        onReviewStop: (_) => _comingSoon(context),
                        onTripFeedback: () => _comingSoon(context),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finalize(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Chốt lịch trình?',
      message:
          'Sau khi chốt, các điểm dừng được khóa và lưu vào Lịch trình của tôi. '
          'Bạn vẫn có thể đánh dấu đã ghé từng điểm.',
      confirmLabel: 'Xác nhận chốt',
      confirmIcon: LucideIcons.check,
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(tripsRepositoryProvider).finalize(id);
      ref
        ..invalidate(tripDetailProvider(id))
        ..invalidate(myTripsProvider)
        ..invalidate(subscriptionProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã chốt lịch trình.')),
      );
    } on ApiFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
    }
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    FinalizedStop stop,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(tripsRepositoryProvider).toggleVisited(stop.id);
      ref.invalidate(tripDetailProvider(id));
    } on ApiFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
    }
  }

  // TODO(phase-5): POST /trips/items/{id}/review and /feedback/trip sheets.
  void _comingSoon(BuildContext context) => ScaffoldMessenger.of(context)
      .showSnackBar(
        const SnackBar(content: Text('Đánh giá sẽ có trong bản cập nhật tới.')),
      );
}

class _DraftView extends StatelessWidget {
  const _DraftView(this.trip);
  final TripGenerationResponseDto trip;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = context.textStyles;
    final items = trip.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            label: 'Bản nháp',
            kind: StatusKind.draft,
            icon: LucideIcons.pencil,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(
            _tripTitle(
              trip.startStation?.name ?? trip.stationName,
              trip.durationHours,
            ),
            style: text.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_dateLabel(trip.plannedDate)} · ${_hhmm(trip.startTime)} – ${_hhmm(trip.endTime)}'
          '${trip.endsNextDay ? ' (hôm sau)' : ''}',
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            _Meta(LucideIcons.mapPin, '${items.length} điểm dừng'),
            _Meta(
              LucideIcons.wallet,
              'Khoảng ${_vnd(trip.estimatedBudget)} / người',
            ),
            _Meta(LucideIcons.timer, '${trip.totalMinutes} phút'),
          ],
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
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) ?_legOf(items[i].leg),
          StaggeredEntrance(
            index: i,
            child: TimelineStop(
              index: i + 1,
              isFirst: i == 0,
              isLast: i == items.length - 1,
              time: _hhmm(items[i].scheduledTime),
              timeNote: items[i].isNextDay ? '(hôm sau)' : null,
              title: items[i].placeName,
              subtitle: [
                '${categoryLabel(items[i].category)} · dừng ${items[i].estimatedDurationMinutes} phút · ~${_vnd(items[i].estimatedBudget)}',
                ?items[i].reasoning,
              ].join('\n'),
              tone: placeTone(items[i].category),
              imageUrl: items[i].imageUrl,
              heroTag: placeHeroTag(items[i].placeId),
              onTap: () => context.push(
                '/places/${Uri.encodeComponent(items[i].placeId)}',
              ),
              actions: [
                AppButton.ghost(
                  label: 'Xem địa điểm',
                  compact: true,
                  trailingIcon: LucideIcons.chevronRight,
                  onPressed: () => context.push(
                    '/places/${Uri.encodeComponent(items[i].placeId)}',
                  ),
                ),
              ],
            ),
          ),
        ],
        if (trip.note != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AppBanner(icon: LucideIcons.pencil, message: 'Ghi chú: ${trip.note}'),
        ],
      ],
    );
  }
}
