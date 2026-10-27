// Debug-only showcase of design tokens and core widgets ("Tuyến Ga").
// Routed at /dev/gallery when kDebugMode; never reachable in release builds.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../core/widgets/widgets.dart';
import '../features/discovery/data/station_fixture_data.dart';

class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key, this.initialDark = false});

  final bool initialDark;

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  late bool _dark = widget.initialDark;

  @override
  Widget build(BuildContext context) => AnimatedTheme(
    data: _dark ? AppTheme.dark : AppTheme.light,
    duration: AppDurations.medium,
    child: Builder(
      builder: (context) => Scaffold(
        body: CustomScrollView(
          slivers: [
            AppLargeTitleBar(
              title: 'Thư viện thành phần',
              actions: [
                AppIconButton(
                  icon: _dark ? LucideIcons.sun : LucideIcons.moon,
                  tooltip: _dark ? 'Chuyển sang sáng' : 'Chuyển sang tối',
                  variant: AppIconButtonVariant.tonal,
                  onPressed: () => setState(() => _dark = !_dark),
                ),
              ],
            ),
            const SliverToBoxAdapter(child: _GalleryBody()),
          ],
        ),
        bottomNavigationBar: const _NavPreview(),
      ),
    ),
  );
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Section('Màu sắc', child: _ColorTokens()),
      _Section('Chữ', child: _TypeScale()),
      _Section('Khoảng cách · bo góc · bóng', child: _ShapeTokens()),
      _Section('Nút', child: _Buttons()),
      _Section('Ô nhập & tìm kiếm', child: _Inputs()),
      _Section('Chip & trạng thái', child: _Chips()),
      _Section('Thông báo trong nội dung', child: _Banners()),
      _Section('Metro số 1', flush: true, child: _Metro()),
      _Section('Thẻ địa điểm', flush: true, child: _Places()),
      _Section('Lịch trình (timeline)', child: _Timeline()),
      _Section('Thông tin & đánh giá', child: _InfoAndRating()),
      _Section('Skeleton khi tải', child: _Skeletons()),
      _Section('Trạng thái rỗng · lỗi · offline', child: _States()),
      _Section('Minh họa', child: _Illustrations()),
      _Section('Bottom sheet & thanh hành động', child: _Sheets()),
      SizedBox(height: AppSpacing.xxxl),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child, this.flush = false});

  final String title;
  final Widget child;

  /// Child handles its own horizontal padding (horizontal scrollers).
  final bool flush;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: flush ? 0 : AppSpacing.gutter,
          ),
          child: child,
        ),
      ],
    ),
  );
}

class _ColorTokens extends StatelessWidget {
  const _ColorTokens();

