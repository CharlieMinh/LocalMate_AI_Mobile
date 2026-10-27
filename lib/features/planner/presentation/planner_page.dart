import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/formatters.dart';
import '../../auth/application/auth_controller.dart';
import '../../discovery/data/station_fixture_data.dart';
import '../../discovery/domain/discovery_models.dart';
import '../../discovery/presentation/station_picker.dart';
import '../../trips/application/trips_providers.dart';
import '../application/planner_controller.dart';
import '../application/planner_form_controller.dart';
import '../data/offline_planner_repository.dart';
import '../domain/planner_criteria.dart';
import 'planner_fill_sheet.dart';
import 'planner_format.dart';

export 'itinerary_preview_page.dart';

/// Stations for the offline wizard (compiled BE seed, same as before).
final plannerStations = [
  for (final s in stationSeed)
    Station(
      '${s['Order']}',
      s['Name']! as String,
      s['Order']! as int,
      s['Latitude'] as double?,
      s['Longitude'] as double?,
    ),
];

String plannerStationName(int order) =>
    plannerStations.firstWhere((s) => s.order == order).name;

class PlannerEntryPage extends ConsumerWidget {
  const PlannerEntryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppEmptyState(
                  illustration: IllustrationKind.noTrips,
                  title: 'Một hành trình đang chờ bạn',
                  message: 'Chọn một ga và thời gian rảnh để bắt đầu hành trình đầu tiên.',
                  actionLabel: ref.watch(liveBackendProvider)
                      ? 'Tạo lịch trình'
                      : 'Tạo lịch trình mẫu',
                  actionIcon: LucideIcons.sparkles,
                  onAction: () => context.push('/planner'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  child: _HowItWorks(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    'Lịch trình đã lưu chưa được kết nối. Bản xem trước chỉ tồn tại tạm thời trong phiên.',
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Three-step explainer on the empty Trips tab: create, review, finalize.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    (
      LucideIcons.trainFront,
      'Chọn ga & thời gian',
      'Bắt đầu từ một ga tuyến số 1.',
    ),
    (
      LucideIcons.route,
      'Xem lịch trình nháp',
      'Điều chỉnh từng điểm dừng theo giờ.',
    ),
    (
      LucideIcons.circleCheck,
      'Chốt & lưu',
      'Lịch trình đã chốt xuất hiện tại đây.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = context.textStyles;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: scheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Cách hoạt động', style: text.titleSmall),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < _steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StationBadge(order: i + 1, size: AppSizes.stationBadgeSm),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _steps[i].$1,
                                size: AppSizes.iconSm,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  _steps[i].$2,
                                  style: text.labelLarge,
                                ),
                              ),
                            ],
                          ),
                          Text(_steps[i].$3, style: text.bodySmall),
                        ],
                      ),
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

class PlannerPage extends ConsumerWidget {
  const PlannerPage({super.key, this.initialStation});

  /// Departure station to preselect (e.g. from a place's nearest station).
  final int? initialStation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-key on auth changes so text controllers reset together with the
    // form controller (which also rebuilds on auth transitions).
    final auth = ref.watch(authProvider);
    return _PlannerForm(key: ObjectKey(auth), initialStation: initialStation);
  }
}

class _PlannerForm extends ConsumerStatefulWidget {
  const _PlannerForm({super.key, this.initialStation});
  final int? initialStation;
  @override
  ConsumerState<_PlannerForm> createState() => _PlannerFormState();
}

