import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/features/foundation/domain/destination.dart';
import 'package:localmate_ai_mobile/shared/theme/app_theme.dart';
import 'package:localmate_ai_mobile/shared/widgets/brand_header.dart';

import 'support/fake_session_store.dart';

Future<ProviderContainer> boot(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      sessionStoreProvider.overrideWithValue(FakeSessionStore()),
      apiProvider.overrideWith(
        (_) => throw StateError('Unexpected global transport'),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const LocalMateApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await fonts.load();
  });
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('shell $width x844 text=$scale geometry semantics and Back', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final semantics = tester.ensureSemantics();
        try {
          final container = await boot(tester);
          addTearDown(container.dispose);
          expect(
            tester
                .widget<BrandHeader>(find.byType(BrandHeader))
                .preferredSize
                .height,
            64,
          );
          final account = find.byKey(const ValueKey('brand-account-action'));
          final bounds = tester.getRect(account);
          expect(bounds.size, const Size(48, 48));
          expect(bounds.right, width - 16);
          final iconBounds = tester.getRect(
            find.descendant(of: account, matching: find.byType(Icon)),
          );
          expect(iconBounds.width, 24);
          expect(iconBounds.right, width - 28);
          final brand = find.byKey(const ValueKey('brand-wordmark'));
          expect(
            tester.renderObject<RenderParagraph>(brand).didExceedMaxLines,
            isFalse,
          );
          expect(
            MediaQuery.textScalerOf(tester.element(brand)).scale(10),
            closeTo(scale == 2 ? 13 : 10, .01),
          );
          expect(find.bySemanticsLabel('LocalMate AI'), findsWidgets);
          expect(
            MediaQuery.textScalerOf(
              tester.element(find.text(Destination.home.heading)),
            ).scale(10),
            scale * 10,
          );
          debugPrint(
            'V02_SHELL width=$width text=$scale account=$bounds '
            'icon=$iconBounds brand=${tester.getRect(brand)}',
          );
          expect(
            tester
                .getSemantics(account)
                .getSemanticsData()
                .flagsCollection
                .isButton,
            isTrue,
          );
          for (final destination in Destination.values) {
            final item = find
                .byType(NavigationDestination)
                .at(destination.index);
            await tester.tap(item);
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<NavigationBar>(find.byType(NavigationBar))
                  .selectedIndex,
              destination.index,
            );
            final bar = tester.getRect(find.byType(NavigationBar));
            expect(bar.height, scale == 2 ? 112 : 80);
            final barWidget = tester.widget<NavigationBar>(
              find.byType(NavigationBar),
            );
            final labels =
                barWidget.labelTextStyle ??
                Theme.of(tester.element(find.byType(NavigationBar)))
                    .navigationBarTheme
                    .labelTextStyle!;
            expect(labels.resolve({WidgetState.selected})!.color, Brand.navy);
            expect(labels.resolve({})!.color, Brand.muted);
            final label = scale == 2
                ? destination.label.replaceAll(' ', '\n')
                : destination.label;
            final text = find
                .descendant(of: item, matching: find.text(label))
                .first;
            final textBounds = tester.getRect(text);
            expect(
              textBounds.left,
              greaterThanOrEqualTo(width / 5 * destination.index - .1),
            );
            expect(
              textBounds.right,
              lessThanOrEqualTo(width / 5 * (destination.index + 1) + .1),
            );
            expect(textBounds.bottom, lessThanOrEqualTo(bar.bottom));
            expect(tester.takeException(), isNull);
          }
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text(Destination.home.heading), findsOneWidget);
          await tester.tap(account);
          await tester.pumpAndSettle();
          expect(
            container
                .read(routerProvider)
                .routeInformationProvider
                .value
                .uri
                .path,
            '/account',
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  testWidgets(
    'private guard still redirects and shell does not create a session',
    (tester) async {
      final container = await boot(tester);
      addTearDown(container.dispose);
      container.read(routerProvider).go('/private');
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập offline'), findsOneWidget);
      expect(find.byKey(const Key('login-email')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'context-ready header invokes only the supplied account callback',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: Brand.theme,
          home: Scaffold(
            appBar: BrandHeader(
              contextTitle: 'Khám phá',
              onAccount: () => calls++,
            ),
            body: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Khám phá'), findsOneWidget);
      expect(find.text('AI'), findsNothing);
      expect(calls, 0);
      await tester.tap(find.byTooltip('Mở tài khoản'));
      expect(calls, 1);
    },
  );

  testWidgets(
    'shared header retains the native Back affordance on a pushed route',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: Brand.theme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: BrandHeader(
                        onAccount: () {},
                        contextTitle: 'Khám phá',
                      ),
                    ),
                  ),
                ),
                child: const Text('Mở màn hình'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở màn hình'));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Mở màn hình'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
