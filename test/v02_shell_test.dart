import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/features/foundation/domain/destination.dart';
import 'package:localmate_ai_mobile/core/theme/app_theme.dart';
import 'package:localmate_ai_mobile/core/widgets/widgets.dart';

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
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
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
          final account = find.byKey(const ValueKey('brand-account-action'));
          final bounds = tester.getRect(account);
          expect(bounds.width, greaterThanOrEqualTo(48));
          expect(bounds.height, greaterThanOrEqualTo(48));
          expect(bounds.right, lessThanOrEqualTo(width - 8));
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
          expect(
            tester
                .getSemantics(find.byTooltip('Mở tài khoản'))
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
            final tall = scale == 2 || width < 360;
            final bar = tester.getRect(find.byType(NavigationBar));
            // NavigationBar pads itself for the 24px system bottom inset.
            expect(bar.height, (tall ? 104 : 80) + 24);
            final scheme = AppTheme.light.colorScheme;
            final labels = AppTheme.light.navigationBarTheme.labelTextStyle!;
            expect(
              labels.resolve({WidgetState.selected})!.color,
              scheme.onSurface,
            );
            expect(labels.resolve({})!.color, scheme.onSurfaceVariant);
            final label = tall
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
      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(find.byKey(const Key('login-email')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('brand lockup announces the product name once', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Center(child: BrandLockup())),
      ),
    );
    expect(find.bySemanticsLabel('LocalMate AI'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    semantics.dispose();
  });
}