class _PlannerFormState extends ConsumerState<_PlannerForm>
    with WidgetsBindingObserver {
  late final TextEditingController budget;
  late final TextEditingController note;
  final scroll = ScrollController();
  bool stepChanging = false;
  bool reverse = false;

  static const titles = [
    'Bắt đầu từ đâu?',
    'Bạn có bao nhiêu thời gian?',
    'Hôm nay bạn thích gì?',
    'Đi theo phong cách của bạn',
  ];
  static const captions = ['VỊ TRÍ', 'THỜI GIAN', 'SỞ THÍCH', 'PHONG CÁCH'];
  static const helpers = [
    'Chọn một ga trên tuyến Metro số 1.',
    'Một hành trình vừa với khoảng thời gian rảnh.',
    'Chọn các trải nghiệm bạn muốn ưu tiên, hoặc tiếp tục mà không chọn.',
    'Hoàn tất lựa chọn trước khi xem lịch trình mẫu.',
  ];

  PlannerFormController get form => ref.read(plannerFormProvider.notifier);

  @override
  void initState() {
    super.initState();
    final initial = ref.read(plannerFormProvider);
    budget = TextEditingController(text: initial.budget);
    note = TextEditingController(text: initial.note);
    WidgetsBinding.instance.addObserver(this);
    final station = widget.initialStation;
    if (station != null && plannerStations.any((s) => s.order == station)) {
      // Providers cannot change while the tree is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) form.setOrigin(station);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(plannerProvider.notifier).interrupt();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    budget.dispose();
    note.dispose();
    scroll.dispose();
    super.dispose();
  }

  void back() {
    ref.read(plannerProvider.notifier).interrupt();
    FocusScope.of(context).unfocus();
    setState(() => reverse = true);
    if (form.back()) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/trips');
    }
  }

  Future<void> fill() async {
    final parsed = await showPlannerFillSheet(context);
    if (parsed == null || !mounted) return;
    form.applyParsed(parsed);
    final f = ref.read(plannerFormProvider);
    budget.text = f.budget;
    note.text = f.note;
    setState(() => reverse = true);
    const names = {
      'durationHours': 'thời lượng',
      'budgetMax': 'ngân sách',
      'startLocation': 'ga xuất phát',
    };
    final missing = [for (final m in parsed.missing) ?names[m]];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          missing.isEmpty
              ? 'Đã điền sẵn thông tin. Hãy xem lại từng bước.'
              : 'Đã điền sẵn. Bạn bổ sung thêm ${missing.join(', ')} nhé.',
        ),
      ),
    );
  }

  Future<void> next() async {
    if (stepChanging) return;
    final catalog = ref.read(plannerTagsProvider);
    final blocked =
        ref.read(plannerFormProvider).step >= 2 &&
        (catalog.isLoading ||
            (catalog.hasError &&
                ref.read(plannerFormProvider).tags.isNotEmpty));
    if (!blocked) FocusScope.of(context).unfocus();
    if (ref.read(plannerProvider).phase == PlannerPhase.processing) return;
    final result = form.advance(
      catalog: catalog,
      now: ref.read(plannerNowProvider)(),
    );
    switch (result) {
      case PlannerBlocked() || PlannerInvalid():
        setState(() => reverse = true);
        return;
      case PlannerMoved():
        stepChanging = true;
        setState(() => reverse = false);
        if (scroll.hasClients) scroll.jumpTo(0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) stepChanging = false;
        });
        return;
      case PlannerReady(:final criteria, :final availableTags):
        if (ref.read(liveBackendProvider) &&
            !ref.read(authProvider).authenticated) {
          final login = await showAppConfirmSheet(
            context: context,
            title: 'Đăng nhập để tạo lịch trình',
            message: 'Lịch trình được lưu theo tài khoản để bạn xem lại và chốt sau.',
            confirmLabel: 'Đăng nhập',
            confirmIcon: LucideIcons.logIn,
          );
          if (login && mounted) await context.push('/login');
          return;
        }
        final preview = await ref
            .read(plannerProvider.notifier)
            .submit(criteria, availableTags: availableTags);
        if (!mounted ||
            preview == null ||
            ref.read(plannerProvider).preview != preview) {
          return;
        }
        AppHaptics.success();
        await context.push(
          preview.tripId != null
              ? '/trips/${Uri.encodeComponent(preview.tripId!)}'
              : '/planner/preview/${Uri.encodeComponent(preview.localKey)}',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plannerProvider);
    final f = ref.watch(plannerFormProvider);
    final catalog = ref.watch(plannerTagsProvider);
    final busy = state.phase == PlannerPhase.processing;
    final live = ref.watch(liveBackendProvider);
    final blocked =
        f.step >= 2 &&
        (catalog.isLoading || (catalog.hasError && f.tags.isNotEmpty));
    String? error(String key) => f.errors[key] ?? state.errors[key];

    final body = switch (f.step) {
      0 => _LocationStep(
        form: f,
        busy: busy,
        onFill: live && ref.watch(authProvider).authenticated ? fill : null,
      ),
      1 => _TimeStep(form: f, busy: busy, budget: budget, error: error),
      2 => _InterestStep(form: f, busy: busy, catalog: catalog, error: error),
      _ => _StyleStep(
        form: f,
        busy: busy,
        catalog: catalog,
        note: note,
        error: error,
        failure: state.message,
        outcomeUnknown: state.phase == PlannerPhase.outcomeUnknown,
        onRetry: next,
      ),
    };

    return PopScope(
      canPop: f.step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: live ? 'Tạo lịch trình' : 'Tạo lịch trình mẫu',
          onBack: back,
          backTooltip: 'Quay lại',
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: busy
                    ? const _PlannerLoading()
                    : SingleChildScrollView(
                        controller: scroll,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          AppSpacing.sm,
                          AppSpacing.gutter,
                          AppSpacing.xl,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSpacing.maxContentWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _StepHeader(
                                  step: f.step,
                                  caption: captions[f.step],
                                  title: titles[f.step],
                                  helper: live && f.isLastStep
                                      ? 'Kiểm tra lại lựa chọn trước khi tạo lịch trình.'
                                      : helpers[f.step],
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                PageTransitionSwitcher(
                                  reverse: reverse,
                                  duration: AppDurations.slow,
                                  transitionBuilder:
                                      (
                                        child,
                                        primary,
                                        secondary,
                                      ) => SharedAxisTransition(
                                        animation: primary,
                                        secondaryAnimation: secondary,
                                        transitionType:
                                            SharedAxisTransitionType.horizontal,
                                        fillColor: Colors.transparent,
                                        child: child,
                                      ),
                                  layoutBuilder: (entries) => Stack(
                                    alignment: Alignment.topCenter,
                                    children: entries,
                                  ),
                                  child: KeyedSubtree(
                                    key: ValueKey(f.step),
                                    child: body,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              AppBottomActionBar(
                children: [
                  AppButton(
                    label: busy
                        ? (live ? 'Đang tạo lịch trình…' : 'Đang tạo bản mẫu…')
                        : f.isLastStep &&
                              state.phase == PlannerPhase.outcomeUnknown
                        ? 'Vẫn tạo lịch trình mới'
                        : f.isLastStep
                        ? (live ? 'Tạo lịch trình' : 'Xem lịch trình mẫu')
                        : 'Tiếp tục',
                    icon: f.isLastStep ? LucideIcons.sparkles : null,
                    trailingIcon: f.isLastStep ? null : LucideIcons.arrowRight,
                    loading: busy,
                    haptic: f.isLastStep,
                    onPressed: busy || blocked ? null : next,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.caption,
    required this.title,
    required this.helper,
  });
  final int step;
  final String caption;
  final String title;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Bước ${step + 1} trên $plannerStepCount',
          child: Row(
            children: [
              for (var i = 0; i < plannerStepCount; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AnimatedContainer(
                    duration: AppDurations.medium,
                    curve: AppCurves.standard,
                    height: AppSpacing.xs,
                    decoration: BoxDecoration(
                      color: i <= step ? scheme.primary : scheme.outline,
                      borderRadius: AppRadius.chip,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'BƯỚC ${step + 1}/$plannerStepCount · $caption',
          style: text.labelSmall?.copyWith(color: scheme.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(header: true, child: Text(title, style: text.headlineSmall)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          helper,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Row(
      children: [
        Icon(icon, size: AppSizes.icon, color: context.colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(text, style: context.textStyles.titleSmall),
          ),
        ),
      ],
    ),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: AppSizes.iconSm,
              color: context.colors.error,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message!,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineNotice extends ConsumerWidget {
  const _OfflineNotice();
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(liveBackendProvider)
      ? const SizedBox.shrink()
      : const AppBanner(
          kind: BannerKind.warning,
          icon: LucideIcons.flaskConical,
          title: 'Chế độ offline',
          message: 'Chỉ xem lịch trình mẫu. Không gọi AI, không lưu Trip, không tiêu hao lượt dùng.',
        );
}

class _LocationStep extends ConsumerWidget {
  const _LocationStep({required this.form, required this.busy, this.onFill});
  final PlannerFormState form;
  final bool busy;

  /// "Điền giúp tôi" (live, signed in only).
  final VoidCallback? onFill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(plannerFormProvider.notifier);
    Future<void> pick({required bool origin}) async {
      final picked = await showStationPicker(
        context: context,
        stations: plannerStations,
        title: origin ? 'Chọn ga xuất phát' : 'Chọn ga đích',
        selected: origin ? form.origin : form.destination,
        allowNone: !origin,
      );
      if (picked == null) return;
      if (origin) {
        controller.setOrigin(picked);
      } else {
        controller.setDestination(picked == noStation ? null : picked);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onFill != null) ...[
          AppButton.tonal(
            buttonKey: const ValueKey('planner-fill'),
            label: 'Điền giúp tôi bằng AI',
            icon: LucideIcons.sparkles,
            expand: true,
            onPressed: busy ? null : onFill,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        StationField(
          inkKey: const ValueKey('planner-origin'),
          label: 'Ga xuất phát',
          value: plannerStationName(form.origin),
          order: form.origin,
          onTap: busy ? null : () => pick(origin: true),
        ),
        const SizedBox(height: AppSpacing.md),
        StationField(
          inkKey: const ValueKey('planner-destination'),
          label: 'Ga đích (tùy chọn)',
          value: form.destination == null
              ? 'Không chọn · quanh ga gần nhất'
              : plannerStationName(form.destination!),
          order: form.destination,
          onTap: busy ? null : () => pick(origin: false),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Hoặc chạm một ga trên tuyến',
          style: context.textStyles.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        MetroLineDiagram(
          padding: EdgeInsets.zero,
          stations: [
            for (final s in plannerStations)
              MetroStop(order: s.order, name: s.name),
          ],
          selectedOrder: form.origin,
          rangeEnd: form.destination,
          onSelect: busy ? null : (s) => controller.setOrigin(s.order),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppBanner(
          message: ref.watch(liveBackendProvider)
              ? 'Địa điểm và thứ tự di chuyển sẽ hiện trong lịch trình nháp để bạn xem lại.'
              : 'Địa điểm và thứ tự di chuyển sẽ được xem lại trong bản mẫu.',
        ),
        const SizedBox(height: AppSpacing.md),
        const _OfflineNotice(),
      ],
    );
  }
}

class _TimeStep extends ConsumerWidget {
  const _TimeStep({
    required this.form,
    required this.busy,
    required this.budget,
    required this.error,
  });
  final PlannerFormState form;
  final bool busy;
  final TextEditingController budget;
  final String? Function(String) error;

  static const _durations = [2, 4, 6, 8];
  static const _budgets = [150000, 300000, 500000, 1000000];
  static const _slots = [
    ('Sáng', '08:00', LucideIcons.sunrise),
    ('Chiều', '13:00', LucideIcons.sunMedium),
    ('Tối', '18:00', LucideIcons.sunset),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(plannerFormProvider.notifier);
    final now = vietnamCivilNow(ref.read(plannerNowProvider)());
    final today = DateTime.utc(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final picked = parsePlannerDate(form.date);
    final isToday = form.date.isEmpty || picked == today;
    final isTomorrow = picked == tomorrow;
    final customDate = !isToday && !isTomorrow;
    final slot = _slots
        .where((s) => s.$2 == (form.time.isEmpty ? '08:00' : form.time))
        .firstOrNull;
    final ends = endsNextDay(form.time, form.durationHours);

    Future<void> pickDate() async {
      FocusScope.of(context).unfocus();
      final last = today.add(const Duration(days: 90));
      final initial =
          picked == null || picked.isBefore(today) || picked.isAfter(last)
          ? today
          : picked;
      final result = await showDatePicker(
        context: context,
        firstDate: DateTime(today.year, today.month, today.day),
        lastDate: DateTime(last.year, last.month, last.day),
        initialDate: DateTime(initial.year, initial.month, initial.day),
        helpText: 'Chọn ngày đi',
        cancelText: 'Hủy',
        confirmText: 'Chọn',
      );
      if (result != null) controller.setDate(plannerDateString(result));
    }

    Future<void> pickTime() async {
      FocusScope.of(context).unfocus();
      final minutes = parsePlannerTime(form.time) ?? 480;
      final result = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        helpText: 'Chọn giờ xuất phát',
        cancelText: 'Hủy',
        confirmText: 'Chọn',
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (result != null) {
        controller.setTime(
          '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}',
        );
      }
    }

    Future<void> pickDuration() async {
      final value = await showDurationSheet(context, form.durationHours);
      if (value != null) controller.setDuration(value);
    }

    void setBudget(int amount) {
      budget.text = '$amount';
      controller.setBudget('$amount');
    }

    final chosenDate = picked ?? today;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel('Ngày đi', icon: LucideIcons.calendarDays),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppFilterChip(
              label: 'Hôm nay',
              selected: isToday,
              onSelected: busy ? null : () => controller.setDate(''),
            ),
            AppFilterChip(
              label: 'Ngày mai',
              selected: isTomorrow,
              onSelected: busy
                  ? null
                  : () => controller.setDate(plannerDateString(tomorrow)),
            ),
            Tooltip(
              message: 'Chọn ngày',
              child: AppFilterChip(
                label: customDate
                    ? shortVietnameseDate(chosenDate)
                    : 'Ngày khác',
                icon: LucideIcons.calendarDays,
                selected: customDate,
                onSelected: busy ? null : pickDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${longVietnameseDate(chosenDate)} · giờ Việt Nam',
          style: context.textStyles.bodySmall,
        ),
        _ErrorText(error('PlannedDate')),
        const SizedBox(height: AppSpacing.xl),
        const _FieldLabel('Giờ xuất phát', icon: LucideIcons.clock),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in _slots)
              AppFilterChip(
                label: '${s.$1} · ${s.$2}',
                icon: s.$3,
                selected: slot == s,
                onSelected: busy
                    ? null
                    : () => controller.setTime(s.$2 == '08:00' ? '' : s.$2),
              ),
            Tooltip(
              message: 'Chọn giờ',
              child: AppFilterChip(
                label: slot == null ? form.time : 'Giờ khác',
                icon: LucideIcons.clock,
                selected: slot == null,
                onSelected: busy ? null : pickTime,
              ),
            ),
          ],
        ),
        _ErrorText(error('StartTime')),
        const SizedBox(height: AppSpacing.xl),
        const _FieldLabel('Thời lượng', icon: LucideIcons.timer),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final h in _durations)
              AppFilterChip(
                label: durationPresetLabel(h),
                selected: form.durationHours == h,
                onSelected: busy ? null : () => controller.setDuration(h),
              ),
            AppFilterChip(
              key: const ValueKey('planner-duration-custom'),
              label: _durations.contains(form.durationHours)
                  ? 'Tùy chỉnh'
                  : '${form.durationHours} giờ',
              icon: LucideIcons.slidersHorizontal,
              selected: !_durations.contains(form.durationHours),
              onSelected: busy ? null : pickDuration,
            ),
          ],
        ),
        if (ends) ...[
          const SizedBox(height: AppSpacing.md),
          const AppBanner(
            icon: LucideIcons.moonStar,
            message: 'Lịch trình kết thúc sang ngày hôm sau.',
          ),
        ],
        _ErrorText(error('DurationHours')),
        const SizedBox(height: AppSpacing.xl),
        const _FieldLabel(
          'Ngân sách tối đa mỗi người',
          icon: LucideIcons.wallet,
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final amount in _budgets)
              AppFilterChip(
                label: '${formatVnd(amount)}đ',
                selected: form.budget.trim() == '$amount',
                onSelected: busy ? null : () => setBudget(amount),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          fieldKey: const ValueKey('planner-budget'),
          label: 'Hoặc nhập số tiền (VND / người)',
          hint: 'Ví dụ: 250000',
          controller: budget,
          enabled: !busy,
          keyboardType: TextInputType.number,
          prefixIcon: LucideIcons.banknote,
          onChanged: controller.setBudget,
          errorText: error('BudgetMax'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ngân sách tối thiểu cố định 0 VND.',
          style: context.textStyles.bodySmall,
        ),
      ],
    );
  }
}

/// Bottom sheet with a 1–24 h stepper and slider. Resolves to the hours.
Future<int?> showDurationSheet(BuildContext context, int current) {
  var value = current;
  return showAppBottomSheet<int>(
    context: context,
    title: 'Thời lượng tùy chỉnh',
    subtitle: 'Từ 1 đến 24 giờ · có thể sang ngày hôm sau',
    scrollable: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIconButton(
                icon: LucideIcons.minus,
                tooltip: 'Giảm 1 giờ',
                variant: AppIconButtonVariant.tonal,
                onPressed: value <= 1 ? null : () => setState(() => value--),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    '$value giờ',
                    style: context.textStyles.displaySmall,
                  ),
                ),
              ),
              AppIconButton(
                icon: LucideIcons.plus,
                tooltip: 'Tăng 1 giờ',
                variant: AppIconButtonVariant.tonal,
                onPressed: value >= 24 ? null : () => setState(() => value++),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 24,
            divisions: 23,
            label: '$value giờ',
            onChanged: (v) => setState(() => value = v.round()),
          ),
        ],
      ),
    ),
    actions: [
      Builder(
        builder: (c) => AppButton(
          label: 'Xong',
          expand: true,
          onPressed: () => Navigator.of(c).pop(value),
        ),
      ),
    ],
  );
}

class _InterestStep extends ConsumerWidget {
  const _InterestStep({
    required this.form,
    required this.busy,
    required this.catalog,
    required this.error,
  });
  final PlannerFormState form;
  final bool busy;
  final AsyncValue<List<PlannerTag>> catalog;
  final String? Function(String) error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(plannerFormProvider.notifier);
    final known = catalog.asData?.value ?? const <PlannerTag>[];
    final unverified = [
      if (catalog.hasError || catalog.hasValue)
        for (final id in form.tags)
          if (catalog.hasError || !known.any((tag) => tag.id == id)) id,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: _FieldLabel(
                'Sở thích (không bắt buộc)',
                icon: LucideIcons.heart,
              ),
            ),
          ],
        ),
        catalog.when(
          skipLoadingOnRefresh: false,
          loading: () => const _ChoiceGridSkeleton(),
          error: (_, _) => _CatalogFailure(form: form, isLastStep: false),
          data: (items) => items.isEmpty
              ? AppEmptyState(
                  compact: true,
                  title: ref.watch(liveBackendProvider)
                      ? 'Chưa có sở thích để chọn'
                      : 'Chưa có sở thích mẫu',
                  message: 'Bạn vẫn có thể bỏ trống lựa chọn.',
                )
              : _ChoiceGrid(
                  children: [
                    for (final tag in items)
                      _ChoiceCard(
                        icon: interestIcon(tag.label),
                        label: tag.label,
                        selected: form.tags.contains(tag.id),
                        onTap: busy ? null : () => controller.toggleTag(tag.id),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppBanner(
          kind: form.tags.isEmpty ? BannerKind.info : BannerKind.success,
          message: form.tags.isEmpty
              ? 'Chưa chọn sở thích · Bạn có thể tiếp tục.'
              : '${form.tags.length} sở thích đã chọn',
        ),
        if (unverified.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final id in unverified)
                InputChip(
                  key: ValueKey(id),
                  avatar: const Icon(
                    LucideIcons.triangleAlert,
                    size: AppSizes.iconSm,
                  ),
                  label: Text(
                    catalog.hasError
                        ? 'Sở thích đã chọn chưa thể xác minh'
                        : ref.watch(liveBackendProvider)
                        ? 'Sở thích cần sửa: không còn trong danh sách'
                        : 'Sở thích cần sửa: không còn trong danh mục mẫu',
                  ),
                  deleteButtonTooltipMessage: 'Bỏ lựa chọn này',
                  onDeleted: busy ? null : () => controller.removeTag(id),
                ),
            ],
          ),
        ],
        _ErrorText(error('TagIds')),
      ],
    );
  }
}

