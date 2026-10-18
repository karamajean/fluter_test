import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Renders [child] inside an iPhone 14 Pro sized frame so the iOS layout can
/// be checked on Windows / Web without a Mac.
///
/// Enable with `--dart-define=IPHONE_PREVIEW=true`. The app also switches to
/// iOS platform behaviour (scroll physics, page transitions, fonts).
class IPhone14ProPreview extends StatelessWidget {
  const IPhone14ProPreview({super.key, required this.child});

  final Widget child;

  static const enabled = bool.fromEnvironment('IPHONE_PREVIEW');

  // iPhone 14 Pro: 1179×2556 px @3x → 393×852 logical points.
  static const _screen = Size(393, 852);
  static const _safeArea = EdgeInsets.only(top: 59, bottom: 34);
  static const _bezel = 12.0;
  static const _screenRadius = 55.0;

  /// Call before `runApp` to make the framework behave as on iOS.
  static void applyPlatformOverride() {
    if (enabled) debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    final host = MediaQuery.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFF2B2B2B),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FittedBox(
            child: Container(
              padding: const EdgeInsets.all(_bezel),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(_screenRadius + _bezel),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_screenRadius),
                child: SizedBox.fromSize(
                  size: _screen,
                  child: Stack(
                    children: [
                      MediaQuery(
                        data: host.copyWith(
                          size: _screen,
                          devicePixelRatio: 3,
                          padding: _safeArea,
                          viewPadding: _safeArea,
                          viewInsets: EdgeInsets.zero,
                        ),
                        child: child,
                      ),
                      const _DynamicIsland(),
                      const _HomeIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DynamicIsland extends StatelessWidget {
  const _DynamicIsland();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(top: 11),
        width: 126,
        height: 37,
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          width: 134,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0x99888888),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
