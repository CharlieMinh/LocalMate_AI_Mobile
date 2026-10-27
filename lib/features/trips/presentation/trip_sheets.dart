import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/api_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/formatters.dart';
import '../../discovery/presentation/discovery_widgets.dart';
import '../application/trips_providers.dart';
import '../domain/trip_models.dart';

/// Positive review tags (backend `ReviewQuickTags.Positive`); the rest are
/// shown under "Cần cải thiện".
const _positiveReviewTags = {
  'WorthVisiting',
  'NearMetro',
  'EasyToReach',
  'GoodValue',
  'NiceAtmosphere',
  'GoodForGroups',
};
const _maxReviewTags = 3;
const _maxComment = 1000;

Future<T?> _showSheet<T>(BuildContext context, Widget sheet) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => sheet,
    );

void _toast(ScaffoldMessengerState messenger, String message) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(message)));

Widget _label(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
  child: Text(text, style: context.textStyles.titleSmall),
);

/// Review of one visited stop: shows the saved review, or a form.
Future<void> showStopReviewSheet(
  BuildContext context, {
  required String itemId,
  required String placeName,
}) => _showSheet(context, _StopReviewSheet(itemId, placeName));

class _StopReviewSheet extends ConsumerStatefulWidget {
  const _StopReviewSheet(this.itemId, this.placeName);
  final String itemId;
  final String placeName;

  @override
  ConsumerState<_StopReviewSheet> createState() => _StopReviewSheetState();
}

