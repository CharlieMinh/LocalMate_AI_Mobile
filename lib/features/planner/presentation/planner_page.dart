import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/content_states.dart';
import '../../auth/application/auth_controller.dart';
import '../../discovery/data/station_fixture_data.dart';
import '../application/planner_controller.dart';
import '../data/offline_planner_repository.dart';
import '../domain/planner_criteria.dart';

class PlannerEntryPage extends StatelessWidget {
  const PlannerEntryPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Hành trình của bạn',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 32),
      const Icon(Icons.route_outlined, size: 48, color: Brand.navy),
      const SizedBox(height: 16),
      Text(
        'Dành một buổi cho chính mình',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Bắt đầu từ ga, thời gian và sở thích.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => context.push('/planner'),
        icon: const Icon(Icons.add),
        label: const Text('Tạo lịch trình mẫu'),
      ),
      const SizedBox(height: 20),
      const _OfflineNotice(),
    ],
  );
}

class PlannerPage extends ConsumerWidget {
  const PlannerPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return _PlannerForm(key: ObjectKey(auth));
  }
}

class _PlannerForm extends ConsumerStatefulWidget {
  const _PlannerForm({super.key});
  @override
  ConsumerState<_PlannerForm> createState() => _PlannerFormState();
}

class _PlannerFormState extends ConsumerState<_PlannerForm>
    with WidgetsBindingObserver {
  final date = TextEditingController();
  final time = TextEditingController();
  final budget = TextEditingController(text: '0');
  final note = TextEditingController();
  final scroll = ScrollController();
  int origin = 1;
  int? destination;
  int duration = 4;
  PlannerTravelMode mode = PlannerTravelMode.auto;
  final Set<String> tags = {};
  int step = 0;
  bool stepChanging = false;
  Map<String, String> localErrors = {};
  static const titles = [
    'Bắt đầu từ đâu?',
    'Bạn có bao nhiêu thời gian?',
    'Hôm nay bạn thích gì?',
    'Đi theo phong cách của bạn',
  ];
  static const captions = ['VỊ TRÍ', 'THỜI GIAN', 'SỞ THÍCH', 'PHONG CÁCH'];

  void back() {
    ref.read(plannerProvider.notifier).interrupt();
    FocusScope.of(context).unfocus();
    if (step > 0) {
      setState(() {
        step--;
        localErrors = {};
      });
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/trips');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    for (final controller in [date, time, budget, note]) {
      controller.dispose();
    }
    scroll.dispose();
    super.dispose();
  }

  Future<void> submit(List<PlannerTag> catalog) async {
    if (stepChanging) return;
    FocusScope.of(context).unfocus();
    final criteria = PlannerCriteria(
      origin: StationOrigin(origin),
      destinationStationOrder: destination,
      durationHours: duration,
      budgetMax: double.tryParse(budget.text.trim()) ?? double.nan,
      tagIds: tags.toList(),
      travelMode: mode,
      plannedDate: date.text.trim().isEmpty ? null : date.text.trim(),
      startTime: time.text.trim().isEmpty ? null : time.text.trim(),
      note: note.text,
    );
    if (ref.read(plannerProvider).phase == PlannerPhase.processing) return;
    final errors = criteria.validate(
      ref.read(plannerNowProvider)(),
      availableTags: catalog.map((tag) => tag.id).toSet(),
    );
    final keys = switch (step) {
      0 => {'StartStationOrder', 'DestinationStationOrder', 'Origin'},
      1 => {'DurationHours', 'PlannedDate', 'StartTime', 'BudgetMax'},
      2 => {'TagIds'},
      _ => errors.keys.toSet(),
    };
    final current = Map<String, String>.fromEntries(
      errors.entries.where((error) => keys.contains(error.key)),
    );
    if (current.isNotEmpty) {
      setState(() {
        localErrors = current;
        if (step == 3) {
          if (current.keys.any(
            {'PlannedDate', 'StartTime', 'BudgetMax', 'DurationHours'}.contains,
          )) {
            step = 1;
          } else if (current.containsKey('TagIds')) {
            step = 2;
          }
        }
      });
      return;
    }
    if (step < 3) {
      stepChanging = true;
      setState(() {
        step++;
        localErrors = {};
      });
      if (scroll.hasClients) scroll.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) stepChanging = false;
      });
      return;
    }
    final result = await ref
        .read(plannerProvider.notifier)
        .submit(criteria, availableTags: catalog.map((tag) => tag.id).toSet());
    if (!mounted ||
        result == null ||
        ref.read(plannerProvider).preview != result) {
      return;
    }
    await context.push(
      '/planner/preview/${Uri.encodeComponent(result.localKey)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plannerProvider);
    final catalog = ref.watch(plannerTagsProvider);
    final busy = state.phase == PlannerPhase.processing;
    return PopScope(
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tạo lịch trình mẫu'),
          leading: IconButton(
            onPressed: back,
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: SingleChildScrollView(
                      controller: scroll,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'BƯỚC ${step + 1}/4 · ${captions[step]}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Brand.muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'Bước ${step + 1} trên 4',
                            child: Row(
                              children: [
                                for (var i = 0; i < 4; i++)
                                  Expanded(
                                    child: Container(
                                      height: 4,
                                      margin: EdgeInsets.only(
                                        right: i == 3 ? 0 : 6,
                                      ),
                                      color: i <= step
                                          ? Brand.navy
                                          : Brand.line,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ...[
                            Text(
                              titles[step],
                              style: const TextStyle(
                                fontSize: 22,
                                height: 1.35,
                                color: Brand.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (step == 0) ...[
                              DropdownButtonFormField<int>(
                                initialValue: origin,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Ga xuất phát',
                                ),
                                items: [
                                  for (final station in stationSeed)
                                    DropdownMenuItem(
                                      value: station['Order'] as int,
                                      child: Text(
                                        '${station['Order']}. ${station['Name']}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                                onChanged: busy
                                    ? null
                                    : (value) =>
                                          setState(() => origin = value!),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                initialValue: destination ?? 0,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Ga đích (tùy chọn)',
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 0,
                                    child: Text('Không chọn'),
                                  ),
                                  for (final station in stationSeed)
                                    DropdownMenuItem(
                                      value: station['Order'] as int,
                                      child: Text(
                                        '${station['Order']}. ${station['Name']}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                                onChanged: busy
                                    ? null
                                    : (value) => setState(
                                        () => destination = value == 0
                                            ? null
                                            : value,
                                      ),
                              ),
                              const SizedBox(height: 16),
                              const _OfflineNotice(),
                            ],
                            if (step == 1) ...[
                              _field(
                                date,
                                'Ngày đi (yyyy-MM-dd, tùy chọn)',
                                busy,
                                localErrors['PlannedDate'] ??
                                    state.errors['PlannedDate'],
                              ),
                              const SizedBox(height: 16),
                              _field(
                                time,
                                'Giờ bắt đầu (HH:mm, tùy chọn)',
                                busy,
                                localErrors['StartTime'] ??
                                    state.errors['StartTime'],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Giờ Việt Nam. Bỏ trống: ngày hiện tại và 08:00 theo mặc định server. Lịch trình có thể sang ngày hôm sau.',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final h in [2, 4, 6, 8])
                                    ChoiceChip(
                                      label: Text('$h giờ'),
                                      selected: duration == h,
                                      onSelected: busy
                                          ? null
                                          : (_) => setState(() => duration = h),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                key: ValueKey(duration),
                                initialValue: duration,
                                decoration: const InputDecoration(
                                  labelText: 'Thời lượng',
                                ),
                                items: [
                                  for (var h = 1; h <= 24; h++)
                                    DropdownMenuItem(
                                      value: h,
                                      child: Text('$h giờ'),
                                    ),
                                ],
                                onChanged: busy
                                    ? null
                                    : (value) =>
                                          setState(() => duration = value!),
                              ),
                              const SizedBox(height: 16),
                              _field(
                                budget,
                                'Ngân sách tối đa (VND / người)',
                                busy,
                                localErrors['BudgetMax'] ??
                                    state.errors['BudgetMax'],
                                numeric: true,
                              ),
                              const Text(
                                'Ngân sách tối thiểu cố định 0 VND. Giá trị 0 không có nghĩa là không giới hạn.',
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (step == 3) ...[
                              DropdownButtonFormField<PlannerTravelMode>(
                                initialValue: mode,
                                decoration: const InputDecoration(
                                  labelText: 'Di chuyển',
                                ),
                                items: [
                                  for (final value in PlannerTravelMode.values)
                                    DropdownMenuItem(
                                      value: value,
                                      child: Text(switch (value) {
                                        PlannerTravelMode.auto => 'Tự động',
                                        PlannerTravelMode.walking => 'Đi bộ',
                                        PlannerTravelMode.motorbike => 'Xe máy',
                                        PlannerTravelMode.metro => 'Metro',
                                      }),
                                    ),
                                ],
                                onChanged: busy
                                    ? null
                                    : (value) => setState(() => mode = value!),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (step == 2) ...[
                              Text(
                                'Sở thích (không bắt buộc)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Text(
                                'Danh mục mẫu offline; mã sở thích không phải dữ liệu production.',
                              ),
                              catalog.when(
                                loading: () => const LoadingContent(
                                  label: 'Đang tải sở thích mẫu…',
                                ),
                                error: (_, _) => ErrorContent(
                                  message: 'Không tải được danh mục mẫu.',
                                  onRetry: () =>
                                      ref.invalidate(plannerTagsProvider),
                                ),
                                data: (items) => items.isEmpty
                                    ? const EmptyContent(
                                        title: 'Chưa có sở thích mẫu',
                                        message:
                                            'Bạn vẫn có thể bỏ trống lựa chọn.',
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        children: [
                                          for (final tag in items)
                                            FilterChip(
                                              avatar: Icon(switch (tag.label) {
                                                'Văn hóa' =>
                                                  Icons
                                                      .account_balance_outlined,
                                                'Ẩm thực' =>
                                                  Icons.restaurant_outlined,
                                                _ => Icons.park_outlined,
                                              }, size: 18),
                                              label: Text(tag.label),
                                              selected: tags.contains(tag.id),
                                              onSelected: busy
                                                  ? null
                                                  : (selected) => setState(() {
                                                      selected
                                                          ? tags.add(tag.id)
                                                          : tags.remove(tag.id);
                                                    }),
                                            ),
                                        ],
                                      ),
                              ),
                              if (catalog.hasValue)
                                for (final id in tags.where(
                                  (id) =>
                                      !(catalog.asData?.value ?? <PlannerTag>[])
                                          .any((tag) => tag.id == id),
                                ))
                                  InputChip(
                                    label: const Text(
                                      'Sở thích cần sửa: không còn trong danh mục mẫu',
                                    ),
                                    onDeleted: busy
                                        ? null
                                        : () => setState(() => tags.remove(id)),
                                  ),
                              if (state.errors['TagIds'] != null)
                                Text(state.errors['TagIds']!),
                              if (localErrors['TagIds'] != null)
                                Semantics(
                                  liveRegion: true,
                                  child: Text(localErrors['TagIds']!),
                                ),
                              const SizedBox(height: 16),
                            ],
                            if (step == 3) ...[
                              TextField(
                                controller: note,
                                enabled: !busy,
                                minLines: 2,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: 'Ghi chú (tùy chọn)',
                                  helperText: 'Tối đa 300 đơn vị UTF-16 sau chuẩn hóa khoảng trắng.',
                                  errorText:
                                      localErrors['Note'] ??
                                      state.errors['Note'],
                                  helperMaxLines: 4,
                                  errorMaxLines: 4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _review(
                                'Ga xuất phát',
                                stationSeed.firstWhere(
                                      (s) => s['Order'] == origin,
                                    )['Name']
                                    as String,
                              ),
                              _review(
                                'Ngày / giờ đi',
                                '${date.text.isEmpty ? 'Hôm nay (mặc định)' : date.text} · ${time.text.isEmpty ? '08:00 (mặc định)' : time.text}',
                              ),
                              _review(
                                'Thời lượng',
                                '$duration giờ · có thể sang ngày hôm sau',
                              ),
                              _review(
                                'Ngân sách tối đa',
                                '${budget.text} VND / người',
                              ),
                              _review(
                                'Sở thích',
                                tags.isEmpty
                                    ? 'Không chọn'
                                    : '${tags.length} lựa chọn mẫu',
                              ),
                              const SizedBox(height: 20),
                              const _OfflineNotice(),
                              if (state.message != null)
                                ErrorContent(
                                  message: state.message!,
                                  onRetry: () =>
                                      submit(catalog.asData?.value ?? []),
                                ),
                              if (busy)
                                const LoadingContent(
                                  label: 'Đang chuẩn bị preview cục bộ…',
                                ),
                            ],
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Brand.line)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        busy ||
                            (step >= 2 &&
                                (catalog.isLoading || catalog.hasError))
                        ? null
                        : () => submit(catalog.asData?.value ?? []),
                    icon: Icon(
                      step == 3
                          ? Icons.auto_awesome_outlined
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      busy
                          ? 'Đang tạo bản mẫu…'
                          : step == 3
                          ? 'Xem lịch trình mẫu'
                          : 'Tiếp tục',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _review(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Brand.line)),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 16,
      runSpacing: 6,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Brand.muted)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Brand.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    bool busy,
    String? error, {
    bool numeric = false,
  }) => TextField(
    controller: controller,
    enabled: !busy,
    keyboardType: numeric ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      errorText: error,
      errorMaxLines: 4,
      suffixIcon: label.startsWith('Ngày đi') || label.startsWith('Giờ bắt đầu')
          ? IconButton(
              tooltip: label.startsWith('Ngày') ? 'Chọn ngày' : 'Chọn giờ',
              onPressed: busy
                  ? null
                  : () => _pick(controller, label.startsWith('Ngày')),
              icon: Icon(
                label.startsWith('Ngày')
                    ? Icons.calendar_today_outlined
                    : Icons.schedule,
              ),
            )
          : null,
    ),
  );

  Future<void> _pick(TextEditingController controller, bool isDate) async {
    FocusScope.of(context).unfocus();
    if (isDate) {
      final now = vietnamCivilNow(ref.read(plannerNowProvider)());
      final today = DateTime(now.year, now.month, now.day);
      final last = today.add(const Duration(days: 90));
      final parsed = parsePlannerDate(controller.text);
      final selected = parsed == null
          ? today
          : DateTime(parsed.year, parsed.month, parsed.day);
      final picked = await showDatePicker(
        context: context,
        firstDate: today,
        lastDate: last,
        initialDate: selected.isBefore(today) || selected.isAfter(last)
            ? today
            : selected,
        helpText: 'Chọn ngày đi',
        cancelText: 'Hủy',
        confirmText: 'Chọn',
      );
      if (!mounted || picked == null) return;
      controller.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    } else {
      final minutes = parsePlannerTime(controller.text) ?? 480;
      final picked = await showTimePicker(
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
      if (!mounted || picked == null) return;
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
    setState(() {});
  }
}

class PlannerPreviewPage extends ConsumerWidget {
  const PlannerPreviewPage({super.key, required this.localKey});
  final String localKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(plannerProvider).preview;
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch trình mẫu offline')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: preview == null || preview.localKey != localKey
                ? const EmptyContent(
                    title: 'Bản mẫu không còn khả dụng',
                    message: 'Phiên hoặc thao tác đã thay đổi. Quay lại để tạo preview mới.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const _OfflineNotice(),
                      const SizedBox(height: 16),
                      OfflinePreviewContent(preview: preview),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Brand.amber.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'CHẾ ĐỘ OFFLINE • Chỉ xem lịch trình mẫu. Không gọi AI, không lưu Trip, không tiêu hao lượt dùng.',
      ),
    ),
  );
}

class OfflinePreviewContent extends StatelessWidget {
  const OfflinePreviewContent({super.key, required this.preview});
  final OfflineDraftPreview preview;
  String clock(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  String stopLabel(int index) {
    final value = preview.start.add(
      Duration(
        minutes:
            index *
            preview.criteria.durationHours *
            60 ~/
            preview.sampleStops.length,
      ),
    );
    final nextDay =
        value.year != preview.start.year ||
        value.month != preview.start.month ||
        value.day != preview.start.day;
    return '${clock(value)}${nextDay ? ' (ngày hôm sau)' : ''} · mốc minh họa';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Bản xem trước tạm thời',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const Text(
        'Không phải kết quả AI hay Draft đã lưu. Đóng ứng dụng hoặc đổi phiên sẽ mất bản mẫu.',
      ),
      const SizedBox(height: 16),
      Text(
        'Khung giờ minh họa: ${clock(preview.start)} → ${clock(preview.end)}${preview.endsNextDay ? ' (ngày hôm sau)' : ''}',
      ),
      Text(
        'Ngày bắt đầu: ${preview.start.toIso8601String().substring(0, 10)} • giờ Việt Nam',
      ),
      Text(
        'Thời lượng lựa chọn: ${preview.criteria.durationHours} giờ • ${preview.criteria.travelMode.wire}',
      ),
      Text(
        'Ngân sách bạn nhập: ${preview.criteria.budgetMax.toString().replaceFirst(RegExp(r'\.0$'), '')} VND / người',
      ),
      const Text(
        'Giá và thứ tự bên dưới chỉ minh họa; không phải báo giá hay tối ưu tuyến thực tế.',
      ),
      const SizedBox(height: 24),
      Text(
        'Lịch trình theo giờ',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      for (var i = 0; i < preview.sampleStops.length; i++)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Brand.navy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: i + 1 < preview.sampleStops.length
                            ? Brand.line
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        stopLabel(i),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Brand.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Brand.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.place_outlined, color: Brand.navy),
                            const SizedBox(height: 10),
                            Text(
                              preview.sampleStops[i],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Brand.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Dừng tham quan minh họa • ước tính mẫu 0 VND, không phải giá xác nhận',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      if (normalizePlannerNote(preview.criteria.note) != null)
        Text(
          'Ghi chú của bạn: ${normalizePlannerNote(preview.criteria.note) ?? ''}',
        ),
      const Text('Chưa kết nối Backend. Không có Trip ID, Save hoặc Finalize.'),
    ],
  );
}
