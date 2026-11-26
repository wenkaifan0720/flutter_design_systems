// The frame an app built on Civic stands its pages in, as CivicPreview
// stands one page without a router: the places and the app's one act along
// a phone's foot, in a rail from 600 wide and down the start under the
// service's name from 1024, the way back on a pushed
// page and the close on a raised task (its chevron turned right to left),
// which leave a live page and leave a preview's standing, a page that comes
// and goes in place on every platform, the page states, and a host that
// leaves the reader's text size alone.
import 'dart:async';

import 'package:civic_ui/civic_ui.dart';
import 'package:civic_ui/civic_host.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'screens_matrix.dart' show loadScreenFonts;

const _places = [
  CivicNavItem(LucideIcons.house, 'Home', ValueKey('home')),
  CivicNavItem(LucideIcons.fileText, 'Applications', ValueKey('applications')),
  CivicNavItem(LucideIcons.circleUser, 'Account', ValueKey('account')),
];

const _act = ValueKey('act');
const _leading = ValueKey('leading');

Future<void> _show(
  WidgetTester tester,
  Widget app, {
  double width = 390,
  double height = 844,
  double text = 1,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Widget _hosted(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) =>
      CivicHost(child: child ?? const SizedBox.shrink()),
  home: home,
);

CivicPreview _place({
  required void Function(BuildContext context) onAct,
  Brightness brightness = Brightness.light,
}) => CivicPreview(
  brightness: brightness,
  tabs: _places,
  selectedIndex: 1,
  brand: 'Brindlemere permits',
  action: ShellAction(
    key: _act,
    icon: LucideIcons.plus,
    label: 'Apply for a permit',
    accent: true,
    onPressed: onAct,
  ),
  child: const CivicScreen(
    topBar: CivicTopBar(title: 'Parking permits'),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Your applications'),
        SizedBox(height: CivicSpacing.s16),
        Text('A permit lets you park in your zone at any time.'),
      ],
    ),
  ),
);

