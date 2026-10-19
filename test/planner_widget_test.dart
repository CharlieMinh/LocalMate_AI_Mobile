import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/features/auth/application/auth_controller.dart';
import 'package:localmate_ai_mobile/features/planner/application/planner_controller.dart';
import 'package:localmate_ai_mobile/features/planner/data/offline_planner_repository.dart';
import 'package:localmate_ai_mobile/features/planner/domain/planner_criteria.dart';
import 'package:localmate_ai_mobile/features/planner/presentation/planner_page.dart';

import 'planner_controller_test.dart' show ControlledAuth, DelayedPlanner;

class CatalogRepository extends OfflinePlannerRepository {
  CatalogRepository(this.catalog);
  final Future<List<PlannerTag>> Function() catalog;
  bool failPreview = false;
  @override
  Future<List<PlannerTag>> loadTags(CancelToken cancel) => catalog();
  @override
  Future<OfflineDraftPreview> preview(
    PlannerCriteria criteria,
    DateTime now,
    String key,
    CancelToken cancel,
  ) {
    if (failPreview) return Future.error(StateError('local fixture failure'));
    return super.preview(criteria, now, key, cancel);
  }
}

Finder field(String prefix) => find.byWidgetPredicate(
  (widget) =>
      widget is TextField &&
      (widget.decoration?.labelText?.startsWith(prefix) ?? false),
);