class _CatalogFailure extends ConsumerWidget {
  const _CatalogFailure({required this.form, required this.isLastStep});
  final PlannerFormState form;
  final bool isLastStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: AppRadius.card,
      border: Border.all(color: context.colors.outline),
    ),
    child: AppErrorState(
      compact: true,
      title: ref.watch(liveBackendProvider)
          ? 'Không tải được danh sách sở thích.'
          : 'Không tải được danh mục mẫu.',
      message: form.tags.isEmpty
          ? 'Bạn có thể bấm ${isLastStep ? (ref.watch(liveBackendProvider) ? 'Tạo lịch trình' : 'Xem lịch trình mẫu') : 'Tiếp tục'} mà không chọn sở thích.'
          : 'Sở thích đã chọn chưa thể xác minh và vẫn được giữ nguyên. Hãy Thử lại hoặc quay lại bước Sở thích để bỏ lựa chọn.',
      onRetry: () {
        ref.read(plannerFormProvider.notifier).clearError('TagIds');
        ref.invalidate(plannerTagsProvider);
      },
    ),
  );
}

class _StyleStep extends ConsumerWidget {
  const _StyleStep({
    required this.form,
    required this.busy,
    required this.catalog,
    required this.note,
    required this.error,
    required this.failure,
    required this.onRetry,
    this.outcomeUnknown = false,
  });
  final PlannerFormState form;
  final bool busy;
  final AsyncValue<List<PlannerTag>> catalog;
  final TextEditingController note;
  final String? Function(String) error;
  final String? failure;
  final VoidCallback onRetry;

