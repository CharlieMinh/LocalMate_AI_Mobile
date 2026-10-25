import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/widgets/content_states.dart';
import '../../../shared/widgets/content_container.dart';
import '../../../shared/widgets/feedback_banner.dart';
import '../../auth/application/auth_controller.dart';
import '../../discovery/data/station_fixture_data.dart';
import '../application/planner_controller.dart';
import '../data/offline_planner_repository.dart';
import '../domain/planner_criteria.dart';

class PlannerEntryPage extends StatelessWidget {
  const PlannerEntryPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.zero,
    children: [
      ContentContainer(
        maxWidth: 520,
        verticalPadding: 56,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.wallet_outlined, size: 42, color: Brand.muted),
            const SizedBox(height: 24),
            const Text(
              'Một hành trình đang chờ bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: Brand.ink,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Chọn một ga và thời gian rảnh để bắt đầu hành trình đầu tiên.',
              textAlign: TextAlign.center,
              style: BrandTypography.body,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/planner'),
              icon: const Icon(Icons.add),
              label: const Text('Tạo lịch trình mẫu'),
            ),
            const SizedBox(height: 24),
            const _OfflineNotice(),
            const Text(
              'Lịch trình đã lưu chưa được kết nối. Bản xem trước chỉ tồn tại tạm thời trong phiên, không phải chuyến đi đã lưu.',
              textAlign: TextAlign.center,
              style: BrandTypography.metadata,
            ),
          ],
        ),
      ),
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
  static const helpers = [
    'Chọn một ga trên tuyến Metro số 1.',
    'Một hành trình vừa với khoảng thời gian rảnh.',
    'Chọn các trải nghiệm bạn muốn ưu tiên, hoặc tiếp tục mà không chọn.',
    'Hoàn tất lựa chọn trước khi xem lịch trình mẫu.',
  ];

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
    final catalogState = ref.read(plannerTagsProvider);
    if (step >= 2 &&
        (catalogState.isLoading ||
            (catalogState.hasError && tags.isNotEmpty))) {
      setState(() {
        step = 2;
        localErrors['TagIds'] = 'Sở thích đã chọn chưa thể xác minh. Hãy thử lại hoặc chủ động bỏ lựa chọn.';
      });
      return;
    }
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
    final reviewDate = parsePlannerDate(date.text);
    Widget catalogFailure() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ErrorContent(
          message: 'Không tải được danh mục mẫu.',
          onRetry: () {
            setState(() => localErrors.remove('TagIds'));
            ref.invalidate(plannerTagsProvider);
          },
        ),
        Text(
          tags.isEmpty
              ? 'Bạn có thể bấm ${step == 3 ? 'Xem lịch trình mẫu' : 'Tiếp tục'} mà không chọn sở thích.'
              : 'Sở thích đã chọn chưa thể xác minh và vẫn được giữ nguyên. Hãy Thử lại hoặc quay lại bước Sở thích để bỏ lựa chọn.',
        ),
      ],
    );
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
                child: busy
                    ? const _PlannerLoading()
                    : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: SingleChildScrollView(
                            controller: scroll,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
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
                                const SizedBox(height: 18),
                                Text(
                                  'BƯỚC ${step + 1}/4 · ${captions[step]}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 18 / 11,
                                    fontWeight: FontWeight.w600,
                                    color: Brand.navy,
                                  ),
                                ),
                                const SizedBox(height: 7),
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
                                  const SizedBox(height: 7),
                                  Text(
                                    helpers[step],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 20 / 12,
                                      color: Brand.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 23),
                                  if (step == 0) ...[
                                    const _PlannerLabel('Ga xuất phát'),
                                    DropdownButtonFormField<int>(
                                      initialValue: origin,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Ga xuất phát',
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.never,
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
                                    const _PlannerLabel('Ga đích (tùy chọn)'),
                                    DropdownButtonFormField<int>(
                                      initialValue: destination ?? 0,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Ga đích (tùy chọn)',
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.never,
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
                                    const FeedbackBanner(
                                      message: 'Địa điểm và thứ tự di chuyển sẽ được xem lại trong bản mẫu.',
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
                                    const _PlannerLabel('Thời lượng'),
                                    _PlannerChoiceGrid(
                                      children: [
                                        for (final h in [2, 4, 6, 8])
                                          _PlannerChoiceCard(
                                            label: h < 6
                                                ? '$h giờ'
                                                : h == 6
                                                ? 'Một buổi · 6 giờ'
                                                : 'Cả ngày · 8 giờ',
                                            icon: h < 6
                                                ? Icons.schedule
                                                : Icons.light_mode_outlined,
                                            selected: duration == h,
                                            onTap: busy
                                                ? null
                                                : () => setState(
                                                    () => duration = h,
                                                  ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const _PlannerLabel(
                                      'Thời lượng khác (1–24 giờ)',
                                    ),
                                    DropdownButtonFormField<int>(
                                      key: ValueKey(duration),
                                      initialValue: duration,
                                      decoration: const InputDecoration(
                                        labelText: 'Thời lượng',
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.never,
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
                                          : (value) => setState(
                                              () => duration = value!,
                                            ),
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
                                    const _PlannerLabel('Cách di chuyển'),
                                    _PlannerChoiceGrid(
                                      children: [
                                        for (final value
                                            in PlannerTravelMode.values)
                                          _PlannerChoiceCard(
                                            label: switch (value) {
                                              PlannerTravelMode.auto =>
                                                'Tự động',
                                              PlannerTravelMode.walking =>
                                                'Đi bộ',
                                              PlannerTravelMode.motorbike =>
                                                'Xe máy',
                                              PlannerTravelMode.metro =>
                                                'Metro',
                                            },
                                            icon: switch (value) {
                                              PlannerTravelMode.auto =>
                                                Icons.auto_awesome_outlined,
                                              PlannerTravelMode.walking =>
                                                Icons.directions_walk,
                                              PlannerTravelMode.motorbike =>
                                                Icons.two_wheeler,
                                              PlannerTravelMode.metro =>
                                                Icons.train_outlined,
                                            },
                                            selected: mode == value,
                                            onTap: busy
                                                ? null
                                                : () => setState(
                                                    () => mode = value,
                                                  ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                  if (step == 2) ...[
                                    const _PlannerLabel(
                                      'Sở thích (không bắt buộc)',
                                    ),
                                    const Text(
                                      'Danh mục mẫu offline; mã sở thích không phải dữ liệu production.',
                                      style: BrandTypography.metadata,
                                    ),
                                    const SizedBox(height: 16),
                                    catalog.when(
                                      skipLoadingOnRefresh: false,
                                      loading: () => const LoadingContent(
                                        label: 'Đang tải sở thích mẫu…',
                                      ),
                                      error: (_, _) => catalogFailure(),
                                      data: (items) => items.isEmpty
                                          ? const EmptyContent(
                                              title: 'Chưa có sở thích mẫu',
                                              message: 'Bạn vẫn có thể bỏ trống lựa chọn.',
                                            )
                                          : _PlannerChoiceGrid(
                                              children: [
                                                for (final tag in items)
                                                  _PlannerChoiceCard(
                                                    icon: switch (tag.label) {
                                                      'Văn hóa' =>
                                                        Icons
                                                            .account_balance_outlined,
                                                      'Ẩm thực' =>
                                                        Icons
                                                            .restaurant_outlined,
                                                      'Cà phê' =>
                                                        Icons
                                                            .local_cafe_outlined,
                                                      _ => Icons.park_outlined,
                                                    },
                                                    label: tag.label,
                                                    selected: tags.contains(
                                                      tag.id,
                                                    ),
                                                    onTap: busy
                                                        ? null
                                                        : () => setState(() {
                                                            tags.contains(
                                                                  tag.id,
                                                                )
                                                                ? tags.remove(
                                                                    tag.id,
                                                                  )
                                                                : tags.add(
                                                                    tag.id,
                                                                  );
                                                          }),
                                                  ),
                                              ],
                                            ),
                                    ),
                                    const SizedBox(height: 16),
                                    FeedbackBanner(
                                      message: tags.isEmpty
                                          ? 'Chưa chọn sở thích · Bạn có thể tiếp tục.'
                                          : '${tags.length} sở thích đã chọn',
                                    ),
                                    if (catalog.hasError || catalog.hasValue)
                                      for (final id in tags.where(
                                        (id) =>
                                            catalog.hasError ||
                                            !(catalog.asData?.value ??
                                                    <PlannerTag>[])
                                                .any((tag) => tag.id == id),
                                      ))
                                        InputChip(
                                          key: ValueKey(id),
                                          label: Text(
                                            catalog.hasError
                                                ? 'Sở thích đã chọn chưa thể xác minh'
                                                : 'Sở thích cần sửa: không còn trong danh mục mẫu',
                                          ),
                                          deleteButtonTooltipMessage:
                                              'Bỏ lựa chọn này',
                                          onDeleted: busy
                                              ? null
                                              : () => setState(
                                                  () => tags.remove(id),
                                                ),
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
                                    if (catalog.hasError) catalogFailure(),
                                    TextField(
                                      controller: note,
                                      enabled: !busy,
                                      minLines: 2,
                                      maxLines: 4,
                                      decoration: InputDecoration(
                                        labelText: 'Ghi chú (tùy chọn)',
                                        helper: const Text(
                                          'Tối đa 300 ký tự; emoji có thể được tính nhiều ký tự. Khoảng trắng thừa sẽ được gộp lại.',
                                        ),
                                        errorText:
                                            localErrors['Note'] ??
                                            state.errors['Note'],
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
                                    if (destination != null)
                                      _review(
                                        'Ga đích',
                                        stationSeed.firstWhere(
                                              (s) => s['Order'] == destination,
                                            )['Name']
                                            as String,
                                      ),
                                    _review('Di chuyển', switch (mode) {
                                      PlannerTravelMode.auto => 'Tự động',
                                      PlannerTravelMode.walking => 'Đi bộ',
                                      PlannerTravelMode.motorbike => 'Xe máy',
                                      PlannerTravelMode.metro => 'Metro',
                                    }),
                                    _review(
                                      'Ngày / giờ đi',
                                      '${date.text.isEmpty
                                          ? 'Hôm nay (mặc định)'
                                          : reviewDate == null
                                          ? date.text
                                          : formatVietnameseDate(reviewDate)} · ${time.text.isEmpty ? '08:00 (mặc định)' : time.text}',
                                    ),
                                    _review(
                                      'Thời lượng',
                                      '$duration giờ · có thể sang ngày hôm sau',
                                    ),
                                    _review(
                                      'Ngân sách tối đa',
                                      '${num.tryParse(budget.text) == null ? budget.text : formatVnd(num.parse(budget.text))} VND / người',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                                (catalog.isLoading ||
                                    (catalog.hasError && tags.isNotEmpty)))
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
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _PlannerLabel(
        label.startsWith('Ngày đi')
            ? 'Ngày đi'
            : label.startsWith('Giờ bắt đầu')
            ? 'Giờ xuất phát'
            : label,
      ),
      TextField(
        controller: controller,
        enabled: !busy,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          errorText: error,
          errorMaxLines: 4,
          suffixIcon:
              label.startsWith('Ngày đi') || label.startsWith('Giờ bắt đầu')
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
      ),
    ],
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

class _PlannerLoading extends StatelessWidget {
  const _PlannerLoading();
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: ContentContainer(
        maxWidth: 480,
        verticalPadding: 32,
        child: Semantics(
          liveRegion: true,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Brand.infoSurface,
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: Brand.navy,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Đang chuẩn bị hành trình',
                textAlign: TextAlign.center,
                style: BrandTypography.screenTitle,
              ),
              const SizedBox(height: 12),
              const Text(
                'Sắp xếp các điểm dừng để bạn xem trước.',
                textAlign: TextAlign.center,
                style: BrandTypography.body,
              ),
              const SizedBox(height: 24),
              const LinearProgressIndicator(semanticsLabel: 'Đang tạo bản mẫu'),
              const SizedBox(height: 24),
              const Text(
                'Bản mẫu offline · Bạn có thể quay lại để điều chỉnh.',
                textAlign: TextAlign.center,
                style: BrandTypography.metadata,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PlannerLabel extends StatelessWidget {
  const _PlannerLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        height: 19 / 12,
        fontWeight: FontWeight.w600,
        color: Brand.ink,
      ),
    ),
  );
}

class _PlannerChoiceGrid extends StatelessWidget {
  const _PlannerChoiceGrid({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final child in children)
          SizedBox(width: (constraints.maxWidth - 10) / 2, child: child),
      ],
    ),
  );
}

class _PlannerChoiceCard extends StatelessWidget {
  const _PlannerChoiceCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('planner-choice-$label'),
    button: true,
    selected: selected,
    enabled: onTap != null,
    child: Material(
      color: selected ? Brand.infoSurface : Brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? Brand.navy : Brand.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 57),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, size: 19, color: Brand.navy),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      height: 19 / 12,
                      color: selected ? Brand.navy : Brand.ink,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.check, size: 16, color: Brand.navy),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class PlannerPreviewPage extends ConsumerWidget {
  const PlannerPreviewPage({super.key, required this.localKey});
  final String localKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(plannerProvider).preview;
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch trình mẫu offline')),
      bottomNavigationBar: preview == null || preview.localKey != localKey
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Brand.surface,
                  border: Border(top: BorderSide(color: Brand.line)),
                ),
                child: FilledButton.icon(
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/planner'),
                  icon: const Icon(Icons.tune, size: 20),
                  label: const Text('Điều chỉnh lịch trình'),
                ),
              ),
            ),
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
                    children: [OfflinePreviewContent(preview: preview)],
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
        style: TextStyle(
          fontSize: 12,
          height: 20 / 12,
          color: Brand.warningText,
        ),
      ),
    ),
  );
}

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
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Brand.warningSurface,
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Text(
            'Bản mẫu offline',
            style: TextStyle(
              fontSize: 11,
              height: 16 / 11,
              color: Brand.warningText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Quanh ga $originName · ${preview.criteria.durationHours} giờ',
        style: const TextStyle(
          fontSize: 23,
          height: 31 / 23,
          fontWeight: FontWeight.w700,
          color: Brand.ink,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        '${formatVietnameseDate(preview.start)} · xuất phát ${clock(preview.start)} · giờ Việt Nam',
        style: BrandTypography.body.copyWith(color: Brand.muted),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _PreviewMeta(
            Icons.schedule,
            '${preview.criteria.durationHours} giờ đã chọn',
          ),
          _PreviewMeta(
            Icons.place_outlined,
            '${preview.sampleStops.length} điểm dừng mẫu',
          ),
          _PreviewMeta(
            Icons.account_balance_wallet_outlined,
            'Tối đa ${formatVnd(preview.criteria.budgetMax)} VND / người',
          ),
          _PreviewMeta(
            Icons.directions_outlined,
            switch (preview.criteria.travelMode) {
              PlannerTravelMode.auto => 'Tự động',
              PlannerTravelMode.walking => 'Đi bộ',
              PlannerTravelMode.motorbike => 'Xe máy',
              PlannerTravelMode.metro => 'Metro',
            },
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        'Khung giờ minh họa: ${clock(preview.start)} → ${clock(preview.end)}${preview.endsNextDay ? ' (ngày hôm sau)' : ''}',
        style: BrandTypography.body.copyWith(color: Brand.navy),
      ),
      const SizedBox(height: 16),
      const _OfflineNotice(),
      const SizedBox(height: 24),
      Text('Lịch trình theo giờ', style: BrandTypography.sectionTitle),
      const SizedBox(height: 16),
      for (var i = 0; i < preview.sampleStops.length; i++)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 23,
                      height: 23,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Brand.navy,
                        shape: BoxShape.circle,
                        border: Border.all(color: Brand.canvas, width: 2),
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
                            ? Brand.timelineBorder
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 67,
                              height: 67,
                              decoration: BoxDecoration(
                                color: Brand.infoSurface,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Icon(
                                Icons.place_outlined,
                                color: Brand.navy,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preview.sampleStops[i],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      height: 19 / 12,
                                      color: Brand.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Dừng tham quan minh họa · ước tính mẫu 0 VND, không phải giá xác nhận',
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 18 / 11,
                                      color: Brand.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i + 1 < preview.sampleStops.length) ...[
                        const SizedBox(height: 9),
                        const Text.rich(
                          TextSpan(
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 5),
                                  child: Icon(
                                    Icons.route_outlined,
                                    size: 14,
                                    color: Brand.muted,
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: 'Thứ tự di chuyển minh họa · chưa tối ưu tuyến',
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            height: 18 / 11,
                            color: Brand.muted,
                          ),
                        ),
                      ],
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
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: () => context.push('/metro'),
        icon: const Icon(Icons.train_outlined),
        label: const Text('Ga Metro & liên kết chỉ đường'),
      ),
      const SizedBox(height: 16),
      const Text(
        'Bản xem trước tạm thời, không phải kết quả AI hay Draft đã lưu. Giá và thứ tự chỉ minh họa; đóng ứng dụng hoặc đổi phiên sẽ mất bản mẫu.',
        style: BrandTypography.metadata,
      ),
      const SizedBox(height: 8),
      const Text(
        'Chưa kết nối Backend. Không có Trip ID, Save hoặc Finalize.',
        style: BrandTypography.metadata,
      ),
    ],
  );
}

class _PreviewMeta extends StatelessWidget {
  const _PreviewMeta(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Icon(icon, size: 15, color: Brand.muted),
          ),
        ),
        TextSpan(text: label),
      ],
    ),
    style: const TextStyle(fontSize: 12, height: 20 / 12, color: Brand.muted),
  );
}
