/// The host: the ground, text and icon defaults, the thin primitives
/// theme in Expressive's colours on the ambient platform, Android's
/// edge-to-edge bars, and no text-scale clamp.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('stands the page on the ${brightness.name} ground', (
      tester,
    ) async {
      final t = ExpressiveThemeData.preset('bloom', brightness);
      late BuildContext inside;
      await tester.pumpWidget(
        ExpressiveHost(
          light: ExpressiveThemeData.preset('bloom', Brightness.light),
          dark: ExpressiveThemeData.preset('bloom', Brightness.dark),
          brightness: brightness,
          child: Builder(
            builder: (context) {
              inside = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(inside.expressiveTheme, t);
      final ground = tester.widget<ColoredBox>(find.byType(ColoredBox).first);
      expect(ground.color, t.colors.surface);
      // Compose's MaterialTheme: bodyLarge, content in onSurface.
      final text = DefaultTextStyle.of(inside).style;
      expect(text.fontSize, t.type.bodyLarge.fontSize);
      expect(text.fontFamily, t.type.bodyLarge.fontFamily);
      expect(text.color, t.colors.onSurface);
      expect(IconTheme.of(inside).color, t.colors.onSurface);

      // The primitives read Expressive's roles.
      final material = Theme.of(inside);
      expect(material.brightness, brightness);
      expect(material.colorScheme.primary, t.colors.primary);
      expect(
        material.colorScheme.surfaceContainerHighest,
        t.colors.surfaceContainerHighest,
      );
      expect(material.colorScheme.onInverseSurface, t.colors.inverseOnSurface);
      expect(material.textSelectionTheme.cursorColor, t.colors.primary);
      expect(
        material.textSelectionTheme.selectionColor,
        t.colors.primary.withValues(
          alpha: HostBehavior.textSelectionBackgroundOpacity,
        ),
      );
      expect(DefaultSelectionStyle.of(inside).cursorColor, t.colors.primary);

      // Edge-to-edge bars, icons contrasting with the ground.
      final bars = tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .value;
      expect(bars.statusBarColor!.a, 0);
      expect(bars.systemNavigationBarColor!.a, 0);
      expect(bars.systemNavigationBarContrastEnforced, isFalse);
      final icons = brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark;
      expect(bars.statusBarIconBrightness, icons);
      expect(bars.systemNavigationBarIconBrightness, icons);
    });
  }

  testWidgets('pins no platform: the ambient one outside a preview frame', (
    tester,
  ) async {
    for (final platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      late TargetPlatform read;
      await tester.pumpWidget(
        ExpressiveHost(
          child: Builder(
            builder: (context) {
              read = Theme.of(context).platform;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(read, platform);
    }
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('asks Android for edge-to-edge outside a preview frame only', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(
      const PreviewFrame(
        platform: PreviewPlatform.android,
        child: ExpressiveHost(child: SizedBox.shrink()),
      ),
    );
    await tester.pumpWidget(const ExpressiveHost(child: SizedBox.shrink()));
    await tester.pumpWidget(
      const ExpressiveHost(brightness: Brightness.dark, child: SizedBox()),
    );
    debugDefaultTargetPlatformOverride = null;
    final modes = calls
        .where((call) => call.method == 'SystemChrome.setEnabledSystemUIMode')
        .toList();
    expect(modes, hasLength(1));
    expect(modes.single.arguments, 'SystemUiMode.edgeToEdge');
  });

  testWidgets('clamps no text scale', (tester) async {
    late TextScaler read;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: ExpressiveHost(
          child: Builder(
            builder: (context) {
              read = MediaQuery.textScalerOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(read, const TextScaler.linear(1.3));
  });

  test('the theme reaches every foundation', () {
    final t = ExpressiveThemeData.preset('slate', Brightness.dark);
    expect(t.states, ExpressiveStateLayers.tokens);
    expect(t.elevation.colors, t.colors);
    final calm = t.copyWith(expression: ExpressiveExpression.bold);
    expect(calm.expression, ExpressiveExpression.bold);
    expect(calm.colors, t.colors);
    expect(calm.id, t.id);
    expect(t.copyWith(), t);
  });
}