void main() {
  Future<ProviderContainer> boot(
    WidgetTester tester, {
    PlannerRepository? repository,
    double scale = 1,
    bool settle = true,
  }) async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(ControlledAuth.new),
        apiProvider.overrideWith(
          (_) => throw StateError('Planner attempted live transport'),
        ),
        plannerNowProvider.overrideWithValue(
          () => DateTime.utc(2026, 10, 19, 3),
        ),
        if (repository != null)
          plannerRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, _) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: const LocalMateApp(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/trips');
    await tester.pumpAndSettle();
    container.read(routerProvider).push('/planner');
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return container;
  }

  Future<void> toStep(WidgetTester tester, int target) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final caption = tester.widget<Text>(find.textContaining('BƯỚC ')).data!;
      final current =
          int.parse(RegExp(r'BƯỚC (\d)').firstMatch(caption)![1]!) - 1;
      if (current == target) return;
      FocusManager.instance.primaryFocus?.unfocus();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      if (current > target) {
        await tester.tap(find.byTooltip('Quay lại'));
      } else {
        await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
      }
      await tester.pumpAndSettle();
      final next = tester.widget<Text>(find.textContaining('BƯỚC ')).data!;
      if (next == caption) return;
    }
  }

  Future<void> submit(WidgetTester tester) async {
    await toStep(tester, 3);
    if (find
        .widgetWithText(FilledButton, 'Xem lịch trình mẫu')
        .evaluate()
        .isEmpty) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, 'Xem lịch trình mẫu');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'optional interests, per-person label, offline preview route and Android Back',
    (tester) async {
      final container = await boot(tester);
      expect(find.text('Bắt đầu từ đâu?'), findsOneWidget);
      expect(find.textContaining('CHẾ ĐỘ OFFLINE'), findsOneWidget);
      await submit(tester);
      expect(find.text('Bản xem trước tạm thời'), findsOneWidget);
      expect(container.read(plannerProvider).preview!.criteria.tagIds, isEmpty);
      expect(
        GoRouterState.of(tester.element(find.byType(PlannerPreviewPage)))
            .uri
            .path,
        startsWith('/planner/preview/offline-preview%3A'),
      );
      expect(find.textContaining('0 VND / người'), findsOneWidget);
      expect(find.textContaining('Không có Trip ID'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Đi theo phong cách của bạn'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }
      expect(find.text('Hành trình của bạn'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Hôm nay mình đi đâu?'), findsOneWidget);
    },
  );
  testWidgets(
    'invalid date and budget stay in form; explicit time not replaced',
    (tester) async {
      await boot(tester);
      await toStep(tester, 1);
      await tester.ensureVisible(field('Ngày đi'));
      await tester.enterText(field('Ngày đi'), '2026-02-30');
      await tester.ensureVisible(field('Ngân sách tối đa'));
      await tester.enterText(field('Ngân sách tối đa'), '-1');
      await submit(tester);
      await tester.ensureVisible(field('Ngày đi'));
      expect(find.textContaining('Ngày đi từ hôm nay'), findsOneWidget);
      expect(find.text('Ngân sách không được âm.'), findsOneWidget);
      expect(find.text('Bản xem trước tạm thời'), findsNothing);
    },
  );
  testWidgets(
    'optional preference toggle and normalized note sent only to local preview',
    (tester) async {
      final container = await boot(tester);
      await toStep(tester, 2);
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Văn hóa'));
      await tester.tap(find.widgetWithText(FilterChip, 'Văn hóa'));
      await toStep(tester, 3);
      await tester.ensureVisible(field('Ghi chú'));
      await tester.enterText(field('Ghi chú'), '  yêu  văn hóa  ');
      await submit(tester);
      final preview = container.read(plannerProvider).preview!;
      expect(preview.criteria.tagIds, ['a1000000-0000-4000-8000-000000000001']);
      expect(find.text('Ghi chú của bạn: yêu văn hóa'), findsOneWidget);
    },
  );
  testWidgets('overnight time and entered per-person budget preserved', (
    tester,
  ) async {
    await boot(tester);
    await toStep(tester, 1);
    await tester.ensureVisible(field('Ngày đi'));
    await tester.enterText(field('Ngày đi'), '2026-10-20');
    await tester.enterText(field('Giờ bắt đầu'), '23:30');
    await tester.ensureVisible(field('Ngân sách tối đa'));
    await tester.enterText(field('Ngân sách tối đa'), '250000');
    await submit(tester);
    expect(find.textContaining('23:30 → 03:30 (ngày hôm sau)'), findsOneWidget);
    expect(find.text('01:30 (ngày hôm sau) · mốc minh họa'), findsOneWidget);
    expect(find.textContaining('250000 VND / người'), findsOneWidget);
  });
  testWidgets(
    'catalog loading, failure, manual retry and empty catalog distinguished',
    (tester) async {
      final completer = Completer<List<PlannerTag>>();
      var attempts = 0;
      final repo = CatalogRepository(() {
        attempts++;
        return attempts == 1 ? completer.future : Future.value([]);
      });
      final container = await boot(tester, repository: repo, settle: false);
      expect(container.read(plannerTagsProvider).isLoading, isTrue);
      completer.completeError(StateError('catalog unavailable'));
      await tester.pumpAndSettle();
      await toStep(tester, 2);
      await tester.ensureVisible(find.text('Không tải được danh mục mẫu.'));
      await tester.tap(find.widgetWithText(FilledButton, 'Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có sở thích mẫu'), findsOneWidget);
      expect(attempts, 2);
      await submit(tester);
      expect(find.text('Bản xem trước tạm thời'), findsOneWidget);
    },
  );
  testWidgets('preview error retry retains form, no automatic request retry', (
    tester,
  ) async {
    final repo = CatalogRepository(() async => [])..failPreview = true;
    await boot(tester, repository: repo);
    await submit(tester);
    expect(find.textContaining('Không thể tạo bản mẫu cục bộ'), findsOneWidget);
    repo.failPreview = false;
    await tester.ensureVisible(find.text('Thử lại'));
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bản xem trước tạm thời'), findsOneWidget);
  });
  testWidgets('auth transition immediately hides old preview and form values', (
    tester,
  ) async {
    final container = await boot(tester);
    await submit(tester);
    (container.read(authProvider.notifier) as ControlledAuth).transition();
    await tester.pumpAndSettle();
    expect(find.text('Bản mẫu không còn khả dụng'), findsOneWidget);
    expect(find.text('Bản xem trước tạm thời'), findsNothing);
  });
  testWidgets('background invalidates preview; foreground never replays', (
    tester,
  ) async {
    final container = await boot(tester);
    await submit(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(container.read(plannerProvider).preview, isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(container.read(plannerProvider).phase, PlannerPhase.idle);
    expect(find.text('Bản mẫu không còn khả dụng'), findsOneWidget);
  });
  testWidgets('unknown preview key cannot access a different preview', (
    tester,
  ) async {
    final container = await boot(tester);
    await submit(tester);
    container.read(routerProvider).go('/planner/preview/not-current');
    await tester.pumpAndSettle();
    expect(find.text('Bản mẫu không còn khả dụng'), findsOneWidget);
  });
  testWidgets(
    'double tap disables action; route disposal ignores late failure',
    (tester) async {
      final repo = DelayedPlanner();
      final container = await boot(tester, repository: repo);
      await toStep(tester, 3);
      final button = find.widgetWithText(FilledButton, 'Xem lịch trình mẫu');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      expect(repo.calls, 1);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Đang tạo bản mẫu…'),
            )
            .onPressed,
        isNull,
      );
      container.read(routerProvider).go('/home');
      await tester.pumpAndSettle();
      repo.pending.single.completeError(
        StateError('late after route disposed'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hôm nay mình đi đâu?'), findsOneWidget);
      expect(find.text('Bản xem trước tạm thời'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'wizard keeps one active step, pinned action and date across Back',
    (tester) async {
      await boot(tester);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('BƯỚC 1/4 · VỊ TRÍ'), findsOneWidget);
      expect(field('Ngày đi'), findsNothing);
      await toStep(tester, 1);
      await tester.enterText(field('Ngày đi'), '2026-10-20');
      FocusManager.instance.primaryFocus?.unfocus();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      final action = find.widgetWithText(FilledButton, 'Tiếp tục');
      final before = tester.getCenter(action);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      expect(tester.getCenter(action), before);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('BƯỚC 1/4 · VỊ TRÍ'), findsOneWidget);
      await toStep(tester, 1);
      expect(
        tester.widget<TextField>(field('Ngày đi')).controller!.text,
        '2026-10-20',
      );
    },
  );
  testWidgets('rapid double tap cannot skip a wizard step', (tester) async {
    await boot(tester);
    final action = find.widgetWithText(FilledButton, 'Tiếp tục');
    await tester.tap(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('BƯỚC 2/4 · THỜI GIAN'), findsOneWidget);
    expect(find.text('Hôm nay bạn thích gì?'), findsNothing);
  });
  testWidgets('native date confirm and time cancel preserve explicit values', (
    tester,
  ) async {
    await boot(tester);
    await toStep(tester, 1);
    await tester.enterText(field('Ngày đi'), '2026-10-20');
    FocusManager.instance.primaryFocus?.unfocus();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Chọn ngày'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Chọn'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field('Ngày đi')).controller!.text,
      '2026-10-20',
    );
    await tester.enterText(field('Giờ bắt đầu'), '23:30');
    FocusManager.instance.primaryFocus?.unfocus();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Chọn giờ'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field('Giờ bắt đầu')).controller!.text,
      '23:30',
    );
  });
  testWidgets(
    'Home prototype CTA opens public offline wizard without authentication',
    (tester) async {
      final container = await boot(tester);
      container.read(routerProvider).go('/home');
      await tester.pumpAndSettle();
      final action = find.widgetWithText(FilledButton, 'Tạo lịch trình mẫu');
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('Bắt đầu từ đâu?'), findsOneWidget);
      expect(container.read(authProvider).authenticated, isFalse);
      expect(find.text('BƯỚC 1/4 · VỊ TRÍ'), findsOneWidget);
    },
  );
  testWidgets(
    'preset hours update full duration field without restricting 1 to 24',
    (tester) async {
      final container = await boot(tester);
      await toStep(tester, 1);
      final preset = find.widgetWithText(ChoiceChip, '8 giờ');
      await tester.ensureVisible(preset);
      await tester.pumpAndSettle();
      await tester.tap(preset);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<int>>(
              find.byType(DropdownButtonFormField<int>),
            )
            .initialValue,
        8,
      );
      await submit(tester);
      expect(
        container.read(plannerProvider).preview!.criteria.durationHours,
        8,
      );
      expect(find.text('Lịch trình theo giờ'), findsOneWidget);
    },
  );
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('planner and preview width=$width text=$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await boot(tester, scale: scale);
        await toStep(tester, 1);
        expect(
          MediaQuery.textScalerOf(tester.element(field('Ngày đi'))).scale(10),
          10 * scale,
        );
        expect(tester.takeException(), isNull);
        await toStep(tester, 3);
        await tester.ensureVisible(field('Ghi chú'));
        expect(tester.takeException(), isNull);
        await submit(tester);
        await tester.ensureVisible(find.textContaining('Không có Trip ID'));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