  @override
  Widget build(BuildContext context) {
    final s = context.colors;
    final a = context.appColors;
    final swatches = <(String, Color, Color)>[
      ('primary', s.primary, s.onPrimary),
      ('primaryContainer', s.primaryContainer, s.onPrimaryContainer),
      ('metroLine', a.metroLine, s.surface),
      ('secondary (amber)', s.secondary, s.onSecondary),
      ('warningContainer', a.warningContainer, a.onWarningContainer),
      ('success', a.success, s.surface),
      ('successContainer', a.successContainer, a.onSuccessContainer),
      ('error', s.error, s.onError),
      ('surface', s.surface, s.onSurface),
      ('surfaceContainer', s.surfaceContainer, s.onSurface),
      ('onSurface', s.onSurface, s.surface),
      ('onSurfaceVariant', s.onSurfaceVariant, s.surface),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (name, bg, fg) in swatches)
          Container(
            width: AppSizes.placeCardWidth / 2,
            height: AppSpacing.xxxl + AppSpacing.lg,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.control,
              border: Border.all(color: s.outline),
            ),
            alignment: Alignment.bottomLeft,
            child: Text(
              name,
              style: context.textStyles.labelSmall?.copyWith(color: fg),
            ),
          ),
      ],
    );
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final t = context.textStyles;
    final rows = <(String, TextStyle?)>[
      ('displaySmall 28/800', t.displaySmall),
      ('headlineSmall 24/800', t.headlineSmall),
      ('titleLarge 20/700', t.titleLarge),
      ('titleMedium 17/700', t.titleMedium),
      ('titleSmall 15/600', t.titleSmall),
      ('bodyLarge 16', t.bodyLarge),
      ('bodyMedium 15', t.bodyMedium),
      ('bodySmall 13', t.bodySmall),
      ('labelLarge 15/600', t.labelLarge),
      ('labelMedium 13/600', t.labelMedium),
      ('labelSmall 12/600', t.labelSmall),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, style) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Khám phá quanh ga Bến Thành', style: style),
                Text(name, style: t.labelSmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _ShapeTokens extends StatelessWidget {
  const _ShapeTokens();

  @override
  Widget build(BuildContext context) {
    final s = context.colors;
    final t = context.textStyles;
    const spaces = [
      ('xs', AppSpacing.xs),
      ('sm', AppSpacing.sm),
      ('md', AppSpacing.md),
      ('lg', AppSpacing.lg),
      ('xl', AppSpacing.xl),
      ('xxl', AppSpacing.xxl),
      ('xxxl', AppSpacing.xxxl),
    ];
    const radii = [
      ('xs 6', AppRadius.xs),
      ('sm 10', AppRadius.sm),
      ('md 16', AppRadius.md),
      ('lg 20', AppRadius.lg),
      ('xl 28', AppRadius.xl),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, value) in spaces)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: AppSpacing.xxxl,
                  child: Text(name, style: t.labelSmall),
                ),
                Container(width: value, height: AppSpacing.md, color: s.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('${value.toInt()}', style: t.bodySmall),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final (name, r) in radii)
              Container(
                width: AppSpacing.xxxl + AppSpacing.lg,
                height: AppSpacing.xxxl + AppSpacing.lg,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: s.primaryContainer,
                  borderRadius: BorderRadius.all(Radius.circular(r)),
                ),
                child: Text(name, style: t.labelSmall),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            for (final (name, shadow) in [
              ('soft', AppShadows.soft(context.appColors.shadow)),
              ('raised', AppShadows.raised(context.appColors.shadow)),
            ])
              Expanded(
                child: Container(
                  height: AppSpacing.xxxl + AppSpacing.lg,
                  margin: const EdgeInsets.only(right: AppSpacing.md),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s.surface,
                    borderRadius: AppRadius.card,
                    boxShadow: shadow,
                  ),
                  child: Text('Bóng $name', style: t.labelMedium),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Chuyển động: fast ${AppDurations.fast.inMilliseconds}ms · '
          'medium ${AppDurations.medium.inMilliseconds}ms · '
          'slow ${AppDurations.slow.inMilliseconds}ms · easeOutCubic',
          style: t.bodySmall,
        ),
      ],
    );
  }
}

class _Buttons extends StatefulWidget {
  const _Buttons();

  @override
  State<_Buttons> createState() => _ButtonsState();
}

