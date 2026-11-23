// Preview frames, system bars, navigation isolation and theme inheritance.
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart'
    show LogicalKeyboardKey, SystemUiOverlayStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

const _pageKey = ValueKey<String>('page');

/// A previewed page: its title, a field, the register it reads and its own
/// exit, as a screen's derived back or close asks its route to pop.
class _Page extends StatefulWidget {
  const _Page(this.title);

  final String title;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  static int created = 0;

  final TextEditingController _field = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    created++;
  }

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      key: _pageKey,
      children: <Widget>[
        Text(widget.title),
        Text('register: ${RoutePresentation.of(context).name}'),
        EditableText(
          controller: _field,
          focusNode: _focus,
          style: const TextStyle(),
          cursorColor: const Color(0xFF000000),
          backgroundCursorColor: const Color(0xFF000000),
        ),
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: const Text('Exit'),
        ),
      ],
    ),
  );
}

Future<void> _phone(WidgetTester tester, PreviewPlatform platform) async {
  final device = platform.device;
  tester.view.physicalSize = device.physicalSize;
  tester.view.devicePixelRatio = device.devicePixelRatio;
  addTearDown(tester.view.reset);
}

/// The light and dark system-bar glyphs a theme draws: the lightest and
/// the darkest of its surface grounds and inks.
({Color light, Color dark}) _glyphs(ExpressiveThemeData theme) {
  final c = theme.colors;
  final all = <Color>[
    c.onSurface,
    c.inverseOnSurface,
    c.surface,
    c.surfaceContainerLowest,
  ]..sort((a, b) => a.computeLuminance().compareTo(b.computeLuminance()));
  return (light: all.last, dark: all.first);
}