  /// Generation may have succeeded: check saved trips before retrying.
  final bool outcomeUnknown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(plannerFormProvider.notifier);
    final date = parsePlannerDate(form.date);
    final budget = num.tryParse(form.budget);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (catalog.hasError) ...[
          _CatalogFailure(form: form, isLastStep: true),
          const SizedBox(height: AppSpacing.lg),
        ],
        const _FieldLabel('Cách di chuyển', icon: LucideIcons.route),
        _ChoiceGrid(
          children: [
            for (final mode in PlannerTravelMode.values)
              _ChoiceCard(
                label: travelModeLabel(mode),
                subtitle: travelModeHint(mode),
                icon: travelModeIcon(mode),
                selected: form.mode == mode,
                onTap: busy ? null : () => controller.setMode(mode),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          fieldKey: const ValueKey('planner-note'),
          label: 'Ghi chú (tùy chọn)',
          hint: 'Ví dụ: thích chỗ yên tĩnh, có máy lạnh',
          helper: 'Tối đa 300 ký tự; emoji có thể được tính nhiều ký tự. Khoảng trắng thừa sẽ được gộp lại.',
          controller: note,
          enabled: !busy,
          maxLines: 4,
          onChanged: controller.setNote,
          errorText: error('Note'),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _FieldLabel('Tóm tắt lựa chọn', icon: LucideIcons.listChecks),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: context.colors.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                _SummaryRow(
                  icon: LucideIcons.trainFront,
                  label: 'Ga xuất phát',
                  value: plannerStationName(form.origin),
                ),
                if (form.destination != null)
                  _SummaryRow(
                    icon: LucideIcons.flag,
                    label: 'Ga đích',
                    value: plannerStationName(form.destination!),
                  ),
                _SummaryRow(
                  icon: LucideIcons.route,
                  label: 'Di chuyển',
                  value: travelModeLabel(form.mode),
                ),
                _SummaryRow(
                  icon: LucideIcons.calendarDays,
                  label: 'Ngày / giờ đi',
                  value:
                      '${form.date.isEmpty
                          ? 'Hôm nay (mặc định)'
                          : date == null
                          ? form.date
                          : formatVietnameseDate(date)} · ${form.time.isEmpty ? '08:00 (mặc định)' : form.time}',
                ),
                _SummaryRow(
                  icon: LucideIcons.timer,
                  label: 'Thời lượng',
                  value: '${form.durationHours} giờ · có thể sang ngày hôm sau',
                ),
                _SummaryRow(
                  icon: LucideIcons.wallet,
                  label: 'Ngân sách tối đa',
                  value:
                      '${budget == null ? form.budget : formatVnd(budget)} VND / người',
                ),
                _SummaryRow(
                  icon: LucideIcons.heart,
                  label: 'Sở thích',
                  value: form.tags.isEmpty
                      ? 'Không chọn'
                      : ref.watch(liveBackendProvider)
                      ? '${form.tags.length} sở thích'
                      : '${form.tags.length} lựa chọn mẫu',
                  last: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _OfflineNotice(),
        if (failure != null && outcomeUnknown) ...[
          const SizedBox(height: AppSpacing.lg),
          AppBanner(
            kind: BannerKind.warning,
            title: 'Chưa rõ lịch trình đã được tạo chưa',
            message: failure!,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            buttonKey: const ValueKey('planner-check-trips'),
            label: 'Xem Lịch trình của tôi',
            icon: LucideIcons.route,
            expand: true,
            onPressed: () => context.go('/trips'),
          ),
        ] else if (failure != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AppErrorState(
            compact: true,
            title: ref.watch(liveBackendProvider)
                ? 'Chưa tạo được lịch trình'
                : 'Chưa tạo được bản mẫu',
            message: failure!,
            onRetry: onRetry,
          ),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: context.colors.outline)),
      ),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: AppSizes.icon,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.xs,
                children: [
                  Text(label, style: text.bodySmall),
                  Text(value, style: text.labelLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = AppSpacing.md;
      final width = (constraints.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _ChoiceGridSkeleton extends StatelessWidget {
  const _ChoiceGridSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Đang tải sở thích…',
    child: _ChoiceGrid(
      children: [
        for (var i = 0; i < 4; i++)
          const SkeletonBlock(
            height: AppSpacing.xxxl * 2,
            radius: AppRadius.lg,
          ),
      ],
    ),
  );
}

/// Selectable card for interests and travel modes.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });
  final String label;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = context.textStyles;
    return Semantics(
      key: ValueKey('planner-choice-$label'),
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? AppSizes.focusRing : AppSizes.hairline,
          ),
        ),
        child: Pressable(
          onTap: onTap == null
              ? null
              : () {
                  AppHaptics.selection();
                  onTap!();
                },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.xxxl * 2),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: AppSpacing.xxl + AppSpacing.xs,
                        height: AppSpacing.xxl + AppSpacing.xs,
                        decoration: BoxDecoration(
                          color: selected
                              ? scheme.primary
                              : scheme.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: AppSizes.icon,
                          color: selected ? scheme.onPrimary : scheme.primary,
                        ),
                      ),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: AppDurations.fast,
                        child: Icon(
                          LucideIcons.circleCheck,
                          size: AppSizes.icon,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(label, style: text.titleSmall),
                  if (subtitle != null) Text(subtitle!, style: text.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading state while the local preview is prepared: a train dot runs
/// along the rail and the checklist fills in.
class _PlannerLoading extends ConsumerStatefulWidget {
  const _PlannerLoading();
  @override
  ConsumerState<_PlannerLoading> createState() => _PlannerLoadingState();
}

class _PlannerLoadingState extends ConsumerState<_PlannerLoading>
    with SingleTickerProviderStateMixin {
  late final _train = AnimationController(
    vsync: this,
    duration: AppDurations.shimmer,
  )..repeat();

  static const _steps = [
    'Đọc ga, thời gian và ngân sách',
    'Chọn điểm dừng phù hợp',
    'Sắp xếp theo giờ',
  ];

  @override
  void dispose() {
    _train.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final app = context.appColors;
    final text = context.textStyles;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: Semantics(
            liveRegion: true,
            label: ref.watch(liveBackendProvider)
                ? 'Đang tạo lịch trình'
                : 'Đang tạo bản mẫu',
            child: Column(
              children: [
                SizedBox(
                  height: AppSpacing.xxxl,
                  child: AnimatedBuilder(
                    animation: _train,
                    builder: (context, _) => CustomPaint(
                      size: const Size(double.infinity, AppSpacing.xxxl),
                      painter: _RailProgressPainter(
                        progress: reduceMotion ? .5 : _train.value,
                        rail: app.metroLine,
                        train: scheme.primary,
                        station: scheme.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Đang chuẩn bị hành trình',
                  textAlign: TextAlign.center,
                  style: text.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sắp xếp các điểm dừng để bạn xem trước.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                for (var i = 0; i < _steps.length; i++)
                  StaggeredEntrance(
                    index: i * 3,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.circleCheck,
                            size: AppSizes.icon,
                            color: app.success,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(_steps[i], style: text.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  ref.watch(liveBackendProvider)
                      ? 'Lịch trình được lưu dưới dạng bản nháp để bạn xem lại.'
                      : 'Bản mẫu offline · Bạn có thể quay lại để điều chỉnh.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailProgressPainter extends CustomPainter {
  const _RailProgressPainter({
    required this.progress,
    required this.rail,
    required this.train,
    required this.station,
  });
  final double progress;
  final Color rail;
  final Color train;
  final Color station;

  static const _stations = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final r = size.height / 8;
    final line = Paint()
      ..color = rail.withValues(alpha: AppOpacity.railInactive)
      ..strokeWidth = AppSizes.railWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(r, y), Offset(size.width - r, y), line);
    final x = r + (size.width - 2 * r) * progress;
    canvas.drawLine(Offset(r, y), Offset(x, y), line..color = rail);
    for (var i = 0; i < _stations; i++) {
      final cx = r + (size.width - 2 * r) * i / (_stations - 1);
      canvas.drawCircle(Offset(cx, y), r, Paint()..color = station);
      canvas.drawCircle(
        Offset(cx, y),
        r,
        Paint()
          ..color = rail
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppSizes.focusRing,
      );
    }
    final car = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y), width: r * 5, height: r * 3),
      Radius.circular(r),
    );
    canvas.drawRRect(car, Paint()..color = train);
  }

  @override
  bool shouldRepaint(_RailProgressPainter old) =>
      old.progress != progress || old.rail != rail || old.train != train;
}
