import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/dev/previews/android_device_frame.dart';
import 'package:localmate_ai_mobile/dev/previews/localmate_previews.dart';

void main() {
  test('preview storage is isolated and ephemeral', () async {
    final first = PreviewSessionStore();
    final second = PreviewSessionStore();
    await first.write('offline-test-only');
    expect(await first.read(), 'offline-test-only');
    expect(await second.read(), isNull);
    await first.clear();
    expect(await first.read(), isNull);
  });

  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('frame adapts to panel $width and text $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        MediaQueryData? actual;
        await tester.pumpWidget(
          AndroidDeviceFrame(
            textScale: scale,
            child: Builder(
              builder: (context) {
                actual = MediaQuery.of(context);
                return const ColoredBox(color: Colors.white);
              },
            ),
          ),
        );
        expect(actual!.size, const Size(412, 892));
        expect(actual!.padding, AndroidDeviceFrame.systemInsets);
        expect(actual!.viewPadding, AndroidDeviceFrame.systemInsets);
        expect(actual!.textScaler.scale(16), 16 * scale);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('home preview runs the real shell and can change tabs', (
    tester,
  ) async {
    await tester.pumpWidget(previewHome());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('reference preview keeps the 390 x 844 canvas', (tester) async {
    await tester.pumpWidget(previewReferenceCanvas());
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(AndroidDeviceFrame.screenKey)),
      const Size(390, 844),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
