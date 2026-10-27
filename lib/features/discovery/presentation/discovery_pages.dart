import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/ui_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/discovery_providers.dart';
import '../domain/discovery_models.dart';
import 'discovery_widgets.dart';

/// Centers content and caps its width on tablets.
class _Constrained extends StatelessWidget {
  const _Constrained({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: child,
      ),
    ),
  );
}

class DiscoveryHomePage extends ConsumerWidget {
  const DiscoveryHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => CustomScrollView(
    key: const PageStorageKey('discovery-home'),
    slivers: [
      SliverAppBar(
        pinned: true,
        titleSpacing: AppSpacing.gutter,
        title: const BrandLockup(),
        actions: [
          AppIconButton(
            key: const ValueKey('brand-account-action'),
            icon: LucideIcons.user,
            tooltip: 'Mở tài khoản',
            variant: AppIconButtonVariant.tonal,
            onPressed: () => context.go('/account'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      const SliverToBoxAdapter(child: _Greeting()),
      const SliverToBoxAdapter(child: _HomeHero()),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'Điểm dừng gợi ý',
                subtitle: 'Quanh các ga trung tâm',
                actionLabel: 'Xem tất cả',
                onAction: () => context.go('/explore'),
              ),
              const SizedBox(height: AppSpacing.md),
              DiscoveryAsync(
                value: ref.watch(clustersProvider),
                retry: () => ref.invalidate(clustersProvider),
                compact: true,
                loading: (_) => const PlaceCardsSkeleton(horizontal: true),
                data: (clusters) {
                  final entries = flattenClusters(clusters);
                  if (entries.isEmpty) {
                    return const AppEmptyState(
                      compact: true,
                      title: 'Chưa có điểm dừng',
                      message: 'Chưa có dữ liệu địa điểm quanh ga.',
                    );
                  }
                  return _PlaceCarousel(entries.take(6).toList());
                },
              ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: AppSpacing.xl),
          child: _Constrained(child: _MetroEntry()),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: 'Lịch trình gợi ý',
                subtitle: 'Gợi ý sẵn, xem nhanh từng điểm dừng',
              ),
              const SizedBox(height: AppSpacing.md),
              _Constrained(
                child: DiscoveryAsync(
                  value: ref.watch(curatedProvider),
                  retry: () => ref.invalidate(curatedProvider),
                  compact: true,
                  data: (trips) => trips.isEmpty
                      ? const AppEmptyState(
                          compact: true,
                          illustration: IllustrationKind.noTrips,
                          title: 'Chưa có lịch trình mẫu',
                          message: 'Hãy quay lại sau nhé.',
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < trips.length; i++)
                              StaggeredEntrance(
                                index: i,
                                child: CuratedTile(trips[i]),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
          child: _Constrained(child: PlannerPromoCard()),
        ),
      ),
    ],
  );
}

class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.textStyles;
    return _Constrained(
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  'Xin chào, bạn đồng hành',
                  style: text.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                if (ref.watch(mockDataProvider))
                  const StatusChip(
                    label: 'Dữ liệu minh họa',
                    icon: LucideIcons.flaskConical,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              header: true,
              child: Text('Hôm nay mình đi đâu?', style: text.headlineSmall),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSearchBar(
              fieldKey: const ValueKey('home-search'),
              hint: 'Tìm địa điểm quanh ga Metro',
              onTap: () => context.go('/explore'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHero extends ConsumerWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = context.appColors;
    final text = context.textStyles;
    final onHero = app.onHero;
    return _Constrained(
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Container(
          key: const ValueKey('home-hero'),
          constraints: const BoxConstraints(minHeight: AppSizes.heroHeight),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [app.heroStart, app.heroEnd],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: MetroHeroArt(color: onHero, accent: app.warning),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.trainFront,
                          size: AppSizes.iconSm,
                          color: onHero,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            'BẾN THÀNH – SUỐI TIÊN',
                            style: text.labelSmall?.copyWith(color: onHero),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FractionallySizedBox(
                      widthFactor: .7,
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Khám phá quanh ga Metro',
                          style: text.headlineSmall?.copyWith(color: onHero),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FractionallySizedBox(
                      widthFactor: .7,
                      child: Text(
                        'Một buổi rảnh. Một hành trình theo gu của bạn.',
                        style: text.bodySmall?.copyWith(color: onHero),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () {
                        AppHaptics.light();
                        context.push('/planner');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: onHero,
                        foregroundColor: app.heroStart,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.sparkles, size: AppSizes.icon),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              ref.watch(mockDataProvider)
                                  ? 'Tạo lịch trình mẫu'
                                  : 'Tạo lịch trình',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceCarousel extends StatelessWidget {
  const _PlaceCarousel(this.entries);
  final List<PlaceEntry> entries;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    const maxShare = .8;
    final width = math.min(
      MediaQuery.textScalerOf(context).scale(AppSizes.placeCardWidth),
      screen * maxShare,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            StaggeredEntrance(
              index: i,
              child: DiscoveryPlaceCard(entries[i], width: width),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetroEntry extends StatelessWidget {
  const _MetroEntry();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final app = context.appColors;
    final text = context.textStyles;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: scheme.outline),
      ),
      child: Pressable(
        key: const ValueKey('home-metro-entry'),
        onTap: () => context.go('/metro'),
        semanticLabel: 'Dọc tuyến Metro số 1, Bến Thành đến Suối Tiên, 14 ga',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: AppSizes.avatar,
                      height: AppSizes.avatar,
                      decoration: BoxDecoration(
                        color: app.metroLineContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.trainFront, color: app.metroLine),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dọc tuyến Metro số 1', style: text.titleSmall),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Bến Thành – Suối Tiên · 14 ga',
                            style: text.bodySmall,
                          ),
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
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: AppSpacing.md,
                  child: CustomPaint(
                    painter: _MiniRailPainter(
                      line: app.metroLine,
                      fill: scheme.surface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bến Thành', style: text.labelSmall),
                    Text('Suối Tiên', style: text.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 14 stations along a single rail, as a compact line glyph.
class _MiniRailPainter extends CustomPainter {
  const _MiniRailPainter({required this.line, required this.fill});
  final Color line;
  final Color fill;
  static const _stations = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final r = size.height / 3;
    final rail = Paint()
      ..color = line
      ..strokeWidth = AppSizes.railWidth;
    canvas.drawLine(Offset(r, y), Offset(size.width - r, y), rail);
    final step = (size.width - 2 * r) / (_stations - 1);
    for (var i = 0; i < _stations; i++) {
      final c = Offset(r + i * step, y);
      final terminal = i == 0 || i == _stations - 1;
      canvas.drawCircle(
        c,
        terminal ? r : r * .7,
        Paint()..color = terminal ? line : fill,
      );
      canvas.drawCircle(
        c,
        terminal ? r : r * .7,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppSizes.focusRing,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniRailPainter old) =>
      old.line != line || old.fill != fill;
}

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});
  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final input = TextEditingController();
  String? submitted;
  String? category;
  String? inputError;

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void search() {
    final query = SearchQuery(input.text);
    final error = query.errors['Q']?.first;
    setState(() => inputError = error);
    if (error != null) return;
    FocusScope.of(context).unfocus();
    setState(() => submitted = query.keyword);
  }

  void clear() => setState(() {
    submitted = null;
    inputError = null;
  });

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return CustomScrollView(
      key: const PageStorageKey('discovery-explore'),
      slivers: [
        AppLargeTitleBar(
          title: 'Khám phá',
          showBack: false,
          actions: [
            AppIconButton(
              icon: LucideIcons.sparkles,
              tooltip: ref.watch(mockDataProvider)
                  ? 'Tạo lịch trình mẫu'
                  : 'Tạo lịch trình',
              variant: AppIconButtonVariant.tonal,
              onPressed: () => context.push('/planner'),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: _Constrained(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OfflineNotice(),
                AppSearchBar(
                  fieldKey: const ValueKey('explore-search'),
                  hint: 'Tìm địa điểm hoặc ga Metro',
                  controller: input,
                  onSubmitted: (_) => search(),
                  onClear: clear,
                ),
                if (inputError != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      left: AppSpacing.lg,
                    ),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        inputError!,
                        style: text.bodySmall?.copyWith(
                          color: context.colors.error,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: submitted == null ? _browse() : _results(submitted!),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: AppSpacing.xl,
              bottom: AppSpacing.xxl,
            ),
            child: _Constrained(child: PlannerPromoCard()),
          ),
        ),
      ],
    );
  }

  Widget _browse() => DiscoveryAsync(
    value: ref.watch(clustersProvider),
    retry: () => ref.invalidate(clustersProvider),
    loading: (_) => const _Constrained(child: PlaceCardsSkeleton()),
    data: (clusters) {
      final entries = flattenClusters(clusters);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _categories(entries),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(
            title: 'Quanh các ga trung tâm',
            subtitle: '${_visible(entries).length} địa điểm',
          ),
          const SizedBox(height: AppSpacing.md),
          _Constrained(child: _places(entries)),
        ],
      );
    },
  );

  Widget _results(String query) => DiscoveryAsync(
    value: ref.watch(searchProvider(query)),
    retry: () => ref.invalidate(searchProvider(query)),
    loading: (_) => const _Constrained(child: PlaceCardsSkeleton()),
    data: (result) {
      final places = placeEntries(result.places.items);
      final text = context.textStyles;
      Widget note(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(message, style: text.bodySmall),
      );
      Widget group(String title, int count) => Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.xl,
          bottom: AppSpacing.sm,
        ),
        child: SectionHeader(
          title: title,
          subtitle: count == 0 ? null : '$count kết quả',
          padding: EdgeInsets.zero,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _categories(places),
          _Constrained(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    'Kết quả: ${result.query}',
                    style: text.titleLarge,
                  ),
                ),
                group('Ga Metro', result.stations.items.length),
                if (result.stations.items.isEmpty) note('Không tìm thấy ga.'),
                for (final s in result.stations.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: StationBadge(order: s.order),
                    title: Text(s.name),
                    subtitle: Text('${s.placeCount} địa điểm quanh ga'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () => context.push('/stations/${s.order}'),
                  ),
                if (result.stations.hasMore)
                  note('Còn kết quả ga. Hãy dùng từ khóa cụ thể hơn.'),
                group('Địa điểm', result.places.items.length),
                if (result.places.items.isEmpty)
                  note('Không tìm thấy địa điểm.')
                else
                  _places(places),
                if (result.places.hasMore)
                  note('Còn địa điểm. Hãy thu hẹp từ khóa.'),
                group('Lịch trình mẫu', result.curated.items.length),
                if (result.curated.items.isEmpty)
                  note('Không tìm thấy lịch trình mẫu.'),
                for (final t in result.curated.items) CuratedTile(t),
                if (result.curated.hasMore)
                  note('Còn lịch trình mẫu. Hãy thu hẹp từ khóa.'),
              ],
            ),
          ),
        ],
      );
    },
  );

  List<PlaceEntry> _visible(List<PlaceEntry> entries) => entries
      .where((e) => category == null || e.place.category == category)
      .toList();

  Widget _categories(List<PlaceEntry> entries) {
    // A local projection of loaded data, never a server search parameter.
    final categories = {
      ...placeCategories,
      for (final e in entries) e.place.category,
      ?category,
    };
    return AppChipGroup<String?>(
      key: const ValueKey('explore-categories'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      selected: category,
      onSelected: (value) => setState(() => category = value),
      options: [
        const AppChipOption(value: null, label: 'Tất cả'),
        for (final value in categories)
          AppChipOption(
            value: value,
            label: categoryLabel(value),
            icon: categoryIcon(placeTone(value)),
          ),
      ],
    );
  }

  Widget _places(List<PlaceEntry> entries) {
    final visible = _visible(entries);
    if (visible.isEmpty) {
      return AppEmptyState(
        compact: true,
        title: category == null
            ? 'Chưa có địa điểm'
            : 'Chưa có địa điểm trong danh mục này',
        message: category == null
            ? 'Chưa có dữ liệu quanh ga.'
            : 'Thử chọn Tất cả hoặc đổi từ khóa tìm kiếm.',
        actionLabel: category == null ? null : 'Xem tất cả danh mục',
        onAction: () => setState(() => category = null),
      );
    }
    return PlaceGrid(visible);
  }
}

class PlaceDetailPage extends ConsumerWidget {
  const PlaceDetailPage(this.id, {super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(placeProvider(id));
    return place.when(
      skipLoadingOnRefresh: false,
      data: (p) => _PlaceDetailView(p),
      loading: () => const _PlaceDetailSkeleton(),
      error: (error, _) => Scaffold(
        appBar: const AppTopBar(title: 'Chi tiết địa điểm'),
        body: SafeArea(
          child: SingleChildScrollView(
            child: DiscoveryAsync<Place>(
              value: place,
              retry: () => ref.invalidate(placeProvider(id)),
              data: (_) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceDetailView extends ConsumerStatefulWidget {
  const _PlaceDetailView(this.place);
  final Place place;

  @override
  ConsumerState<_PlaceDetailView> createState() => _PlaceDetailViewState();
}

class _PlaceDetailViewState extends ConsumerState<_PlaceDetailView> {
  final _scroll = ScrollController();
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final threshold =
        AppSizes.detailHeaderHeight -
        AppSizes.appBarHeight -
        MediaQuery.paddingOf(context).top;
    final collapsed = _scroll.offset > threshold;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    final text = context.textStyles;
    final scheme = context.colors;
    final tone = placeTone(p.category);
    return Scaffold(
      bottomNavigationBar: AppBottomActionBar(
        children: [
          AppButton(
            label: p.stationOrder != null
                ? 'Tạo lịch trình quanh ga này'
                : ref.watch(mockDataProvider)
                ? 'Tạo lịch trình mẫu'
                : 'Tạo lịch trình',
            icon: LucideIcons.sparkles,
            haptic: true,
            buttonKey: const ValueKey('place-plan-here'),
            // The planner starts from this place's station.
            onPressed: () => context.push(
              p.stationOrder == null
                  ? '/planner'
                  : '/planner?station=${p.stationOrder}',
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: AppSizes.detailHeaderHeight,
            automaticallyImplyLeading: false,
            backgroundColor: scheme.surface,
            leading: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: AppIconButton(
                icon: LucideIcons.arrowLeft,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                variant: AppIconButtonVariant.surface,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            title: AnimatedSwitcher(
              duration: AppDurations.fast,
              child: _collapsed
                  ? Text(
                      p.name,
                      key: const ValueKey('collapsed-title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox.shrink(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: PlaceImage(
                tone: tone,
                imageUrl: ref.watch(remoteImagesProvider) ? p.imageUrl : null,
                heroTag: placeHeroTag(p.id),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Constrained(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.xl,
                  bottom: AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        StatusChip(
                          label: categoryLabel(p.category),
                          icon: categoryIcon(tone),
                          kind: StatusKind.info,
                        ),
                        if (ref.watch(mockDataProvider))
                          const StatusChip(
                            label: 'Dữ liệu minh họa',
                            icon: LucideIcons.flaskConical,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      header: true,
                      child: Text(p.name, style: text.headlineSmall),
                    ),
                    if (p.stationName != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      StationLabel(
                        name: 'Ga ${p.stationName}',
                        order: p.stationOrder,
                        distanceMeters: p.distanceMeters,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    p.rating == null
                        ? Text('Chưa có điểm đánh giá.', style: text.bodySmall)
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: RatingBadge(
                              rating: p.rating!,
                              reviewCount: p.reviewCount,
                            ),
                          ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      p.description ?? 'Chưa có mô tả.',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(
                      title: 'Thông tin tham khảo',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    InfoRow(
                      icon: LucideIcons.mapPin,
                      label: 'Địa chỉ',
                      value: p.address,
                    ),
                    InfoRow(
                      icon: LucideIcons.wallet,
                      label: 'Chi phí ước tính mỗi người',
                      value: costLabel(p) ?? 'Chưa có khoảng chi phí đầy đủ.',
                    ),
                    if (p.distanceMeters != null)
                      InfoRow(
                        icon: LucideIcons.footprints,
                        label: 'Khoảng cách tới ga',
                        value: '${distanceLabel(p.distanceMeters!)} (ước tính)',
                      ),
                    InfoRow(
                      icon: LucideIcons.clock,
                      label: 'Giờ mở cửa',
                      value: openingHoursLabel(p.openingHours),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MapsPreviewButton(
                      MapsUrlBuilder.directions(
                        p.latitude,
                        p.longitude,
                        placeId: p.googlePlaceId,
                      ),
                      expand: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceDetailSkeleton extends StatelessWidget {
  const _PlaceDetailSkeleton();

  @override
  Widget build(BuildContext context) => const Scaffold(
    appBar: AppTopBar(title: 'Chi tiết địa điểm'),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBlock(height: AppSizes.heroHeight, radius: 0),
            Padding(
              padding: EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(
                    width: AppSpacing.xxxl * 2,
                    height: AppSpacing.xl,
                  ),
                  SizedBox(height: AppSpacing.md),
                  SkeletonBlock(height: AppSpacing.xxl),
                  SizedBox(height: AppSpacing.md),
                  SkeletonBlock(
                    width: AppSizes.placeCardWidth,
                    height: AppSpacing.lg,
                  ),
                  SizedBox(height: AppSpacing.xl),
                  SkeletonBlock(height: AppSizes.thumb),
                  SizedBox(height: AppSpacing.md),
                  SkeletonBlock(height: AppSizes.thumb),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CuratedDetailPage extends ConsumerWidget {
  const CuratedDetailPage(this.id, {super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: const AppTopBar(title: 'Lịch trình mẫu'),
    body: SafeArea(
      child: DiscoveryBody(
        children: [
          DiscoveryAsync(
            value: ref.watch(curatedProvider),
            retry: () => ref.invalidate(curatedProvider),
            data: (trips) {
              final matching = trips.where((t) => t.id == id);
              if (matching.isEmpty) {
                return const AppEmptyState(
                  title: 'Lịch trình chưa khả dụng',
                  message: 'Chưa có trong danh mục mẫu.',
                );
              }
              final t = matching.first;
              final stops = [...t.items]
                ..sort((a, b) => a.order.compareTo(b.order));
              final text = context.textStyles;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(t.title, style: text.headlineSmall),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      StatusChip(
                        label: '${durationLabel(t.durationMinutes)} (ước tính)',
                        icon: LucideIcons.clock,
                        kind: StatusKind.info,
                      ),
                      if (t.stationName != null)
                        StatusChip(
                          label: 'Ga ${t.stationName}',
                          icon: LucideIcons.trainFront,
                          kind: StatusKind.info,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    t.description ?? 'Chưa có mô tả.',
                    style: text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SectionTitle('Các điểm dừng'),
                  for (var i = 0; i < stops.length; i++)
                    StaggeredEntrance(
                      index: i,
                      child: TimelineStop(
                        index: i + 1,
                        isFirst: i == 0,
                        isLast: i == stops.length - 1,
                        title: stops[i].name,
                        tone: PlaceCategoryTone.other,
                        onTap: () => context.push(
                          '/places/${Uri.encodeComponent(stops[i].placeId)}',
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppBanner(
                    message: 'Chỉ xem. Chưa áp dụng, tạo hoặc lưu lịch trình.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// "T2: 07:00–22:00" per line; days with no time are marked as unknown.
String openingHoursLabel(List<OpeningDay>? week) {
  if (week == null) return 'Chưa xác nhận giờ mở cửa hoặc tình trạng sẵn có.';
  String hhmm(String? t) => t != null && t.length >= 5 ? t.substring(0, 5) : '';
  const names = ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  return [
    for (final d in week)
      '${names[d.weekday]}: ${d.closed
          ? 'Đóng cửa'
          : d.open == null || d.close == null
          ? 'Chưa rõ giờ'
          : '${hhmm(d.open)}–${hhmm(d.close)}'}',
  ].join('\n');
}
