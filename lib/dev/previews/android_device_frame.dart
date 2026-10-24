import 'package:flutter/material.dart';

/// Development-only skin, not a Samsung device or an Android emulator.
class AndroidDeviceFrame extends StatelessWidget {
  const AndroidDeviceFrame({
    super.key,
    required this.child,
    this.screenSize = const Size(412, 892),
    this.textScale = 1,
  });

  final Widget child;
  final Size screenSize;
  final double textScale;

  static const systemInsets = EdgeInsets.only(top: 32, bottom: 24);
  static const screenKey = ValueKey('android-preview-screen');

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: ColoredBox(
      color: const Color(0xFFE8EBF0),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF16191D),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFF687078), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: SizedBox(
                    key: screenKey,
                    width: screenSize.width,
                    height: screenSize.height,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MediaQuery(
                          data: MediaQueryData(
                            size: screenSize,
                            padding: systemInsets,
                            viewPadding: systemInsets,
                            textScaler: TextScaler.linear(textScale),
                            platformBrightness: Brightness.light,
                          ),
                          child: child,
                        ),
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 32,
                          child: IgnorePointer(
                            child: ExcludeSemantics(child: _StatusBar()),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 24,
                          child: IgnorePointer(
                            child: ExcludeSemantics(
                              child: ColoredBox(
                                color: Colors.white,
                                child: Center(
                                  child: Container(
                                    width: 108,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16191D),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: Stack(
      alignment: Alignment.center,
      children: [
        const Positioned(
          left: 18,
          child: Text(
            '9:41',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16191D),
              decoration: TextDecoration.none,
            ),
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFF16191D),
            shape: BoxShape.circle,
          ),
        ),
        const Positioned(
          right: 14,
          child: IconTheme(
            data: IconThemeData(size: 14, color: Color(0xFF16191D)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.signal_cellular_alt),
                SizedBox(width: 4),
                Icon(Icons.wifi),
                SizedBox(width: 4),
                Icon(Icons.battery_full),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