class _ButtonsState extends State<_Buttons> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppButton(
        label: 'Tạo lịch trình',
        icon: LucideIcons.sparkles,
        expand: true,
        haptic: true,
        loading: _loading,
        onPressed: () => setState(() => _loading = !_loading),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppButton.secondary(
        label: 'Xem trên Google Maps',
        icon: LucideIcons.map,
        expand: true,
        onPressed: () {},
      ),
      const SizedBox(height: AppSpacing.sm),
      AppButton.tonal(
        label: 'Đổi điểm',
        icon: LucideIcons.refreshCw,
        expand: true,
        onPressed: () {},
      ),
      const SizedBox(height: AppSpacing.sm),
      const AppButton(label: 'Đã hết lượt tạo', onPressed: null, expand: true),
      const SizedBox(height: AppSpacing.sm),
      AppButton(
        label: 'Xóa lịch trình',
        variant: AppButtonVariant.danger,
        icon: LucideIcons.trash2,
        expand: true,
        onPressed: () {},
      ),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppButton(label: 'Nhỏ', compact: true, onPressed: () {}),
          AppButton.ghost(
            label: 'Xem tất cả',
            trailingIcon: LucideIcons.arrowRight,
            onPressed: () {},
          ),
          AppIconButton(
            icon: LucideIcons.bell,
            tooltip: 'Thông báo',
            badge: true,
            onPressed: () {},
          ),
          AppIconButton(
            icon: LucideIcons.arrowLeftRight,
            tooltip: 'Đổi chiều',
            variant: AppIconButtonVariant.tonal,
            onPressed: () {},
          ),
          AppIconButton(
            icon: LucideIcons.plus,
            tooltip: 'Thêm',
            variant: AppIconButtonVariant.filled,
            onPressed: () {},
          ),
        ],
      ),
    ],
  );
}

class _Inputs extends StatefulWidget {
  const _Inputs();

  @override
  State<_Inputs> createState() => _InputsState();
}

class _InputsState extends State<_Inputs> {
  final _search = TextEditingController(text: 'Cà phê');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppSearchBar(hint: 'Tìm địa điểm quanh ga Metro', onTap: () {}),
      const SizedBox(height: AppSpacing.md),
      AppSearchBar(hint: 'Tìm địa điểm hoặc ga', controller: _search),
      const SizedBox(height: AppSpacing.lg),
      const AppTextField(
        label: 'Email',
        hint: 'ban@vidu.com',
        prefixIcon: LucideIcons.mail,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: AppSpacing.lg),
      const AppTextField(
        label: 'Mật khẩu',
        obscure: true,
        prefixIcon: LucideIcons.lock,
        errorText: 'Mật khẩu cần ít nhất 8 ký tự.',
      ),
      const SizedBox(height: AppSpacing.lg),
      const AppTextField(
        label: 'Ghi chú cho chuyến đi',
        hint: 'Ví dụ: thích chỗ yên tĩnh, có máy lạnh',
        helper: 'Không bắt buộc · tối đa 300 ký tự',
        maxLines: 3,
      ),
    ],
  );
}

class _Chips extends StatefulWidget {
  const _Chips();

  @override
  State<_Chips> createState() => _ChipsState();
}

class _ChipsState extends State<_Chips> {
  String _category = 'all';
  int _hours = 4;
  String _mode = 'Auto';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppChipGroup<String>(
        selected: _category,
        onSelected: (v) => setState(() => _category = v),
        options: const [
          AppChipOption(value: 'all', label: 'Tất cả'),
          AppChipOption(value: 'Cafe', label: 'Cà phê', icon: LucideIcons.coffee),
          AppChipOption(value: 'Food', label: 'Ẩm thực', icon: LucideIcons.utensils),
          AppChipOption(value: 'Culture', label: 'Văn hóa', icon: LucideIcons.landmark),
          AppChipOption(value: 'CheckIn', label: 'Check-in', icon: LucideIcons.camera),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      AppChipGroup<int>(
        wrap: true,
        selected: _hours,
        onSelected: (v) => setState(() => _hours = v),
        options: const [
          AppChipOption(value: 2, label: '2 giờ'),
          AppChipOption(value: 4, label: '4 giờ'),
          AppChipOption(value: 6, label: '6 giờ'),
          AppChipOption(value: 8, label: '8 giờ'),
          AppChipOption(value: 0, label: 'Tùy chỉnh', icon: LucideIcons.slidersHorizontal),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'Auto', label: Text('Tự động')),
          ButtonSegment(value: 'Metro', label: Text('Metro')),
          ButtonSegment(value: 'Walking', label: Text('Đi bộ')),
        ],
        selected: {_mode},
        showSelectedIcon: false,
        onSelectionChanged: (v) => setState(() => _mode = v.first),
      ),
      const SizedBox(height: AppSpacing.md),
      const Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          StatusChip(label: 'Bản nháp', kind: StatusKind.draft, icon: LucideIcons.pencil),
          StatusChip(label: 'Đã chốt', kind: StatusKind.finalized, icon: LucideIcons.circleCheck),
          StatusChip(label: 'Ước tính', kind: StatusKind.info),
          StatusChip(label: 'Dữ liệu minh họa'),
          StatusChip(label: 'Đang đóng cửa', kind: StatusKind.danger),
        ],
      ),
    ],
  );
}

