import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/centred_host.dart';

void main() {
  // Decoded marks and pictures stay in the image cache past their test:
  // cleared, so leak tracking sees them disposed.
  tearDown(
    () => imageCache
      ..clear()
      ..clearLiveImages(),
  );

  group('MinimalSignInButton', () {
    testWidgets('names the provider, taps, and is 40 px', (tester) async {
      final handle = tester.ensureSemantics();
      // On a phone's width, where a sign-in stack stands: the test's
      // stand-in face sets every glyph a full em wide, so a desktop's 320 px
      // measure would wrap the words to two lines (Geist sets them in 140).
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var taps = 0;
      await tester.pumpWidget(
        centredHost(MinimalSignInButton('apple', onPressed: () => taps += 1)),
      );
      final button = find.bySemanticsLabel('Continue with Apple');
      expect(
        tester.getSemantics(button),
        matchesSemantics(
          label: 'Continue with Apple',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(tester.getSize(button).height, MinimalChromeMetrics.controlLg);
      await tester.tap(button);
      expect(taps, 1);
      handle.dispose();
      // The mark's decode finishes here, in the cache the tearDown clears,
      // rather than in the next test's real-time wait, where nothing would
      // dispose it.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    });

    testWidgets('email says so; a provider the app does not bundle draws '
        'a monogram', (tester) async {
      await tester.pumpWidget(
        centredHost(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalSignInButton('email', expand: false),
              MinimalSignInButton(
                'sso',
                label: 'Continue with SSO',
                expand: false,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Continue with email'), findsOneWidget);
      // Resolved by lookup in the app's vocabulary: no failed asset load.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('bundled marks resolve: brand, dark cut, mono mask', (
      tester,
    ) async {
      // The asset key the manifest lists: `assets/logos/…` where the app
      // bundles the marks (the package's own tests), under
      // `packages/minimal_ui/` in an app on the package.
      Future<String> asset(
        WidgetTester tester,
        Widget button, {
        Brightness brightness = Brightness.light,
      }) async {
        await tester.pumpWidget(centredHost(button, brightness: brightness));
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        return (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName;
      }

      // Live buttons: a disabled one draws its mono cut.
      expect(
        await asset(tester, MinimalSignInButton('apple', onPressed: () {})),
        'assets/logos/apple_mark.png',
      );
      expect(
        await asset(
          tester,
          MinimalSignInButton('apple', onPressed: () {}),
          brightness: Brightness.dark,
        ),
        'assets/logos/apple_mark_dark.png',
      );
      expect(
        await asset(
          tester,
          const MinimalSignInButton('google', emphasis: true),
        ),
        'assets/logos/google_mark_mask.png',
      );
    });

    testWidgets('disabled, a brand mark turns to its mono cut in the '
        'label\'s ink, so it dims with the words', (tester) async {
      await tester.pumpWidget(centredHost(const MinimalSignInButton('google')));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      final mark = tester.widget<Image>(find.byType(Image));
      expect(
        (mark.image as AssetImage).assetName,
        'assets/logos/google_mark_mask.png',
      );
      expect(
        mark.color,
        MinimalThemeData.preset('standard', Brightness.light).foreground,
      );
    });

    testWidgets('the kit\'s marks resolve where the kit ships them, and an '
        'app\'s own logo of the same name wins', (tester) async {
      // An app on the package lists the kit's marks under the package; an
      // app that bundles them itself lists them under its own folder.
      const kit = minimalFontPackage == null
          ? 'assets/logos/'
          : 'packages/$minimalFontPackage/assets/logos/';
      Future<String> asset(List<String> listed) async {
        await tester.pumpWidget(
          centredHost(
            DefaultAssetBundle(
              bundle: _LogoBundle(listed),
              child: const MinimalSignInButton('apple'),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        return (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName;
      }

      expect(await asset(['${kit}apple_mark.png']), '${kit}apple_mark.png');
      expect(
        await asset(['${kit}apple_mark.png', 'assets/logos/apple_mark.png']),
        'assets/logos/apple_mark.png',
      );
    });

    testWidgets('a mark the app bundles beyond the kit\'s resolves from its '
        'asset manifest', (tester) async {
      await tester.pumpWidget(
        centredHost(
          DefaultAssetBundle(
            bundle: _LogoBundle(const ['assets/logos/applepay_mark.png']),
            child: const MinimalSignInButton('applepay', label: 'Apple Pay'),
          ),
        ),
      );
      expect(find.byType(Image), findsNothing);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(
        (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName,
        'assets/logos/applepay_mark.png',
      );
    });

    testWidgets('a stack reports the provider chosen, and disables whole', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      String? chosen;
      await tester.pumpWidget(
        centredHost(
          MinimalSignInStack(const [
            'apple',
            'google',
            'email',
          ], onPressed: (provider) => chosen = provider),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Continue with Google'));
      expect(chosen, 'google');
      await tester.pumpWidget(
        centredHost(
          const MinimalSignInStack(['apple', 'google'], key: ValueKey('off')),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Continue with Google')),
        matchesSemantics(
          label: 'Continue with Google',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
      // The file's last test: the marks' decodes finish here (up to 2 s of
      // real time), then the cache lets them go before one more frame. A
      // cleared cache disposes its images in the next frame's callbacks, and
      // no frame follows the last test's tearDown.
      for (var i = 0; i < 100 && imageCache.pendingImageCount > 0; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pumpWidget(const SizedBox());
      imageCache
        ..clear()
        ..clearLiveImages();
      await tester.pump();
    });
  });
}

/// An asset bundle whose manifest lists exactly [assets], and that holds
/// nothing else.
class _LogoBundle extends CachingAssetBundle {
  _LogoBundle(this.assets);

  final List<String> assets;

  @override
  Future<ByteData> load(String key) async {
    if (key != 'AssetManifest.bin') throw FlutterError('No asset $key');
    return const StandardMessageCodec().encodeMessage(<String, Object>{
      for (final asset in assets)
        asset: [
          <String, Object>{'asset': asset},
        ],
    })!;
  }
}
