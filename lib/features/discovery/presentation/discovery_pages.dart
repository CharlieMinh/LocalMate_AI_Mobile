import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/content_states.dart';
import '../../../shared/theme/app_theme.dart';
import '../application/discovery_providers.dart';
import '../domain/discovery_models.dart';
import 'discovery_widgets.dart';

class DiscoveryHomePage extends ConsumerWidget {
  const DiscoveryHomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => DiscoveryBody(
    children: [
      Semantics(
        header: true,
        child: Text(
          'Hôm nay mình đi đâu?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: () => context.go('/explore'),
        icon: const Icon(Icons.search),
        label: const Text('Tìm địa điểm quanh ga Metro'),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(20),
        color: Brand.navy,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.tram_outlined, color: Brand.amber, size: 36),
            const SizedBox(height: 16),
            const Text(
              'BẾN THÀNH – SUỐI TIÊN',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Khám phá quanh ga Metro',
              style: TextStyle(
                fontSize: 24,
                height: 1.3,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Một buổi rảnh. Một hành trình theo gu của bạn.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.push('/planner'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Brand.navy,
              ),
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Tạo lịch trình mẫu'),
            ),
          ],
        ),
      ),
      const SectionTitle('Điểm dừng gợi ý'),
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
                                MediaQuery.textScalerOf(context).scale(14) > 20
                                ? 240
                                : 164,
                            child: PlaceTile(place, compact: true),
                          ),
                        ),
                    ],
                  ),
                );
        },
      ),
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
      OutlinedButton.icon(
        onPressed: () => context.go('/metro'),
        icon: const Icon(Icons.train_outlined),
        label: const Text('Mở Metro'),
      ),
    ],
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
  Widget build(BuildContext context) => DiscoveryBody(
    children: [
      Text(
        'Những điểm dừng mới',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      Form(
        key: form,
        child: TextFormField(
          controller: input,
          decoration: const InputDecoration(
            labelText: 'Tìm địa điểm hoặc ga Metro',
            prefixIcon: Icon(Icons.search),
            helperText: '2–100 ký tự · tối đa 5 kết quả mỗi nhóm',
            border: OutlineInputBorder(),
          ),
          validator: (value) => SearchQuery(value ?? '').errors['Q']?.first,
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
      if (submitted == null) ...[
        const SectionTitle('Quanh các ga trung tâm'),
        DiscoveryAsync(
          value: ref.watch(clustersProvider),
          retry: () => ref.invalidate(clustersProvider),
          data: (clusters) => clusters.isEmpty
              ? const EmptyContent(
                  title: 'Chưa có địa điểm',
                  message: 'Chưa có dữ liệu quanh ga.',
                )
              : Column(
                  children: [
                    for (final c in clusters)
                      for (final p in c.places) PlaceTile(p),
                  ],
                ),
        ),
      ] else
        DiscoveryAsync(
          value: ref.watch(searchProvider(submitted!)),
          retry: () => ref.invalidate(searchProvider(submitted!)),
          data: (result) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle('Kết quả: ${result.query}'),
              const SectionTitle('Ga Metro'),
              if (result.stations.items.isEmpty)
                const Text('Không tìm thấy ga.'),
              for (final s in result.stations.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.train_outlined),
                  title: Text(s.name),
                  subtitle: Text('${s.placeCount} địa điểm trong dữ liệu mẫu'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/stations/${s.order}'),
                ),
              if (result.stations.hasMore)
                const Text('Còn kết quả ga. Hãy dùng từ khóa cụ thể hơn.'),
              const SectionTitle('Địa điểm'),
              if (result.places.items.isEmpty)
                const Text('Không tìm thấy địa điểm.'),
              for (final p in result.places.items) PlaceTile(p),
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
    ],
  );
}

class PlaceDetailPage extends ConsumerWidget {
  const PlaceDetailPage(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết địa điểm')),
    body: SafeArea(
      child: DiscoveryBody(
        children: [
          DiscoveryAsync(
            value: ref.watch(placeProvider(id)),
            retry: () => ref.invalidate(placeProvider(id)),
            data: (p) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlaceMedia(p.imageUrl, height: 220, category: p.category),
                const SizedBox(height: 20),
                Text(categoryLabel(p.category)),
                Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(p.address),
                if (p.stationName != null) Text('Gần ga ${p.stationName}'),
                const SectionTitle('Về địa điểm'),
                Text(p.description ?? 'Chưa có mô tả.'),
                const SizedBox(height: 12),
                Text(
                  p.rating == null
                      ? 'Chưa có điểm đánh giá.'
                      : 'Đánh giá: ${p.rating}',
                ),
                if (p.reviewCount != null)
                  Text('${p.reviewCount} lượt đánh giá trong dữ liệu mẫu'),
                Text(costLabel(p) ?? 'Chưa có khoảng chi phí đầy đủ.'),
                if (p.distanceMeters != null)
                  Text(
                    'Cách ga ${p.distanceMeters!.toStringAsFixed(0)} m (dữ liệu mẫu)',
                  ),
                const Text('Chưa xác nhận giờ mở cửa hoặc tình trạng sẵn có.'),
                const SizedBox(height: 16),
                MapsPreviewButton(
                  MapsUrlBuilder.directions(
                    p.latitude,
                    p.longitude,
                    placeId: p.googlePlaceId,
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
                  Text(
                    t.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(t.description ?? 'Chưa có mô tả.'),
                  Text('${t.durationMinutes} phút (ước tính mẫu)'),
                  if (t.stationName != null) Text('Ga ${t.stationName}'),
                  const SectionTitle('Các điểm dừng'),
                  for (var i = 0; i < stops.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text('${i + 1}'),
                      title: Text(stops[i].name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        '/places/${Uri.encodeComponent(stops[i].placeId)}',
                      ),
                    ),
                  const Text('Chỉ xem. Chưa áp dụng, tạo hoặc lưu lịch trình.'),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
