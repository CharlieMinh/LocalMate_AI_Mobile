import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/content_states.dart';
import '../../../shared/widgets/content_container.dart';
import '../../../shared/widgets/feedback_banner.dart';
import '../../../shared/theme/app_theme.dart';
import '../application/discovery_providers.dart';
import '../domain/discovery_models.dart';
import 'discovery_widgets.dart';

class DiscoveryHomePage extends ConsumerWidget {
  const DiscoveryHomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    key: const PageStorageKey('discovery-home'),
    padding: EdgeInsets.zero,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: Brand.surface,
            child: ContentContainer(
              verticalPadding: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Xin chào, bạn đồng hành',
                    style: BrandTypography.metadata,
                  ),
                  const SizedBox(height: 5),
                  Semantics(
                    header: true,
                    child: const Text(
                      'Hôm nay mình đi đâu?',
                      style: TextStyle(
                        fontSize: 21,
                        height: 29 / 21,
                        fontWeight: FontWeight.w700,
                        color: Brand.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton.icon(
                    key: const ValueKey('home-search'),
                    onPressed: () => context.go('/explore'),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      backgroundColor: Brand.canvas,
                      foregroundColor: Brand.muted,
                      side: const BorderSide(color: Brand.line),
                    ),
                    icon: const Icon(Icons.search, size: 20),
                    label: const Text('Tìm địa điểm quanh ga Metro'),
                  ),
                ],
              ),
            ),
          ),
          const _HomeHero(),
          ContentContainer(
            verticalPadding: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OfflineNotice(),
                _DiscoveryHeading(
                  'Điểm dừng gợi ý',
                  onAll: () => context.go('/explore'),
                ),
                DiscoveryAsync(
                  value: ref.watch(clustersProvider),
                  retry: () => ref.invalidate(clustersProvider),
                  data: (clusters) {
                    final places = {
                      for (final c in clusters)
                        for (final p in c.places) p.id: p,
                    }.values;
                    return places.isEmpty
                        ? const EmptyContent(
                            title: 'Chưa có điểm dừng',
                            message: 'Chưa có dữ liệu quanh ga.',
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final place in places.take(3))
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: SizedBox(
                                      width:
                                          MediaQuery.textScalerOf(context)
                                                  .scale(14) >
                                              20
                                          ? 240
                                          : 163,
                                      child: PlaceTile(place, compact: true),
                                    ),
                                  ),
                              ],
                            ),
                          );
                  },
                ),
                const SizedBox(height: 16),
                _DiscoveryEntry(
                  key: const ValueKey('home-metro-entry'),
                  icon: Icons.train_outlined,
                  title: 'Dọc tuyến Metro số 1',
                  subtitle: 'Bến Thành – Suối Tiên',
                  onTap: () => context.go('/metro'),
                ),
                const SizedBox(height: 20),
                const SectionTitle('Lịch trình gợi ý'),
                DiscoveryAsync(
                  value: ref.watch(curatedProvider),
                  retry: () => ref.invalidate(curatedProvider),
                  data: (trips) => trips.isEmpty
                      ? const EmptyContent(
                          title: 'Chưa có lịch trình mẫu',
                          message: 'Hãy quay lại sau.',
                        )
                      : Column(children: trips.map(CuratedTile.new).toList()),
                ),
                const _PlannerEntry(),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const ValueKey('home-hero'),
    color: Brand.navy,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 250),
      child: ContentContainer(
        verticalPadding: 18,
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.train_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'BẾN THÀNH – SUỐI TIÊN',
                        style: TextStyle(
                          fontSize: 11,
                          height: 18 / 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Semantics(
                  header: true,
                  child: const Text(
                    'Khám phá quanh ga Metro',
                    style: TextStyle(
                      fontSize: 23,
                      height: 31 / 23,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Một buổi rảnh. Một hành trình theo gu của bạn.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 13),
                FilledButton.icon(
                  onPressed: () => context.push('/planner'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Brand.navy,
                  ),
                  icon: const Icon(Icons.auto_awesome_outlined, size: 20),
                  label: const Text('Tạo lịch trình mẫu'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _DiscoveryHeading extends StatelessWidget {
  const _DiscoveryHeading(this.title, {required this.onAll});
  final String title;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: BrandTypography.sectionTitle),
        ),
        TextButton.icon(
          onPressed: onAll,
          label: const Text('Xem tất cả'),
          icon: const Icon(Icons.arrow_forward, size: 16),
          iconAlignment: IconAlignment.end,
        ),
      ],
    ),
  );
}

class _DiscoveryEntry extends StatelessWidget {
  const _DiscoveryEntry({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Brand.infoSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Brand.timelineBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 78),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: Brand.navy, size: 25),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Brand.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: BrandTypography.metadata),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Brand.navy),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PlannerEntry extends StatelessWidget {
  const _PlannerEntry();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: _DiscoveryEntry(
      icon: Icons.auto_awesome_outlined,
      title: 'Dành một buổi cho chính mình',
      subtitle: 'Chọn điểm xuất phát và thời gian rảnh để xem lịch trình mẫu.',
      onTap: () => context.push('/planner'),
    ),
  );
}

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});
  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final input = TextEditingController();
  final form = GlobalKey<FormState>();
  String? submitted;
  String? category;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void search() {
    if (form.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() => submitted = SearchQuery(input.text).keyword);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('discovery-explore'),
    padding: EdgeInsets.zero,
    children: [
      ContentContainer(
        verticalPadding: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: form,
              child: TextFormField(
                controller: input,
                style: const TextStyle(fontSize: 14, color: Brand.ink),
                decoration: const InputDecoration(
                  labelText: 'Tìm địa điểm hoặc ga Metro',
                  prefixIcon: Icon(Icons.search),
                  helperText: '2–100 ký tự · tối đa 5 kết quả mỗi nhóm',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    SearchQuery(value ?? '').errors['Q']?.first,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => search(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: search,
                  icon: const Icon(Icons.search),
                  label: const Text('Tìm kiếm'),
                ),
                TextButton(
                  onPressed: () {
                    input.clear();
                    form.currentState?.reset();
                    setState(() => submitted = null);
                  },
                  child: const Text('Xóa tìm kiếm'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (submitted == null) ...[
              DiscoveryAsync(
                value: ref.watch(clustersProvider),
                retry: () => ref.invalidate(clustersProvider),
                data: (clusters) {
                  final places = {
                    for (final c in clusters)
                      for (final p in c.places) p.id: p,
                  }.values.toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _categories(places),
                      const SectionTitle('Quanh các ga trung tâm'),
                      _places(places),
                    ],
                  );
                },
              ),
            ] else
              DiscoveryAsync(
                value: ref.watch(searchProvider(submitted!)),
                retry: () => ref.invalidate(searchProvider(submitted!)),
                data: (result) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionTitle('Kết quả: ${result.query}'),
                    _categories(result.places.items),
                    const SectionTitle('Ga Metro'),
                    if (result.stations.items.isEmpty)
                      const Text('Không tìm thấy ga.'),
                    for (final s in result.stations.items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.train_outlined),
                        title: Text(s.name),
                        subtitle: Text(
                          '${s.placeCount} địa điểm trong dữ liệu mẫu',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/stations/${s.order}'),
                      ),
                    if (result.stations.hasMore)
                      const Text(
                        'Còn kết quả ga. Hãy dùng từ khóa cụ thể hơn.',
                      ),
                    const SectionTitle('Địa điểm'),
                    if (result.places.items.isEmpty)
                      const Text('Không tìm thấy địa điểm.'),
                    if (result.places.items.isNotEmpty)
                      _places(result.places.items),
                    if (result.places.hasMore)
                      const Text('Còn địa điểm. Hãy thu hẹp từ khóa.'),
                    const SectionTitle('Lịch trình mẫu'),
                    if (result.curated.items.isEmpty)
                      const Text('Không tìm thấy lịch trình mẫu.'),
                    for (final t in result.curated.items) CuratedTile(t),
                    if (result.curated.hasMore)
                      const Text('Còn lịch trình mẫu. Hãy thu hẹp từ khóa.'),
                  ],
                ),
              ),
            const _PlannerEntry(),
            const SizedBox(height: 20),
            const OfflineNotice(),
          ],
        ),
      ),
    ],
  );

  Widget _categories(List<Place> places) {
    // A local projection of loaded data, never a server search parameter.
    final categories = {
      'Culture',
      'Cafe',
      for (final p in places) p.category,
      ?category,
    };
    return SingleChildScrollView(
      key: const ValueKey('explore-categories'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in <String?>[null, ...categories])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(value == null ? 'Tất cả' : categoryLabel(value)),
                selected: category == value,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => category = value),
              ),
            ),
        ],
      ),
    );
  }

  Widget _places(List<Place> places) {
    final visible = places
        .where((p) => category == null || p.category == category)
        .toList();
    if (visible.isEmpty) {
      return Column(
        children: [
          EmptyContent(
            title: category == null
                ? 'Chưa có địa điểm'
                : 'Chưa có địa điểm trong danh mục này',
            message: category == null
                ? 'Chưa có dữ liệu quanh ga.'
                : 'Thử chọn Tất cả hoặc đổi từ khóa tìm kiếm.',
            icon: Icons.search_off_outlined,
          ),
          if (category != null)
            TextButton(
              onPressed: () => setState(() => category = null),
              child: const Text('Xem tất cả danh mục'),
            ),
        ],
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
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết địa điểm')),
      bottomNavigationBar: place.asData == null
          ? null
          : SafeArea(
              top: false,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Brand.surface,
                  border: Border(top: BorderSide(color: Brand.line)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: FilledButton.icon(
                    onPressed: () => context.push('/planner'),
                    icon: const Icon(Icons.auto_awesome_outlined, size: 20),
                    label: const Text('Tạo lịch trình mẫu'),
                  ),
                ),
              ),
            ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DiscoveryAsync(
              value: place,
              retry: () => ref.invalidate(placeProvider(id)),
              data: (p) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlaceMedia(p.imageUrl, height: 220, category: p.category),
                  ColoredBox(
                    color: Brand.surface,
                    child: ContentContainer(
                      verticalPadding: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Brand.infoSurface,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                categoryLabel(p.category),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Brand.navy,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 24,
                              height: 32 / 24,
                              fontWeight: FontWeight.w700,
                              color: Brand.ink,
                            ),
                          ),
                          if (p.stationName != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.train_outlined,
                                  size: 16,
                                  color: Brand.navy,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Ga ${p.stationName}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Brand.navy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            p.description ?? 'Chưa có mô tả.',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.75,
                              color: Brand.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ContentContainer(
                    verticalPadding: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Kết hợp trong một buổi đi chơi',
                          style: BrandTypography.sectionTitle,
                        ),
                        const SizedBox(height: 12),
                        const FeedbackBanner(
                          message: 'Chọn ga xuất phát, ngân sách và thời gian để xem lịch trình mẫu phù hợp.',
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Thông tin tham khảo',
                          style: BrandTypography.sectionTitle,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          p.address,
                          style: const TextStyle(fontSize: 12, height: 1.75),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.rating == null
                              ? 'Chưa có điểm đánh giá.'
                              : 'Đánh giá: ${p.rating}',
                        ),
                        if (p.reviewCount != null)
                          Text(
                            '${p.reviewCount} lượt đánh giá trong dữ liệu mẫu',
                          ),
                        Text(costLabel(p) ?? 'Chưa có khoảng chi phí đầy đủ.'),
                        if (p.distanceMeters != null)
                          Text(
                            'Cách ga ${p.distanceMeters!.toStringAsFixed(0)} m (dữ liệu mẫu)',
                          ),
                        const Text(
                          'Chưa xác nhận giờ mở cửa hoặc tình trạng sẵn có.',
                        ),
                        const SizedBox(height: 16),
                        MapsPreviewButton(
                          MapsUrlBuilder.directions(
                            p.latitude,
                            p.longitude,
                            placeId: p.googlePlaceId,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const OfflineNotice(),
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

class CuratedDetailPage extends ConsumerWidget {
  const CuratedDetailPage(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Lịch trình mẫu')),
    body: SafeArea(
      child: DiscoveryBody(
        children: [
          DiscoveryAsync(
            value: ref.watch(curatedProvider),
            retry: () => ref.invalidate(curatedProvider),
            data: (trips) {
              final matching = trips.where((t) => t.id == id);
              if (matching.isEmpty) {
                return const EmptyContent(
                  title: 'Lịch trình chưa khả dụng',
                  message: 'Chưa có trong danh mục mẫu.',
                );
              }
              final t = matching.first;
              final stops = [...t.items]
                ..sort((a, b) => a.order.compareTo(b.order));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.title, style: BrandTypography.screenTitle),
                  const SizedBox(height: 12),
                  Text(
                    t.description ?? 'Chưa có mô tả.',
                    style: BrandTypography.body,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text(
                        '${t.durationMinutes} phút (ước tính mẫu)',
                        style: BrandTypography.metadata,
                      ),
                      if (t.stationName != null)
                        Text(
                          'Ga ${t.stationName}',
                          style: BrandTypography.metadata,
                        ),
                    ],
                  ),
                  const SectionTitle('Các điểm dừng'),
                  for (var i = 0; i < stops.length; i++)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 26,
                            child: Column(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Brand.navy,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (i < stops.length - 1)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: Brand.timelineBorder,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Material(
                                color: Brand.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Brand.line),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => context.push(
                                    '/places/${Uri.encodeComponent(stops[i].placeId)}',
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Brand.infoSurface,
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.place_outlined,
                                            color: Brand.navy,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            stops[i].name,
                                            style: BrandTypography.choice,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 18,
                                          color: Brand.navy,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  const FeedbackBanner(
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