void main() {
  setUpAll(loadScreenFonts);
  testWidgets('a phone stands the places along its foot, the act at their '
      'end, a touch target at least 48 square', (tester) async {
    final semantics = tester.ensureSemantics();
    BuildContext? acted;
    await _show(tester, _place(onAct: (context) => acted = context));
    // Along the foot, side by side, each a glyph over its name.
    final home = tester.getCenter(find.byKey(const ValueKey('home')));
    expect(tester.getCenter(find.byKey(const ValueKey('account'))).dy, home.dy);
    expect(home.dy, greaterThan(844 - 96));
    expect(find.byIcon(LucideIcons.house), findsOneWidget);
    for (final place in ['home', 'applications', 'account']) {
      expect(find.byKey(ValueKey(place)), findsOneWidget);
    }
    final act = find.byKey(_act);
    expect(act, findsOneWidget);
    expect(find.bySemanticsLabel('Apply for a permit'), findsOneWidget);
    final size = tester.getSize(act);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(
      tester.getCenter(act).dx,
      greaterThan(tester.getCenter(find.byKey(const ValueKey('account'))).dx),
    );
    await tester.tap(act);
    await tester.pumpAndSettle();
    expect(acted, isNotNull);
    semantics.dispose();
  });

  testWidgets("a tablet stands the phone's places down the start as a rail, "
      'one over the other, the act over them', (tester) async {
    BuildContext? acted;
    await _show(
      tester,
      _place(onAct: (context) => acted = context),
      width: 768,
      height: 1024,
    );
    expect(find.byIcon(LucideIcons.house), findsOneWidget);
    final home = tester.getCenter(find.byKey(const ValueKey('home')));
    final account = tester.getCenter(find.byKey(const ValueKey('account')));
    expect(account.dx, home.dx, reason: 'one over the other');
    expect(account.dy, greaterThan(home.dy));
    expect(home.dx, lessThan(96), reason: 'at the start');
    final act = find.byKey(_act);
    expect(tester.getCenter(act).dy, lessThan(home.dy));
    expect(tester.getSize(act).width, greaterThanOrEqualTo(48));
    await tester.tap(act);
    await tester.pumpAndSettle();
    expect(acted, isNotNull);
  });

  testWidgets('from 1024 wide the places stand down the start under the '
      "service's name, the act a button in words at their foot", (
    tester,
  ) async {
    BuildContext? acted;
    await _show(
      tester,
      _place(onAct: (context) => acted = context),
      width: 1024,
      height: 768,
    );
    // Words alone, one over the other at the start.
    expect(find.byIcon(LucideIcons.house), findsNothing);
    final home = tester.getCenter(find.byKey(const ValueKey('home')));
    final account = tester.getCenter(find.byKey(const ValueKey('account')));
    expect(account.dy, greaterThan(home.dy));
    expect(home.dx, lessThan(CivicLayout.sideNavigationWidth));
    expect(find.text('Brindlemere permits'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(_act),
        matching: find.text('Apply for a permit'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(_act));
    await tester.pumpAndSettle();
    expect(acted, isNotNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('a place holds at 390 with twice the text '
        '(${brightness.name})', (tester) async {
      await _show(
        tester,
        _place(onAct: (_) {}, brightness: brightness),
        text: 2,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a press on a place selects it', (tester) async {
    int? picked;
    await _show(
      tester,
      _hosted(
        CivicAppShell(
          destinations: _places,
          selectedIndex: 0,
          onDestinationSelected: (index) => picked = index,
          child: const CivicScreen(body: Text('Home')),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('account')));
    await tester.pumpAndSettle();
    expect(picked, 2);
  });

  for (final (width, height) in [
    (390.0, 844.0),
    (768.0, 1024.0),
    (1440.0, 900.0),
  ]) {
    testWidgets('at $width the places are one tab stop: the arrows move '
        'along them and Enter picks the one reached', (tester) async {
      int? picked;
      await _show(
        tester,
        _hosted(
          CivicAppShell(
            destinations: _places,
            selectedIndex: 0,
            onDestinationSelected: (index) => picked = index,
            child: const CivicScreen(body: Text('Home')),
          ),
        ),
        width: width,
        height: height,
      );
      Focus.of(tester.element(find.byKey(const ValueKey('home'))))
          .requestFocus();
      await tester.pump();
      final next = width < CivicLayout.medium
          ? LogicalKeyboardKey.arrowRight
          : LogicalKeyboardKey.arrowDown;
      await tester.sendKeyEvent(next);
      await tester.pump();
      expect(picked, isNull, reason: 'the arrows move, they do not pick');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked, 1);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  }

  testWidgets('a screen reader hears each place as a tab and where it '
      'stands', (tester) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      _hosted(
        CivicAppShell(
          destinations: _places,
          selectedIndex: 1,
          onDestinationSelected: (_) {},
          child: const CivicScreen(body: Text('Applications')),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('applications'))),
      isSemantics(
        label: 'Applications\nTab 2 of 3',
        isSelected: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets("a place's page has no way back", (tester) async {
    Widget? leading = const SizedBox();
    await _show(
      tester,
      CivicPreview(
        child: Builder(
          builder: (context) {
            leading = CivicTopBar.autoLeading(context);
            return const CivicScreen(body: Text('Home'));
          },
        ),
      ),
    );
    expect(leading, isNull);
  });

  for (final direction in TextDirection.values) {
    testWidgets('a pushed page goes back, its chevron pointing the way the '
        'reader came (${direction.name})', (tester) async {
      final semantics = tester.ensureSemantics();
      await _show(
        tester,
        CivicPreview(
          presentation: CivicPresentation.pushed,
          child: Directionality(
            textDirection: direction,
            child: Builder(
              builder: (context) => CivicScreen(
                topBar: CivicTopBar(
                  title: 'Your permit',
                  leading: CivicTopBar.autoLeading(context, key: _leading),
                ),
                body: const Text('Permit'),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(_leading), findsOneWidget);
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      final flip = tester.widget<Transform>(
        find
            .ancestor(
              of: find.byKey(_leading),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(
        flip.transform.storage[0],
        direction == TextDirection.rtl ? -1 : 1,
      );
      // A preview is looked at, not walked out of: the page stays.
      await tester.tap(find.byKey(_leading));
      await tester.pumpAndSettle();
      expect(find.text('Permit'), findsOneWidget);
      semantics.dispose();
    });
  }

  testWidgets("a raised task's top bar offers its close", (tester) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      CivicPreview(
        presentation: CivicPresentation.sheet,
        child: Builder(
          builder: (context) => CivicScreen(
            topBar: CivicTopBar(
              title: 'Apply for a permit',
              leading: CivicTopBar.autoLeading(context, key: _leading),
            ),
            body: const Text('Question'),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Close'), findsOneWidget);
    semantics.dispose();
  });

  for (final sheet in [false, true]) {
    testWidgets('live, the ${sheet ? 'close' : 'way back'} leaves the '
        '${sheet ? 'task' : 'page'}', (tester) async {
      await _show(tester, _hosted(_Stack(sheet: sheet)));
      expect(find.text('Permit'), findsOneWidget);
      await tester.tap(find.byKey(_leading));
      await tester.pumpAndSettle();
      expect(find.text('Permit'), findsNothing);
      expect(find.text('Your permits'), findsOneWidget);
    });
  }

  testWidgets(
    'under the host a page comes and goes in place, on every platform',
    (tester) async {
      late BuildContext home;
      await _show(
        tester,
        _hosted(
          Builder(
            builder: (context) {
              home = context;
              return const CivicScreen(body: Text('Your permits'));
            },
          ),
        ),
        width: 1440,
        height: 900,
      );
      // A plain route: the host's page change reaches it too.
      unawaited(
        Navigator.of(home).push(
          MaterialPageRoute<void>(
            builder: (_) => const CivicScreen(body: Text('Permit')),
          ),
        ),
      );
      final places = <Offset>{};
      Future<void> watch() async {
        for (var i = 0; i < 18; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          final permit = find.text('Permit');
          if (permit.evaluate().isNotEmpty) {
            places.add(tester.getTopLeft(permit));
          }
        }
      }

      await watch();
      await tester.pumpAndSettle();
      final theme = Theme.of(tester.element(find.text('Permit')));
      for (final platform in TargetPlatform.values) {
        final builder = theme.pageTransitionsTheme.builders[platform];
        // On iOS, Civic's change with the swipe back from the edge round it.
        expect(
          builder is SwipeBackPageTransitionsBuilder
              ? builder.builder
              : builder,
          isA<CivicPageTransitions>(),
          reason: '$platform',
        );
        expect(
          builder is SwipeBackPageTransitionsBuilder,
          platform == TargetPlatform.iOS,
          reason: '$platform',
        );
      }
      places.add(tester.getTopLeft(find.text('Permit')));
      Navigator.of(home).pop();
      await watch();
      await tester.pumpAndSettle();
      expect(find.text('Permit'), findsNothing);
      // Never anywhere but where it stands: nothing travels.
      expect(places, hasLength(1));
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('the page states say what is happening, and the error offers '
      'a retry', (tester) async {
    var retried = 0;
    await _show(
      tester,
      _hosted(
        CivicScreen(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CivicLoadingState(label: 'Loading your permits'),
              CivicErrorState(
                title: 'Sorry, there is a problem with the service',
                message: 'Try again later.',
                onRetry: () => retried++,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Loading your permits'), findsOneWidget);
    expect(find.text('Try again later.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(retried, 1);
  });

  testWidgets('the host leaves the reader\'s text size alone', (tester) async {
    late double scale;
    await _show(
      tester,
      _hosted(
        Builder(
          builder: (context) {
            scale = MediaQuery.textScalerOf(context).scale(10) / 10;
            return const SizedBox();
          },
        ),
      ),
      text: 3,
    );
    expect(scale, 3);
  });

  testWidgets('the plain field asks with its label and says its error', (
    tester,
  ) async {
    String? typed;
    await _show(
      tester,
      _hosted(
        CivicScreen(
          body: CivicInput(
            labelText: 'Vehicle registration number',
            hintText: 'For example, CU57 ABC',
            errorText: 'Enter your vehicle registration number',
            onChanged: (value) => typed = value,
          ),
        ),
      ),
    );
    expect(find.text('Vehicle registration number'), findsOneWidget);
    expect(find.text('For example, CU57 ABC'), findsOneWidget);
    expect(
      find.textContaining('Enter your vehicle registration number'),
      findsWidgets,
    );
    await tester.enterText(find.byType(EditableText), 'BR 12 ABC');
    expect(typed, 'BR 12 ABC');
  });
}

/// A place's page with a page pushed over it, or a task raised over it, on
/// a live navigator: the raised page leaves when the navigator pops it.
class _Stack extends StatefulWidget {
  const _Stack({required this.sheet});

  final bool sheet;

  @override
  State<_Stack> createState() => _StackState();
}

class _StackState extends State<_Stack> {
  static const _raised = ValueKey('raised');
  bool _up = true;

  @override
  Widget build(BuildContext context) {
    final page = Builder(
      builder: (context) => CivicScreen(
        topBar: CivicTopBar(
          title: 'Your permit',
          leading: CivicTopBar.autoLeading(context, key: _leading),
        ),
        body: const Text('Permit'),
      ),
    );
    return Navigator(
      pages: [
        const CivicPage<void>(
          key: ValueKey('place'),
          child: CivicScreen(body: Text('Your permits')),
        ),
        if (_up)
          widget.sheet
              ? CivicSheetPage<void>(key: _raised, child: page)
              : CivicPage<void>(key: _raised, child: page),
      ],
      onDidRemovePage: (removed) {
        if (removed.key == _raised) setState(() => _up = false);
      },
    );
  }
}
