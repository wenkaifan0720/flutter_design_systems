// Right to left: every everyday part mirrors. Each part stands at the start of a 480-wide row, once left to right
// and once right to left. A mark inside it (its glyph, its words, its end control) must stand at the mirrored place,
// a glyph that points the reading way must flip, and a slider must run from the reading start.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_ui/fluent2_ui.dart';
import 'package:fluent2_ui/fluent2_host.dart';

const _width = 480.0;

void _noop() {}
void _drop(Object? _) {}

Future<void> _pump(WidgetTester t, Widget part, TextDirection d) async {
  t.view.physicalSize = const Size(_width, 360);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Directionality(
        textDirection: d,
        child: Fluent2Host(brightness: Brightness.light, child: child!),
      ),
      home: Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(
          width: _width,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: part,
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

/// The mark's middle, left to right and right to left.
Future<(double, double)> _middles(
  WidgetTester t,
  Widget part,
  Finder mark,
) async {
  await _pump(t, part, TextDirection.ltr);
  final ltr = t.getCenter(mark.first).dx;
  await _pump(t, part, TextDirection.rtl);
  final rtl = t.getCenter(mark.first).dx;
  return (ltr, rtl);
}

/// Whether the [icon] is drawn flipped (Flutter's matchTextDirection).
bool _flipped(WidgetTester t, IconData icon) => find
    .descendant(of: find.byIcon(icon), matching: find.byType(Transform))
    .evaluate()
    .isNotEmpty;

void main() {
  setUp(
    () =>
        TestWidgetsFlutterBinding.ensureInitialized()
            .platformDispatcher
            .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        ),
  );
  tearDown(
    () => TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  final parts = <(String, Widget, Finder)>[
    (
      'a button: its glyph',
      const Fluent2Button('Send', icon: Fluent2Icons.send, onPressed: _noop),
      find.byIcon(Fluent2Icons.send),
    ),
    (
      'a check box: its label',
      const Fluent2Checkbox(
        value: true,
        label: 'Remember me',
        onChanged: _drop,
      ),
      find.text('Remember me'),
    ),
    (
      'a radio group: its first label',
      const Fluent2RadioGroup<int>(
        options: [Fluent2Radio(1, 'Daily'), Fluent2Radio(2, 'Weekly')],
        value: 1,
        onChanged: _drop,
      ),
      find.text('Daily'),
    ),
    (
      'a switch: its label',
      const Fluent2Switch(
        value: true,
        label: 'Show me as away',
        onChanged: _drop,
      ),
      find.text('Show me as away'),
    ),
    (
      'a text field: its glyph before the words',
      const Fluent2TextField(
        label: 'Search',
        value: 'Northwind',
        onChanged: _drop,
        prefixIcon: Fluent2Icons.search,
      ),
      find.byIcon(Fluent2Icons.search),
    ),
    (
      'a list row: its glyph',
      const Fluent2ListItem(
        icon: Fluent2Icons.document,
        title: 'Q3 plan.docx',
        chevron: true,
        onTap: _noop,
      ),
      find.byIcon(Fluent2Icons.document),
    ),
    (
      'a list row: its chevron',
      const Fluent2ListItem(
        icon: Fluent2Icons.document,
        title: 'Q3 plan.docx',
        chevron: true,
        onTap: _noop,
      ),
      find.byIcon(Fluent2Icons.chevronRight16),
    ),
    (
      'tabs: the first tab',
      const Fluent2TabList(
        tabs: ['Chat', 'Files', 'Notes'],
        selectedIndex: 0,
        onChanged: _drop,
      ),
      find.text('Chat'),
    ),
    (
      'segments: the first segment',
      const Fluent2SegmentedButton<String>(
        label: 'Calendar view',
        segments: [
          Fluent2ButtonSegment('day', 'Day'),
          Fluent2ButtonSegment('week', 'Week'),
        ],
        value: 'day',
        onChanged: _drop,
      ),
      find.text('Day'),
    ),
    (
      'a tag: its dismiss',
      const Fluent2Tag('Launch', onDeleted: _noop),
      find.byIcon(Fluent2Icons.dismiss),
    ),
    (
      'a navigation item: its glyph',
      const Fluent2NavigationDrawerItem(
        icon: Fluent2Icons.folder,
        label: 'Files',
        selected: false,
        onPressed: _noop,
      ),
      find.byIcon(Fluent2Icons.folder),
    ),
  ];

  for (final (name, part, mark) in parts) {
    testWidgets('right to left mirrors $name', (t) async {
      final (ltr, rtl) = await _middles(t, part, mark);
      expect(
        rtl,
        moreOrLessEquals(_width - ltr, epsilon: 1),
        reason: 'left to right at $ltr, right to left at $rtl',
      );
    });
  }

  testWidgets(
    'the host keeps an app\'s right to left where it lends Material\'s words',
    (t) async {
      // A WidgetsApp has no Material words, so the host lends English ones; the
      // locale it lends them under must not turn the app left to right.
      TextDirection? got;
      await t.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, _) => Directionality(
            textDirection: TextDirection.rtl,
            child: Fluent2Host(
              brightness: Brightness.light,
              child: Builder(
                builder: (context) {
                  got = Directionality.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(got, TextDirection.rtl);
    },
  );

  testWidgets('right to left flips the list row\'s chevron', (t) async {
    const row = Fluent2ListItem(title: 'Settings', chevron: true, onTap: _noop);
    await _pump(t, row, TextDirection.ltr);
    expect(_flipped(t, Fluent2Icons.chevronRight16), isFalse);
    await _pump(t, row, TextDirection.rtl);
    expect(_flipped(t, Fluent2Icons.chevronRight16), isTrue);
  });

  testWidgets('right to left an open accordion still points down', (t) async {
    const accordion = SizedBox(
      width: 320,
      child: Fluent2Accordion(
        items: [
          Fluent2AccordionItem(
            value: 'agenda',
            title: 'Agenda',
            child: Text('Roadmap review'),
          ),
        ],
        initiallyExpanded: {'agenda'},
      ),
    );
    for (final d in TextDirection.values) {
      await _pump(t, accordion, d);
      final turn = t
          .widget<AnimatedRotation>(
            find.ancestor(
              of: find.byIcon(Fluent2Icons.chevronRight),
              matching: find.byType(AnimatedRotation),
            ),
          )
          .turns;
      // The glyph points the reading way, so a mirrored one turns the other
      // way round to point down.
      expect(turn, d == TextDirection.ltr ? .25 : -.25, reason: d.name);
    }
  });

  testWidgets('right to left runs a slider from the right', (t) async {
    double? got;
    final slider = StatefulBuilder(
      builder: (context, set) => Fluent2Slider(
        label: 'Volume',
        value: 50,
        onChanged: (v) => set(() => got = v),
      ),
    );
    for (final d in TextDirection.values) {
      got = null;
      await _pump(t, slider, d);
      final box = t.getRect(find.byType(Fluent2Slider));
      // A press near the reading start sets a low value.
      final x = d == TextDirection.ltr ? box.left + 24 : box.right - 24;
      await t.tapAt(Offset(x, box.center.dy));
      await t.pumpAndSettle();
      expect(got, isNotNull, reason: d.name);
      expect(got!, lessThan(20), reason: '${d.name}: $got');
    }
  });
}