class _Banners extends StatelessWidget {
  const _Banners();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const AppBanner(message: 'Lịch tàu là lịch ước tính, khoảng 8 phút một chuyến.'),
      const SizedBox(height: AppSpacing.sm),
      const AppBanner(
        kind: BannerKind.warning,
        message: 'Xem lại từng điểm dừng trước khi chốt lịch trình.',
      ),
      const SizedBox(height: AppSpacing.sm),
      const AppBanner(
        kind: BannerKind.success,
        title: 'Đã chốt lịch trình',
        message: 'Lịch trình đã được lưu vào mục Lịch trình của tôi.',
      ),
      const SizedBox(height: AppSpacing.sm),
      AppBanner(
        kind: BannerKind.error,
        message: 'Không đủ địa điểm phù hợp quanh ga này.',
        action: AppButton.ghost(
          label: 'Thử ga Ba Son',
          compact: true,
          onPressed: () {},
        ),
      ),
    ],
  );
}

final _stops = [
  for (final s in stationSeed)
    MetroStop(order: s['Order']! as int, name: s['Name']! as String),
];

class _Metro extends StatefulWidget {
  const _Metro();

  @override
  State<_Metro> createState() => _MetroState();
}

class _MetroState extends State<_Metro> {
  int _from = 1;
  int? _to = 5;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MetroLineDiagram(
        stations: _stops,
        selectedOrder: _from,
        rangeEnd: _to,
        onSelect: (s) => setState(() {
          if (_to != null) {
            _from = s.order;
            _to = null;
          } else {
            _to = s.order;
          }
        }),
      ),
      const SizedBox(height: AppSpacing.md),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            StationBadge(order: 1, selected: true),
            StationBadge(order: 6),
            StationBadge(order: 14, muted: true),
            StationLabel(name: 'Ga Bến Thành', order: 1, distanceMeters: 350),
            StationLabel(name: 'Ga Nhà hát Thành phố'),
          ],
        ),
      ),
    ],
  );
}

class _Places extends StatelessWidget {
  const _Places();