void main() {
  group('the device and the system bars', () {
    for (final platform in PreviewPlatform.values) {
      testWidgets('the ${platform.name} register reserves and draws its bars', (
        tester,
      ) async {
        await _phone(tester, platform);
        await tester.pumpWidget(
          ExpressivePreview(platform: platform, child: const _Page('Home')),
        );
        await tester.pumpAndSettle();
        final insets = ExpressivePreview.systemInsetsOf(platform);
        final context = tester.element(find.byKey(_pageKey));
        expect(
          MediaQuery.paddingOf(context),
          EdgeInsets.zero,
          reason: 'the page\'s SafeArea consumed the bars',
        );
        // The SafeArea the page stands in (the host's toaster keeps one of
        // its own beside the app).
        final outer = tester.element(
          find.ancestor(
            of: find.byKey(_pageKey),
            matching: find.byType(SafeArea),
          ),
        );
        expect(MediaQuery.paddingOf(outer), insets);
        // The page stands clear of both bars.
        final page = tester.getRect(find.byKey(_pageKey));
        expect(page.top, insets.top);
        expect(page.bottom, platform.device.size.height - insets.bottom);
        expect(
          tester
              .getSize(
                find.byKey(const ValueKey('expressive-preview:status-bar')),
              )
              .height,
          insets.top,
        );
        expect(
          find.byKey(
            ValueKey<String>(
              platform == PreviewPlatform.ios
                  ? 'expressive-preview:home-indicator'
                  : 'expressive-preview:gesture-handle',
            ),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    test('the registers\' insets are the platforms\' own', () {
      expect(
        ExpressivePreview.systemInsetsOf(PreviewPlatform.android),
        const EdgeInsets.only(top: 24, bottom: 24),
      );
      expect(
        ExpressivePreview.systemInsetsOf(
          PreviewPlatform.android,
          mode: ExpressiveNavigationMode.threeButton,
        ),
        const EdgeInsets.only(top: 24, bottom: 48),
      );
      expect(
        ExpressivePreview.systemInsetsOf(PreviewPlatform.ios),
        const EdgeInsets.only(top: 47, bottom: 34),
      );
    });

    testWidgets('Android draws the three-button bar when asked', (
      tester,
    ) async {
      await _phone(tester, PreviewPlatform.android);
      await tester.pumpWidget(
        const ExpressivePreview(
          navigationMode: ExpressiveNavigationMode.threeButton,
          child: _Page('Home'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('expressive-preview:three-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('expressive-preview:gesture-handle')),
        findsNothing,
      );
      expect(
        tester.getRect(find.byKey(_pageKey)).bottom,
        PreviewDevice.android.size.height - 48,
      );
    });

    testWidgets('the bars are never hit and never announced', (tester) async {
      await _phone(tester, PreviewPlatform.android);
      var taps = 0;
      await tester.pumpWidget(
        ExpressivePreview(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 4));
      await tester.tapAt(Offset(200, PreviewDevice.android.size.height - 4));
      expect(taps, 2);
      expect(find.bySemanticsLabel('12:30'), findsNothing);
    });

    testWidgets('the bars wear the content colour of the brightness', (
      tester,
    ) async {
      await _phone(tester, PreviewPlatform.android);
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          ExpressivePreview(
            key: ValueKey(brightness),
            brightness: brightness,
            child: const SizedBox.expand(),
          ),
        );
        await tester.pumpAndSettle();
        final theme = ExpressiveThemeData.preset(
          ExpressiveThemeData.defaultPreset,
          brightness,
        );
        final time = tester.widget<Text>(find.text('12:30'));
        expect(time.style?.color, theme.colors.onSurface);
      }
    });

    for (final platform in PreviewPlatform.values) {
      testWidgets('on ${platform.name} the bars follow the overlay style the '
          'page annotates under them', (tester) async {
        await _phone(tester, platform);
        final theme = ExpressiveThemeData.preset(
          ExpressiveThemeData.defaultPreset,
          Brightness.light,
        );
        final light = _glyphs(theme).light;
        final cover = ValueNotifier<bool>(true);
        addTearDown(cover.dispose);
        Color time() => tester.widget<Text>(find.text('12:30')).style!.color!;
        Color pill() {
          final key = platform == PreviewPlatform.ios
              ? 'expressive-preview:home-indicator'
              : 'expressive-preview:gesture-handle';
          final box = tester.widget<DecoratedBox>(
            find.descendant(
              of: find.byKey(ValueKey<String>(key)),
              matching: find.byType(DecoratedBox),
            ),
          );
          return (box.decoration as ShapeDecoration).color!;
        }

        await tester.pumpWidget(
          ExpressivePreview(
            platform: platform,
            child: ValueListenableBuilder<bool>(
              valueListenable: cover,
              builder: (context, dark, _) => dark
                  // A full-bleed cover over a dark photo asks for light
                  // glyphs.
                  ? const AnnotatedRegion<SystemUiOverlayStyle>(
                      value: SystemUiOverlayStyle.light,
                      child: SizedBox.expand(),
                    )
                  : const SizedBox.expand(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(time(), light);
        expect(pill(), light);

        // The cover gone, the bars fall back to the theme's content
        // colour.
        cover.value = false;
        await tester.pumpAndSettle();
        expect(time(), theme.colors.onSurface);
        expect(pill(), theme.colors.onSurface);

        cover.value = true;
        await tester.pumpAndSettle();
        expect(time(), light);
      });
    }

    testWidgets('a page in a theme scope of its own lends the bars its ink '
        'where it asks for no overlay style', (tester) async {
      await _phone(tester, PreviewPlatform.android);
      // A page wearing another scheme than the preview's (a show's cover
      // colours): the dark preset inside a light preview.
      final page = ExpressiveThemeData.preset(
        ExpressiveThemeData.defaultPreset,
        Brightness.dark,
      );
      await tester.pumpWidget(
        ExpressivePreview(
          child: ExpressiveTheme(data: page, child: const SizedBox.expand()),
        ),
      );
      await tester.pumpAndSettle();
      final time = tester.widget<Text>(find.text('12:30'));
      expect(time.style?.color, page.colors.onSurface);
      final pill = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(const ValueKey('expressive-preview:gesture-handle')),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((pill.decoration as ShapeDecoration).color, page.colors.onSurface);
    });

    testWidgets('a style under the status band alone leaves the navigation '
        'bar to Android\'s own reading, and dark icons read dark', (
      tester,
    ) async {
      await _phone(tester, PreviewPlatform.android);
      final theme = ExpressiveThemeData.preset(
        ExpressiveThemeData.defaultPreset,
        Brightness.dark,
      );
      await tester.pumpWidget(
        const ExpressivePreview(
          brightness: Brightness.dark,
          navigationMode: ExpressiveNavigationMode.threeButton,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 120,
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle.dark,
                  child: SizedBox.expand(),
                ),
              ),
              Expanded(
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    systemNavigationBarIconBrightness: Brightness.light,
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final time = tester.widget<Text>(find.text('12:30'));
      // Dark icons in the dark theme: its darkest ground.
      expect(time.style?.color, _glyphs(theme).dark);
      expect(time.style?.color, isNot(theme.colors.onSurface));
      final keys = tester.widget<IconTheme>(
        find.byKey(const ValueKey<String>('expressive-preview:three-button')),
      );
      expect(keys.data.color, theme.colors.onSurface);
    });

    testWidgets('without system bars the frame\'s insets stand', (
      tester,
    ) async {
      await _phone(tester, PreviewPlatform.ios);
      await tester.pumpWidget(
        const ExpressivePreview(systemBars: false, child: _Page('Home')),
      );
      await tester.pumpAndSettle();
      expect(find.text('12:30'), findsNothing);
      expect(tester.getRect(find.byKey(_pageKey)).top, 0);
    });

    for (final platform in PreviewPlatform.values) {
      testWidgets('with device, a ${platform.name} page is laid out at the '
          'register\'s device and scaled to fit', (tester) async {
        tester.view.physicalSize = const Size(600, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ExpressivePreview(
            platform: platform,
            device: true,
            child: const _Page('Home'),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byKey(_pageKey));
        expect(MediaQuery.sizeOf(context), platform.device.size);
        expect(PreviewFrame.targetPlatformOf(context), platform.targetPlatform);
        expect(Theme.of(context).platform, platform.targetPlatform);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a text scale of 1.3 leaves the bars in their band', (
      tester,
    ) async {
      await _phone(tester, PreviewPlatform.ios);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        const ExpressivePreview(
          platform: PreviewPlatform.ios,
          child: _Page('Home'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.text('12:30')).height,
        lessThanOrEqualTo(
          ExpressivePreview.systemInsetsOf(PreviewPlatform.ios).top,
        ),
      );
    });
  });

  group('Preview navigation and inherited themes', () {
    testWidgets('a preview keeps its page and focused field when rebuilt '
        'with a new page', (tester) async {
      await _phone(tester, PreviewPlatform.android);
      _PageState.created = 0;
      await tester.pumpWidget(const ExpressivePreview(child: _Page('Draft')));
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Morning pages');
      await tester.pump();

      await tester.pumpWidget(const ExpressivePreview(child: _Page('Draft 2')));
      await tester.pump();
      expect(find.text('Draft 2'), findsOneWidget);
      expect(find.text('Morning pages'), findsOneWidget);
      expect(_PageState.created, 1);
      final field = tester.state<EditableTextState>(find.byType(EditableText));
      expect(field.widget.focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });

    for (final register in RoutePresentation.values) {
      testWidgets('a page previewed alone as ${register.name} reads the '
          'register its live route would', (tester) async {
        await _phone(tester, PreviewPlatform.android);
        await tester.pumpWidget(
          ExpressivePreview(
            presentation: register,
            under: const Text('Beneath'),
            child: const _Page('Trip'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('register: ${register.name}'), findsOneWidget);
        expect(
          find.text('Beneath', skipOffstage: false),
          register == RoutePresentation.root ? findsNothing : findsWidgets,
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final register in <RoutePresentation>[
      RoutePresentation.pushed,
      RoutePresentation.sheet,
    ]) {
      testWidgets('a ${register.name} preview refuses its own pop, while a '
          'route raised over it still closes', (tester) async {
        await _phone(tester, PreviewPlatform.android);
        await tester.pumpWidget(
          ExpressivePreview(presentation: register, child: const _Page('Trip')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Trip'), findsOneWidget);

        // The derived exit.
        await tester.tap(find.text('Exit'));
        await tester.pumpAndSettle();
        expect(find.text('Trip'), findsOneWidget);

        // The page's own pop: the stage raises it again.
        Navigator.of(tester.element(find.text('Trip'))).pop();
        await tester.pumpAndSettle();
        expect(find.text('Trip'), findsOneWidget);

        // The system back.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Trip'), findsOneWidget);

        // A pop that asks for the whole stack still leaves the page.
        Navigator.of(tester.element(find.text('Trip')))
            .popUntil((route) => route.isFirst);
        await tester.pumpAndSettle();
        expect(find.text('Trip'), findsOneWidget);

        // A route raised over the page still pops.
        showGeneralDialog<void>(
          context: tester.element(find.text('Trip')),
          pageBuilder: (context, _, _) => const Center(child: Text('Raised')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Raised'), findsOneWidget);
        Navigator.of(tester.element(find.text('Raised'))).pop();
        await tester.pumpAndSettle();
        expect(find.text('Raised'), findsNothing);
        expect(find.text('Trip'), findsOneWidget);
        expect(find.text('register: ${register.name}'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    // Routes on a preview navigator inherit its theme. Root overlays capture
    // the preview’s inherited themes, including ExpressiveTheme.
    testWidgets('a preview nested in another app keeps its theme in routes '
        'raised over the page', (tester) async {
      await _phone(tester, PreviewPlatform.android);
      final bloom = ExpressiveThemeData.preset('bloom', Brightness.dark);
      final raised = <String, ExpressiveThemeData>{};
      Widget opener(String label, {required bool root}) => Builder(
        builder: (context) => GestureDetector(
          onTap: () {
            final navigator = Navigator.of(context, rootNavigator: root);
            final themes = InheritedTheme.capture(
              from: context,
              to: navigator.context,
            );
            navigator.push(
              PageRouteBuilder<void>(
                opaque: false,
                pageBuilder: (context, _, _) => themes.wrap(
                  Builder(
                    builder: (context) {
                      raised[label] = context.expressiveTheme;
                      return Center(child: Text('Raised $label'));
                    },
                  ),
                ),
              ),
            );
          },
          child: Text(label),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ExpressivePreview(
            brightness: Brightness.dark,
            darkTheme: bloom,
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  opener('own', root: false),
                  opener('outer', root: true),
                ],
              ),
            ),
          ),
        ),
      );
      for (final label in <String>['own', 'outer']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.text('Raised $label'), findsOneWidget);
        expect(raised[label]?.id, bloom.id);
        expect(raised[label]?.brightness, Brightness.dark);
        expect(raised[label]?.colors.primary, bloom.colors.primary);
        Navigator.of(tester.element(find.text('Raised $label'))).pop();
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Tab goes on from a preview to the page it stands in', (
    tester,
  ) async {
    // A preview’s navigator passes keyboard focus to the surrounding page
    // after its last control.
    final after = FocusNode(debugLabel: 'after');
    addTearDown(after.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            const Expanded(
              child: ExpressivePreview(
                platform: PreviewPlatform.android,
                child: _Page('Home'),
              ),
            ),
            TextButton(
              focusNode: after,
              onPressed: () {},
              child: const Text('After'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final preview = find.byType(ExpressivePreview);
    final navigators = tester.widgetList<Navigator>(
      find.descendant(of: preview, matching: find.byType(Navigator)),
    );
    expect(navigators, isNotEmpty);
    for (final navigator in navigators) {
      expect(
        navigator.routeTraversalEdgeBehavior,
        TraversalEdgeBehavior.parentScope,
      );
    }
    expect(
      find.descendant(
        of: preview,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is FocusScope && widget.debugLabel == 'Navigator Scope',
        ),
      ),
      findsNothing,
      reason: "an app's own navigator leaves the window on the web",
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(after.hasPrimaryFocus, isTrue);
  });

  testWidgets('a preview reads in the language of the page it stands in', (
    tester,
  ) async {
    // The gallery's right-to-left pages are Arabic, their previews' own
    // words (an error state's Try again) were their own app's English.
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [_FrenchWords()],
        home: ExpressivePreview(
          platform: PreviewPlatform.android,
          child: ExpressiveErrorState(title: 'Hors ligne', onRetry: _noop),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });
}

void _noop() {}

/// The look's words with a French retry, for the language test.
class _FrenchWords extends LocalizationsDelegate<ExpressiveLocalizations> {
  const _FrenchWords();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<ExpressiveLocalizations> load(Locale locale) =>
      SynchronousFuture(const ExpressiveLocalizations(tryAgain: 'Réessayer'));

  @override
  bool shouldReload(_FrenchWords old) => false;
}