class _StopReviewSheetState extends ConsumerState<_StopReviewSheet> {
  final _comment = TextEditingController();
  int _rating = 0;
  final _tags = <String>{};
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // The sheet can be dismissed while the request runs.
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(tripsRepositoryProvider)
          .submitReview(
            widget.itemId,
            rating: _rating,
            quickTags: _tags.toList(),
            comment: _comment.text,
          );
      container.invalidate(stopReviewProvider(widget.itemId));
      AppHaptics.success();
      if (mounted) navigator.pop();
      _toast(messenger, 'Cảm ơn bạn đã đánh giá ${widget.placeName}.');
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = apiErrorMessage(error);
      });
    }
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await ref.read(tripsRepositoryProvider).deleteReview(widget.itemId);
      container.invalidate(stopReviewProvider(widget.itemId));
      if (mounted) navigator.pop();
      _toast(messenger, 'Đã xoá đánh giá.');
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = apiErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = ref.watch(stopReviewProvider(widget.itemId));
    final tags = ref.watch(quickTagsProvider);
    final saved = review.asData?.value;
    final formReady = review.hasValue && saved == null;
    return AppSheetBody(
      title: saved == null ? 'Đánh giá điểm dừng' : 'Đánh giá của bạn',
      subtitle: widget.placeName,
      actions: [
        if (formReady)
          AppButton(
            buttonKey: const ValueKey('review-submit'),
            label: 'Gửi đánh giá',
            icon: LucideIcons.send,
            expand: true,
            loading: _busy,
            onPressed: _rating == 0 || _busy ? null : _submit,
          ),
        if (saved != null)
          AppButton.secondary(
            label: 'Xoá đánh giá',
            icon: LucideIcons.trash2,
            expand: true,
            loading: _busy,
            onPressed: _busy ? null : _delete,
          ),
      ],
      child: DiscoveryAsync<PlaceReview?>(
        value: review,
        compact: true,
        retry: () => ref.invalidate(stopReviewProvider(widget.itemId)),
        loading: (_) => const SkeletonBlock(height: AppSpacing.xxxl * 2),
        data: (saved) {
          final labels = {
            for (final t in tags.asData?.value.review ?? const <QuickTag>[])
              t.code: t.label,
          };
          if (saved != null) {
            return _SavedReview(review: saved, labels: labels, error: _error);
          }
          final all = tags.asData?.value.review ?? const <QuickTag>[];
          Widget group(String title, Iterable<QuickTag> items) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(context, title),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final t in items)
                    AppFilterChip(
                      key: ValueKey('review-tag-${t.code}'),
                      label: t.label,
                      selected: _tags.contains(t.code),
                      onSelected:
                          _tags.contains(t.code) ||
                              _tags.length < _maxReviewTags
                          ? () => setState(
                              () => _tags.contains(t.code)
                                  ? _tags.remove(t.code)
                                  : _tags.add(t.code),
                            )
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label(context, 'Bạn chấm mấy sao?'),
              Align(
                alignment: Alignment.centerLeft,
                child: RatingStars(
                  value: _rating,
                  onChanged: _busy ? null : (v) => setState(() => _rating = v),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Stars alone can be sent; the quick tags just come back on retry.
              if (tags.hasError && !tags.isLoading) ...[
                _QuickTagsError(
                  onRetry: () => ref.invalidate(quickTagsProvider),
                ),
                const SizedBox(height: AppSpacing.lg),
              ] else if (all.isNotEmpty) ...[
                Text(
                  'Chọn tối đa $_maxReviewTags nhận xét nhanh',
                  style: context.textStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                group(
                  'Điểm cộng',
                  all.where((t) => _positiveReviewTags.contains(t.code)),
                ),
                group(
                  'Cần cải thiện',
                  all.where((t) => !_positiveReviewTags.contains(t.code)),
                ),
              ],
              AppTextField(
                fieldKey: const ValueKey('review-comment'),
                controller: _comment,
                label: 'Nhận xét (không bắt buộc)',
                hint: 'Điều bạn thích hoặc cần lưu ý ở đây',
                maxLines: 4,
                maxLength: _maxComment,
                enabled: !_busy,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppBanner(kind: BannerKind.error, message: _error!),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SavedReview extends StatelessWidget {
  const _SavedReview({required this.review, required this.labels, this.error});
  final PlaceReview review;
  final Map<String, String> labels;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: RatingStars(value: review.rating),
      ),
      if (review.quickTags.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final code in review.quickTags)
              StatusChip(label: labels[code] ?? code, kind: StatusKind.info),
          ],
        ),
      ],
      if (review.comment != null) ...[
        const SizedBox(height: AppSpacing.md),
        Text(review.comment!, style: context.textStyles.bodyMedium),
      ],
      if (error != null) ...[
        const SizedBox(height: AppSpacing.md),
        AppBanner(kind: BannerKind.error, message: error!),
      ],
    ],
  );
}

/// One feedback per finalized trip (quick tag + optional comment).
Future<void> showTripFeedbackSheet(BuildContext context, String tripId) =>
    _showSheet(context, _TripFeedbackSheet(tripId));

class _TripFeedbackSheet extends ConsumerStatefulWidget {
  const _TripFeedbackSheet(this.tripId);
  final String tripId;

  @override
  ConsumerState<_TripFeedbackSheet> createState() => _TripFeedbackSheetState();
}

class _TripFeedbackSheetState extends ConsumerState<_TripFeedbackSheet> {
  final _comment = TextEditingController();
  String? _tag;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(tripsRepositoryProvider)
          .submitFeedback(
            widget.tripId,
            quickTag: _tag!,
            comment: _comment.text,
          );
      container.invalidate(tripFeedbackProvider(widget.tripId));
      AppHaptics.success();
      if (mounted) navigator.pop();
      _toast(messenger, 'Cảm ơn bạn đã góp ý cho chuyến đi.');
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = apiErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedback = ref.watch(tripFeedbackProvider(widget.tripId));
    final tags = ref.watch(quickTagsProvider);
    final formReady = feedback.hasValue && feedback.value == null;
    return AppSheetBody(
      title: 'Đánh giá chuyến đi',
      subtitle: 'Giúp LocalMate gợi ý lịch trình hợp với bạn hơn.',
      actions: [
        if (formReady)
          AppButton(
            buttonKey: const ValueKey('feedback-submit'),
            label: 'Gửi phản hồi',
            icon: LucideIcons.send,
            expand: true,
            loading: _busy,
            onPressed: _tag == null || _busy ? null : _submit,
          ),
      ],
      child: DiscoveryAsync<TripFeedback?>(
        value: feedback,
        compact: true,
        retry: () => ref.invalidate(tripFeedbackProvider(widget.tripId)),
        loading: (_) => const SkeletonBlock(height: AppSpacing.xxxl * 2),
        data: (saved) {
          final options = tags.asData?.value.feedback ?? const <QuickTag>[];
          if (saved != null) {
            final label = options
                .where((t) => t.code == saved.quickTag)
                .map((t) => t.label)
                .firstOrNull;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppBanner(
                  kind: BannerKind.success,
                  message: 'Bạn đã gửi phản hồi cho chuyến đi này.',
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusChip(
                    label: label ?? saved.quickTag,
                    kind: StatusKind.info,
                  ),
                ),
                if (saved.comment != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(saved.comment!, style: context.textStyles.bodyMedium),
                ],
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label(context, 'Chuyến đi này thế nào?'),
              if (tags.isLoading)
                const SkeletonBlock(height: AppSizes.minTouchTarget)
              else if (tags.hasError)
                // Feedback needs a tag, so the form cannot work without them.
                _QuickTagsError(
                  onRetry: () => ref.invalidate(quickTagsProvider),
                )
              else
                AppChipGroup<String>(
                  wrap: true,
                  keyPrefix: 'feedback-tag',
                  options: [
                    for (final t in options)
                      AppChipOption(value: t.code, label: t.label),
                  ],
                  selected: _tag,
                  onSelected: (v) => setState(() => _tag = v),
                ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _comment,
                label: 'Góp ý thêm (không bắt buộc)',
                maxLines: 4,
                maxLength: _maxComment,
                enabled: !_busy,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppBanner(kind: BannerKind.error, message: _error!),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Draft editing: pick a replacement for one stop. Resolves to true when
/// the stop was swapped.
Future<bool> showReplaceStopSheet(
  BuildContext context, {
  required String tripId,
  required String itemId,
  required String placeName,
}) async =>
    await _showSheet<bool>(
      context,
      _ReplaceStopSheet(tripId: tripId, itemId: itemId, placeName: placeName),
    ) ??
    false;

class _ReplaceStopSheet extends ConsumerStatefulWidget {
  const _ReplaceStopSheet({
    required this.tripId,
    required this.itemId,
    required this.placeName,
  });
  final String tripId;
  final String itemId;
  final String placeName;

  @override
  ConsumerState<_ReplaceStopSheet> createState() => _ReplaceStopSheetState();
}

class _ReplaceStopSheetState extends ConsumerState<_ReplaceStopSheet> {
  String? _busyId;
  String? _error;

  Future<void> _pick(AlternativePlace place) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _busyId = place.placeId;
      _error = null;
    });
    try {
      final warnings = await ref
          .read(tripsRepositoryProvider)
          .replaceItem(widget.tripId, widget.itemId, place.placeId);
      container
        ..invalidate(tripDetailProvider(widget.tripId))
        ..invalidate(myTripsProvider);
      AppHaptics.success();
      if (mounted) navigator.pop(true);
      _toast(
        messenger,
        warnings.isEmpty
            ? 'Đã đổi sang ${place.name}.'
            : 'Đã đổi sang ${place.name}. Giờ các điểm sau đã được tính lại.',
      );
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _busyId = null;
        _error = apiErrorMessage(error);
      });
    }
  }

  String _subtitle(AlternativePlace p) => [
    categoryLabel(p.category),
    p.costMax <= 0
        ? 'Miễn phí'
        : p.costMin == p.costMax || p.costMin <= 0
        ? '${formatVnd(p.costMax)}đ'
        : '${formatVnd(p.costMin)}–${formatVnd(p.costMax)}đ',
    if (p.distanceFromStationMeters != null && p.stationName != null)
      '${p.distanceFromStationMeters} m tới ga ${p.stationName}',
    if (p.openingStatus == 'Closed') 'Đang đóng cửa',
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final key = (tripId: widget.tripId, itemId: widget.itemId);
    final alternatives = ref.watch(alternativesProvider(key));
    return AppSheetBody(
      title: 'Đổi địa điểm',
      subtitle: 'Thay cho ${widget.placeName}',
      child: DiscoveryAsync<List<AlternativePlace>>(
        value: alternatives,
        compact: true,
        retry: () => ref.invalidate(alternativesProvider(key)),
        loading: (_) => const Column(
          children: [
            SkeletonBlock(height: AppSizes.thumb),
            SizedBox(height: AppSpacing.md),
            SkeletonBlock(height: AppSizes.thumb),
          ],
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              compact: true,
              title: 'Chưa có địa điểm thay thế',
              message: 'Quanh ga này chưa có địa điểm phù hợp khác trong ngân sách của bạn.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                AppBanner(kind: BannerKind.error, message: _error!),
                const SizedBox(height: AppSpacing.sm),
              ],
              for (final p in items)
                PlaceListTile(
                  key: ValueKey('alternative-${p.placeId}'),
                  name: p.name,
                  subtitle: _subtitle(p),
                  tone: placeTone(p.category),
                  imageUrl: p.imageUrl,
                  onTap: _busyId == null ? () => _pick(p) : null,
                  trailing: _busyId == p.placeId
                      ? const SizedBox.square(
                          dimension: AppSizes.icon,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          LucideIcons.replace,
                          size: AppSizes.icon,
                          color: context.colors.primary,
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Quick tags (`master-data`) failed to load: explain and offer a retry.
class _QuickTagsError extends StatelessWidget {
  const _QuickTagsError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppBanner(
    kind: BannerKind.error,
    message: 'Chưa tải được danh sách nhận xét nhanh.',
    action: AppButton.ghost(
      buttonKey: const ValueKey('quick-tags-retry'),
      label: 'Thử lại',
      icon: LucideIcons.refreshCw,
      compact: true,
      onPressed: onRetry,
    ),
  );
}