  static const _samples = [
    ('Chợ Bến Thành', 'Văn hóa', PlaceCategoryTone.culture, 'Bến Thành', 1),
    ('Cà phê giữa khoảng xanh', 'Cà phê', PlaceCategoryTone.cafe, 'Nhà hát Thành phố', 2),
    ('Phố ẩm thực Ba Son', 'Ẩm thực', PlaceCategoryTone.food, 'Ba Son', 3),
    ('Landmark 81 Skyview', 'Check-in', PlaceCategoryTone.checkIn, 'Tân Cảng', 5),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _samples.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: StaggeredEntrance(
                  index: i,
                  child: PlaceCard(
                    width: AppSizes.placeCardWidth,
                    name: _samples[i].$1,
                    categoryLabel: _samples[i].$2,
                    tone: _samples[i].$3,
                    stationName: 'Ga ${_samples[i].$4}',
                    stationOrder: _samples[i].$5,
                    priceLabel: i.isEven ? 'Từ 0đ – 100.000đ' : null,
                    onTap: () {},
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      for (final s in _samples.take(2))
        PlaceListTile(
          name: s.$1,
          subtitle: '${s.$2} · Ga ${s.$4}',
          tone: s.$3,
          onTap: () {},
        ),
    ],
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TimelineStop(
        index: 1,
        isFirst: true,
        time: '09:00',
        title: 'Chợ Bến Thành',
        subtitle: 'Văn hóa · dừng 70 phút',
        tone: PlaceCategoryTone.culture,
        visited: true,
        onTap: () {},
      ),
      const TravelLeg(
        mode: TravelMode.metro,
        minutes: 6,
        boardStation: 'Ga Bến Thành',
        alightStation: 'Ga Ba Son',
        detail: '2 ga · chờ khoảng 4 phút',
        estimated: true,
      ),
      TimelineStop(
        index: 2,
        time: '10:20',
        title: 'Phố ẩm thực Ba Son',
        subtitle: 'Ẩm thực · dừng 60 phút · ~120.000đ',
        tone: PlaceCategoryTone.food,
        onTap: () {},
        actions: [
          AppButton.ghost(
            label: 'Xem địa điểm',
            compact: true,
            trailingIcon: LucideIcons.chevronRight,
            onPressed: () {},
          ),
          AppButton.ghost(
            label: 'Đổi điểm',
            compact: true,
            icon: LucideIcons.refreshCw,
            onPressed: () {},
          ),
        ],
      ),
      const TravelLeg(mode: TravelMode.walking, minutes: 9),
      TimelineStop(
        index: 3,
        isLast: true,
        time: '00:30',
        timeNote: '(hôm sau)',
        title: 'Cà phê giữa khoảng xanh',
        subtitle: 'Cà phê · dừng 45 phút',
        tone: PlaceCategoryTone.cafe,
        onTap: () {},
      ),
    ],
  );
}

class _InfoAndRating extends StatefulWidget {
  const _InfoAndRating();

  @override
  State<_InfoAndRating> createState() => _InfoAndRatingState();
}

class _InfoAndRatingState extends State<_InfoAndRating> {
  int _stars = 4;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const InfoRow(
        icon: LucideIcons.mapPin,
        label: 'Địa chỉ',
        value: 'Lê Lợi, Bến Thành, Quận 1, TP. Hồ Chí Minh',
      ),
      const InfoRow(
        icon: LucideIcons.clock,
        label: 'Giờ mở cửa hôm nay',
        value: '06:00 – 18:00',
        trailing: StatusChip(label: 'Đang mở', kind: StatusKind.finalized),
      ),
      const InfoRow(
        icon: LucideIcons.wallet,
        label: 'Chi phí ước tính mỗi người',
        value: '0đ – 100.000đ',
      ),
      const SizedBox(height: AppSpacing.md),
      const Row(
        children: [
          AppAvatar(name: 'Bảo Trần'),
          SizedBox(width: AppSpacing.md),
          AppAvatar(),
          SizedBox(width: AppSpacing.lg),
          RatingBadge(rating: 4.6, reviewCount: 128),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      RatingStars(value: _stars, onChanged: (v) => setState(() => _stars = v)),
    ],
  );
}

class _Skeletons extends StatefulWidget {
  const _Skeletons();

  @override
  State<_Skeletons> createState() => _SkeletonsState();
}

