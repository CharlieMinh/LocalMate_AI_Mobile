import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/shared/theme/app_theme.dart';
import 'package:localmate_ai_mobile/shared/widgets/content_container.dart';
import 'package:localmate_ai_mobile/shared/widgets/feedback_banner.dart';

void main() {
  for (final kind in FeedbackBannerKind.values) {
    testWidgets(
      '$kind action inherits transparent Material and semantic foreground',
      (tester) async {
        final (surface, foreground) = switch (kind) {
          FeedbackBannerKind.info => (Brand.infoSurface, Brand.navy),
          FeedbackBannerKind.warning => (
            Brand.warningSurface,
            Brand.warningText,
          ),
          FeedbackBannerKind.success => (
            Brand.successSurface,
            Brand.successText,
          ),
          FeedbackBannerKind.error => (Brand.errorSurface, Brand.errorText),
        };
        var calls = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: Brand.theme,
            home: Scaffold(
              body: FeedbackBanner(
                kind: kind,
                message: 'Dữ liệu mẫu',
                actionLabel: 'Thử lại',
                onAction: () => calls++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final button = find.byType(TextButton);
        final material = tester.widget<Material>(
          find.descendant(of: button, matching: find.byType(Material)).first,
        );
        final decoration =
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(FeedbackBanner),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(decoration.color, surface);
        expect(material.color, Colors.transparent);
        expect(Color.alphaBlend(material.color!, surface), surface);
        expect(
          DefaultTextStyle.of(tester.element(find.text('Thử lại'))).style.color,
          foreground,
        );
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        expect(calls, 0);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(calls, 1);
        await tester.pump();
        expect(calls, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'mounted text button keeps transparent base while state overlays remain',
    (tester) async {
      final states = WidgetStatesController();
      addTearDown(states.dispose);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: Brand.theme,
          home: Scaffold(
            body: ColoredBox(
              color: Brand.warningSurface,
              child: Column(
                children: [
                  TextButton(
                    key: const ValueKey('enabled-text-action'),
                    statesController: states,
                    onPressed: () => calls++,
                    child: const Text('Thực hiện'),
                  ),
                  const TextButton(
                    key: ValueKey('disabled-text-action'),
                    onPressed: null,
                    child: Text('Chưa khả dụng'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final state in [
        WidgetState.focused,
        WidgetState.hovered,
        WidgetState.pressed,
      ]) {
        states.update(state, true);
        await tester.pumpAndSettle();
        final button = find.byKey(const ValueKey('enabled-text-action'));
        expect(
          tester
              .widget<Material>(
                find
                    .descendant(of: button, matching: find.byType(Material))
                    .first,
              )
              .color,
          Colors.transparent,
        );
        final ink = tester.widget<InkWell>(
          find.descendant(of: button, matching: find.byType(InkWell)).first,
        );
        expect(ink.overlayColor!.resolve({state})!.a, greaterThan(0));
        expect(calls, 0);
        states.update(state, false);
      }
      final disabled = find.byKey(const ValueKey('disabled-text-action'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Material>(
              find
                  .descendant(of: disabled, matching: find.byType(Material))
                  .first,
            )
            .color,
        Colors.transparent,
      );
      expect(tester.getSize(disabled).height, greaterThanOrEqualTo(48));
      await tester.tap(disabled);
      expect(calls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final kind in FeedbackBannerKind.values) {
    testWidgets('$kind is readable semantic feedback with manual action only', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        var calls = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: Brand.theme,
            home: Scaffold(
              body: FeedbackBanner(
                kind: kind,
                title: 'Dữ liệu mẫu',
                message: 'Chưa kết nối Backend.',
                actionLabel: 'Thử lại',
                onAction: () => calls++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(calls, 0);
        final node = tester.getSemantics(find.byType(FeedbackBanner));
        expect(
          node.getSemanticsData().flagsCollection.isLiveRegion,
          kind != FeedbackBannerKind.info,
        );
        expect(find.text('Chưa kết nối Backend.'), findsOneWidget);
        final target = tester.getSize(find.byType(TextButton));
        expect(target.height, greaterThanOrEqualTo(48));
        await tester.tap(find.text('Thử lại'));
        expect(calls, 1);
        await tester.pump();
        expect(calls, 1);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('components width=$width text=$scale height844 keyboard300', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        var submits = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: Brand.theme,
            home: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  child: ContentContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(
                          key: ValueKey('content-width'),
                          height: 48,
                        ),
                        for (final kind in FeedbackBannerKind.values) ...[
                          FeedbackBanner(
                            kind: kind,
                            title: 'Thông báo minh họa',
                            message: 'Nội dung rõ ràng khi tăng cỡ chữ. Không gọi API hoặc lưu lịch trình.',
                          ),
                          const SizedBox(height: 16),
                        ],
                        const TextField(
                          key: ValueKey('keyboard-field'),
                          decoration: InputDecoration(
                            labelText: 'Ghi chú kiểm thử',
                          ),
                        ),
                        FilledButton(
                          key: const ValueKey('keyboard-action'),
                          onPressed: () => submits++,
                          child: const Text('Tiếp tục'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final marker = tester.getRect(
          find.byKey(const ValueKey('content-width')),
        );
        final inset = width >= 600 ? 24.0 : 16.0;
        expect(marker.left, inset);
        expect(marker.right, width - inset);
        await tester.ensureVisible(
          find.byKey(const ValueKey('keyboard-field')),
        );
        await tester.showKeyboard(find.byKey(const ValueKey('keyboard-field')));
        await tester.enterText(
          find.byKey(const ValueKey('keyboard-field')),
          'Giữ nội dung',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('keyboard-action')),
        );
        await tester.pumpAndSettle();
        final action = tester.getRect(
          find.byKey(const ValueKey('keyboard-action')),
        );
        expect(action.bottom, lessThanOrEqualTo(844 - 300));
        expect(action.height, greaterThanOrEqualTo(48));
        await tester.tap(find.byKey(const ValueKey('keyboard-action')));
        expect(submits, 1);
        expect(find.text('Giữ nội dung'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets(
    'content max width is optional and safe in horizontal scrolling',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ContentContainer(
                maxWidth: 200,
                child: const SizedBox(key: ValueKey('bounded'), height: 40),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const ValueKey('bounded'))).width, 200);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentContainer(
              maxWidth: null,
              child: SizedBox(key: ValueKey('unbounded'), height: 40),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('unbounded'))).width,
        752,
      );
    },
  );

  testWidgets(
    'native button focus works from keyboard and disabled action stays inert',
    (tester) async {
      final focus = FocusNode();
      final states = WidgetStatesController();
      addTearDown(focus.dispose);
      addTearDown(states.dispose);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: Brand.theme,
          home: Scaffold(
            body: Column(
              children: [
                FilledButton(
                  focusNode: focus,
                  statesController: states,
                  onPressed: () => calls++,
                  child: const Text('Thực hiện'),
                ),
                const FilledButton(
                  onPressed: null,
                  child: Text('Chưa khả dụng'),
                ),
              ],
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(states.value, contains(WidgetState.focused));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(calls, 1);
      await tester.tap(find.text('Chưa khả dụng'));
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
