import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/core/theme/app_colors.dart';
import 'package:localmate_ai_mobile/core/theme/app_theme.dart';
import 'package:localmate_ai_mobile/core/widgets/widgets.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('both themes expose AppColors and differ in brightness', () {
    expect(AppTheme.light.extension<AppColors>(), isNotNull);
    expect(AppTheme.dark.extension<AppColors>(), isNotNull);
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(
      AppTheme.light.colorScheme.primary,
      isNot(AppTheme.dark.colorScheme.primary),
    );
  });

  testWidgets('AppButton fires, and is disabled while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(AppButton(label: 'Tạo lịch trình', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Tạo lịch trình'));
    expect(taps, 1);

    await tester.pumpWidget(
      _host(
        AppButton(label: 'Tạo lịch trình', loading: true, onPressed: () => taps++),
      ),
    );
    await tester.tap(find.text('Tạo lịch trình'), warnIfMissed: false);
    expect(taps, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppIconButton meets the 48dp target and has a tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        AppIconButton(icon: Icons.add, tooltip: 'Thêm', onPressed: () {}),
      ),
    );
    final size = tester.getSize(find.byType(IconButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(find.byTooltip('Thêm'), findsOneWidget);
  });

  testWidgets('AppSearchBar clears its text', (tester) async {
    final controller = TextEditingController(text: 'Cà phê');
    addTearDown(controller.dispose);
    var cleared = false;
    await tester.pumpWidget(
      _host(
        AppSearchBar(
          hint: 'Tìm',
          controller: controller,
          onClear: () => cleared = true,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Xóa tìm kiếm'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(cleared, isTrue);
    expect(find.byTooltip('Xóa tìm kiếm'), findsNothing);
  });

  testWidgets('AppChipGroup reports the tapped value', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _host(
        AppChipGroup<String>(
          selected: 'all',
          onSelected: (v) => picked = v,
          options: const [
            AppChipOption(value: 'all', label: 'Tất cả'),
            AppChipOption(value: 'Cafe', label: 'Cà phê'),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Cà phê'));
    expect(picked, 'Cafe');
  });

  testWidgets('MetroLineDiagram renders every station and selects', (
    tester,
  ) async {
    final stops = [
      for (var i = 1; i <= 14; i++) MetroStop(order: i, name: 'Ga $i'),
    ];
    MetroStop? selected;
    await tester.pumpWidget(
      _host(
        MetroLineDiagram(
          stations: stops,
          selectedOrder: 1,
          onSelect: (s) => selected = s,
        ),
      ),
    );
    expect(find.byType(StationBadge), findsNWidgets(14));
    expect(find.bySemanticsLabel(RegExp('^Ga 2: Ga 2')), findsOneWidget);
    await tester.tap(find.text('Ga 2'));
    expect(selected?.order, 2);
  });

  testWidgets('state views show their action', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _host(
        AppErrorState(message: 'Không tải được.', onRetry: () => retried = true),
      ),
    );
    await tester.tap(find.text('Thử lại'));
    expect(retried, isTrue);

    await tester.pumpWidget(
      _host(
        const AppEmptyState(
          title: 'Chưa có lịch trình nào',
          message: 'Hãy tạo lịch trình đầu tiên.',
          illustration: IllustrationKind.noTrips,
        ),
      ),
    );
    expect(find.text('Chưa có lịch trình nào'), findsOneWidget);
  });

  testWidgets('timeline renders in dark theme without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        theme: AppTheme.dark,
        const Column(
          children: [
            TimelineStop(
              index: 1,
              isFirst: true,
              time: '09:00',
              title: 'Chợ Bến Thành',
              subtitle: 'Văn hóa · dừng 70 phút',
              tone: PlaceCategoryTone.culture,
              visited: true,
            ),
            TravelLeg(
              mode: TravelMode.metro,
              minutes: 6,
              boardStation: 'Ga Bến Thành',
              alightStation: 'Ga Ba Son',
            ),
            TimelineStop(
              index: 2,
              isLast: true,
              time: '10:20',
              title: 'Phố ẩm thực Ba Son',
              tone: PlaceCategoryTone.food,
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      find.bySemanticsLabel(RegExp('từ Ga Bến Thành đến Ga Ba Son')),
      findsOneWidget,
    );
  });

  testWidgets('confirm sheet resolves true on confirm', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showAppConfirmSheet(
                  context: context,
                  title: 'Chốt lịch trình?',
                  message: 'Không thể đổi điểm sau khi chốt.',
                  confirmLabel: 'Xác nhận chốt',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận chốt'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