class _SkeletonsState extends State<_Skeletons> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppSkeleton(
        enabled: _loading,
        child: Row(
          children: [
            Expanded(
              child: PlaceCard(
                name: 'Tên địa điểm mẫu',
                categoryLabel: 'Văn hóa',
                tone: PlaceCategoryTone.culture,
                stationName: 'Ga Bến Thành',
                onTap: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PlaceCard(
                name: 'Tên địa điểm mẫu dài',
                categoryLabel: 'Cà phê',
                tone: PlaceCategoryTone.cafe,
                stationName: 'Ga Ba Son',
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      const SkeletonBlock(height: AppSpacing.lg, width: AppSizes.placeCardWidth),
      const SizedBox(height: AppSpacing.sm),
      AppButton.ghost(
        label: _loading ? 'Hiện dữ liệu' : 'Hiện skeleton',
        compact: true,
        onPressed: () => setState(() => _loading = !_loading),
      ),
    ],
  );
}

class _States extends StatelessWidget {
  const _States();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Framed(
        child: AppEmptyState(
          compact: true,
          illustration: IllustrationKind.noTrips,
          title: 'Chưa có lịch trình nào',
          message: 'Chọn một ga, thời gian rảnh và sở thích — LocalMate sẽ gợi ý lộ trình cho bạn.',
          actionLabel: 'Tạo lịch trình',
          actionIcon: LucideIcons.sparkles,
          onAction: () {},
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _Framed(
        child: AppErrorState(
          compact: true,
          message: 'Không tải được danh sách địa điểm. Vui lòng thử lại.',
          onRetry: () {},
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _Framed(child: AppOfflineState(compact: true, onRetry: () {})),
      const SizedBox(height: AppSpacing.md),
      const ClipRRect(borderRadius: AppRadius.control, child: OfflineBanner()),
    ],
  );
}

class _Framed extends StatelessWidget {
  const _Framed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: AppRadius.card,
      border: Border.all(color: context.colors.outline),
    ),
    child: child,
  );
}

class _Illustrations extends StatelessWidget {
  const _Illustrations();

  @override
  Widget build(BuildContext context) {
    final s = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final kind in IllustrationKind.values)
              AppIllustration(kind: kind, size: AppSpacing.xxxl * 2),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ClipRRect(
          borderRadius: AppRadius.card,
          child: Container(
            height: AppSpacing.xxxl * 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [s.primary, context.appColors.metroLine],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: MetroHeroArt(
                    color: s.onPrimary,
                    accent: context.appColors.warning,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BẾN THÀNH – SUỐI TIÊN',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: s.onPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Khám phá\nquanh ga Metro',
                        style: context.textStyles.headlineSmall?.copyWith(
                          color: s.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Sheets extends StatelessWidget {
  const _Sheets();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppButton.secondary(
        label: 'Mở bottom sheet chọn ga',
        icon: LucideIcons.trainFront,
        onPressed: () => showAppBottomSheet<void>(
          context: context,
          title: 'Chọn ga xuất phát',
          subtitle: '14 ga · Tuyến Metro số 1',
          builder: (c) => Column(
            children: [
              for (final s in _stops)
                ListTile(
                  leading: StationBadge(order: s.order),
                  title: Text(s.name),
                  onTap: () => Navigator.of(c).pop(),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppButton.secondary(
        label: 'Mở sheet xác nhận',
        icon: LucideIcons.circleCheck,
        onPressed: () => showAppConfirmSheet(
          context: context,
          title: 'Chốt lịch trình?',
          message:
              'Sau khi chốt, bạn không thể đổi điểm dừng. Lịch trình sẽ được lưu vào mục Lịch trình của tôi.',
          confirmLabel: 'Xác nhận chốt',
          confirmIcon: LucideIcons.check,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      ClipRRect(
        borderRadius: AppRadius.card,
        child: AppBottomActionBar(
          children: [
            AppButton.secondary(label: 'Đổi điểm', onPressed: () {}),
            AppButton(
              label: 'Chốt',
              icon: LucideIcons.check,
              onPressed: () {},
            ),
          ],
        ),
      ),
    ],
  );
}

class _NavPreview extends StatefulWidget {
  const _NavPreview();

  @override
  State<_NavPreview> createState() => _NavPreviewState();
}

class _NavPreviewState extends State<_NavPreview> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => AppBottomNav(
    selectedIndex: _index,
    onSelected: (i) => setState(() => _index = i),
    destinations: const [
      AppNavDestination(label: 'Trang chủ', icon: LucideIcons.house),
      AppNavDestination(label: 'Khám phá', icon: LucideIcons.compass),
      AppNavDestination(label: 'Metro', icon: LucideIcons.trainFront),
      AppNavDestination(label: 'Lịch trình', icon: LucideIcons.route),
      AppNavDestination(label: 'Tài khoản', icon: LucideIcons.user),
    ],
  );
}
