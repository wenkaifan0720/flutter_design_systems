import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

Widget _host(
  Widget child, {
  Brightness brightness = Brightness.light,
  double scale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (BuildContext context, Widget? page) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: Fluent2Host(brightness: brightness, child: page!),
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

/// Sets the test window to [size] logical px for the rest of the test.
void _window(WidgetTester t, Size size) {
  t.view.physicalSize = size * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

SemanticsNode _node(WidgetTester t, String label) =>
    t.getSemantics(find.bySemanticsLabel(label).first);

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

  group('Fluent2Card', () {
    testWidgets('a press on the card fires onTap and it reads as a button', (
      t,
    ) async {
      final s = t.ensureSemantics();
      var taps = 0;
      await t.pumpWidget(
        _host(
          Fluent2Card(
            onPressed: () => taps++,
            label: 'Q3 plan',
            children: const [
              Fluent2CardHeader(header: 'Q3 plan.docx', description: '2h ago'),
              Fluent2CardPreview(height: 80, child: SizedBox.expand()),
              Fluent2CardFooter(children: [Text('Open')]),
            ],
          ),
        ),
      );
      await t.tap(find.text('Q3 plan.docx'));
      expect(taps, 1);
      expect(
        _node(t, 'Q3 plan'),
        isSemantics(isButton: true, hasTapAction: true),
      );
      s.dispose();
    });

    testWidgets('a selectable card asks for the other state; without a '
        'handler it is inert', (t) async {
      bool? asked;
      await t.pumpWidget(
        _host(
          Fluent2Card(
            selected: false,
            onSelected: (v) => asked = v,
            children: const [Fluent2CardHeader(header: 'Offsite photos')],
          ),
        ),
      );
      await t.tap(find.text('Offsite photos'));
      expect(asked, isTrue);

      asked = null;
      await t.pumpWidget(
        _host(
          const Fluent2Card(
            selected: true,
            children: [Fluent2CardHeader(header: 'Offsite photos')],
          ),
        ),
      );
      await t.tap(find.text('Offsite photos'), warnIfMissed: false);
      expect(asked, isNull);
    });
  });

  group('Fluent2ListItem and Fluent2ListGroup', () {
    testWidgets('a row fires onTap and stands 44 tall on a phone', (t) async {
      _window(t, const Size(390, 844));
      var taps = 0;
      await t.pumpWidget(
        _host(
          Fluent2ListItem(
            icon: Fluent2Icons.document,
            title: 'Q3 plan.docx',
            onTap: () => taps++,
          ),
        ),
      );
      await t.tap(find.text('Q3 plan.docx'));
      expect(taps, 1);
      expect(
        t.getSize(find.byType(Fluent2ListItem)).height,
        greaterThanOrEqualTo(44),
      );
    });

    testWidgets('a checked row toggles; a disabled row is inert', (t) async {
      final s = t.ensureSemantics();
      bool? asked;
      var taps = 0;
      await t.pumpWidget(
        _host(
          Fluent2ListGroup(
            title: 'Checklist',
            children: [
              Fluent2ListItem(
                title: 'Book the room',
                checked: false,
                onChanged: (v) => asked = v,
              ),
              Fluent2ListItem(
                title: 'Archived',
                enabled: false,
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      );
      await t.tap(find.text('Book the room'));
      expect(asked, isTrue);
      await t.tap(find.text('Archived'), warnIfMissed: false);
      expect(taps, 0);
      expect(_node(t, 'Checklist'), isSemantics(isHeader: true));
      s.dispose();
    });

    testWidgets("a section header's link fires", (t) async {
      var taps = 0;
      await t.pumpWidget(
        _host(
          Fluent2SectionHeader(
            'Meetings today',
            aside: '3',
            action: Fluent2SectionHeader.link(
              'See all',
              onPressed: () => taps++,
            ),
          ),
        ),
      );
      await t.tap(find.text('See all'));
      expect(taps, 1);
    });
  });

  group('Fluent2TabList', () {
    testWidgets('a tab asks for its index; a disabled tab is inert', (t) async {
      final s = t.ensureSemantics();
      final asked = <int>[];
      await t.pumpWidget(
        _host(
          Fluent2TabList.items(
            selectedIndex: 0,
            onChanged: asked.add,
            items: const [
              Fluent2Tab('Posts'),
              Fluent2Tab('Files'),
              Fluent2Tab('Wiki', enabled: false),
            ],
          ),
        ),
      );
      // A tab lays its words twice (the bold copy reserves the width).
      await t.tap(find.text('Files').first);
      await t.tap(find.text('Wiki').first, warnIfMissed: false);
      expect(asked, [1]);
      expect(_node(t, 'Posts'), isSemantics(isSelected: true));
      s.dispose();
    });

    testWidgets('many tabs scroll instead of overflowing a phone', (t) async {
      _window(t, const Size(390, 844));
      await t.pumpWidget(
        _host(
          Fluent2TabList(
            selectedIndex: 0,
            onChanged: (_) {},
            tabs: [for (var i = 0; i < 9; i++) 'Section $i'],
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.byType(Scrollable), findsWidgets);
    });
  });

  group('Fluent2Breadcrumb', () {
    testWidgets('an item fires; the current page reads as current', (t) async {
      final s = t.ensureSemantics();
      var taps = 0;
      await t.pumpWidget(
        _host(
          Fluent2Breadcrumb(
            items: [
              Fluent2BreadcrumbItem('Northwind', onPressed: () => taps++),
              const Fluent2BreadcrumbItem('Design'),
            ],
          ),
        ),
      );
      await t.tap(find.text('Northwind'));
      expect(taps, 1);
      expect(find.bySemanticsLabel('Design, current page'), findsOneWidget);
      s.dispose();
    });

    testWidgets('past maxDisplayedItems the middle folds into a menu', (
      t,
    ) async {
      final s = t.ensureSemantics();
      await t.pumpWidget(
        _host(
          Fluent2Breadcrumb(
            maxDisplayedItems: 3,
            items: [
              for (final name in ['A', 'B', 'C', 'D'])
                Fluent2BreadcrumbItem(name, onPressed: () {}),
              const Fluent2BreadcrumbItem('Here'),
            ],
          ),
        ),
      );
      expect(find.text('B'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^More places')), findsWidgets);
      s.dispose();
    });
  });

  group('Fluent2Toolbar and Fluent2Divider', () {
    testWidgets('a command fires and a toggle asks for the other state', (
      t,
    ) async {
      var taps = 0;
      bool? asked;
      await t.pumpWidget(
        _host(
          Fluent2Toolbar(
            items: [
              Fluent2ToolbarItem.button(
                icon: Fluent2Icons.add,
                label: 'New',
                showLabel: true,
                onPressed: () => taps++,
              ),
              const Fluent2ToolbarItem.divider(),
              Fluent2ToolbarItem.toggle(
                icon: Fluent2Icons.pin,
                label: 'Pin',
                showLabel: true,
                checked: false,
                onChanged: (v) => asked = v,
              ),
            ],
          ),
        ),
      );
      await t.tap(find.text('New'));
      await t.tap(find.text('Pin'));
      expect(taps, 1);
      expect(asked, isTrue);
    });

    testWidgets('a divider draws its label and stands vertical', (t) async {
      await t.pumpWidget(
        _host(
          const Column(
            children: [
              Fluent2Divider(label: 'Yesterday'),
              SizedBox(
                height: 40,
                child: Row(children: [Fluent2Divider(vertical: true)]),
              ),
            ],
          ),
        ),
      );
      expect(find.text('Yesterday'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('Fluent2Accordion', () {
    testWidgets('a header opens its panel; a disabled one stays shut', (
      t,
    ) async {
      final s = t.ensureSemantics();
      final toggled = <Object>[];
      await t.pumpWidget(
        _host(
          Fluent2Accordion(
            onExpansionChanged: (v, _) => toggled.add(v),
            items: const [
              Fluent2AccordionItem(
                value: 'agenda',
                title: 'Agenda',
                child: Text('Roadmap review'),
              ),
              Fluent2AccordionItem(
                value: 'notes',
                title: 'Notes',
                enabled: false,
                child: Text('Shared later'),
              ),
            ],
          ),
        ),
      );
      expect(find.text('Roadmap review'), findsNothing);
      await t.tap(find.text('Agenda'));
      await t.pumpAndSettle();
      expect(find.text('Roadmap review'), findsOneWidget);
      expect(_node(t, 'Agenda'), isSemantics(isExpanded: true));
      await t.tap(find.text('Notes'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(find.text('Shared later'), findsNothing);
      expect(toggled, ['agenda']);
      s.dispose();
    });
  });

  group('Fluent2Table', () {
    testWidgets('a header sorts, a row check selects, a row fires', (t) async {
      _window(t, const Size(1280, 800));
      int? sorted;
      Set<int>? selection;
      var opened = 0;
      await t.pumpWidget(
        _host(
          Fluent2Table(
            columns: const [
              Fluent2TableColumn('Name', sortable: true),
              Fluent2TableColumn('Owner'),
            ],
            onSort: (i) => sorted = i,
            selected: const {},
            onSelectionChanged: (s) => selection = s,
            rows: [
              Fluent2TableRow(
                onPressed: () => opened++,
                cells: const [
                  Fluent2TableCell('Q3 plan.docx'),
                  Fluent2TableCell('Kai Tanaka'),
                ],
              ),
              const Fluent2TableRow(
                cells: [
                  Fluent2TableCell('Roadmap.pptx'),
                  Fluent2TableCell('Ines Duarte'),
                ],
              ),
            ],
          ),
        ),
      );
      await t.tap(find.text('Name'));
      expect(sorted, 0);
      await t.tap(find.bySemanticsLabel('Select Roadmap.pptx'));
      expect(selection, {1});
      await t.tap(find.bySemanticsLabel('Select all rows'));
      expect(selection, {0, 1});
      await t.tap(find.text('Kai Tanaka'));
      expect(opened, 1);
    });

    testWidgets('scrolls sideways rather than overflowing a phone', (t) async {
      _window(t, const Size(390, 844));
      await t.pumpWidget(
        _host(
          const Fluent2Table(
            columns: [
              Fluent2TableColumn('Name', minWidth: 180),
              Fluent2TableColumn('Owner', minWidth: 160),
              Fluent2TableColumn('Modified', minWidth: 140),
            ],
            rows: [
              Fluent2TableRow(
                cells: [
                  Fluent2TableCell('Q3 plan.docx'),
                  Fluent2TableCell('Kai Tanaka'),
                  Fluent2TableCell('2h ago'),
                ],
              ),
            ],
          ),
        ),
      );
      expect(t.takeException(), isNull);
    });
  });

  group('Fluent2Tree', () {
    testWidgets('a branch opens and a leaf asks to be chosen', (t) async {
      final chosen = <String>[];
      await t.pumpWidget(
        _host(
          Fluent2Tree<String>(
            onChanged: chosen.add,
            items: const [
              Fluent2TreeItem(
                'design',
                'Design',
                children: [Fluent2TreeItem('brand', 'Brand guidelines.pdf')],
              ),
            ],
          ),
        ),
      );
      expect(find.text('Brand guidelines.pdf'), findsNothing);
      await t.tap(find.text('Design'));
      await t.pumpAndSettle();
      await t.tap(find.text('Brand guidelines.pdf'));
      expect(chosen, contains('brand'));
    });

    testWidgets('the keyboard opens a branch, walks down and chooses', (
      t,
    ) async {
      final chosen = <String>[];
      await t.pumpWidget(
        _host(
          Fluent2Tree<String>(
            onChanged: chosen.add,
            items: const [
              Fluent2TreeItem(
                'design',
                'Design',
                children: [Fluent2TreeItem('brand', 'Brand guidelines.pdf')],
              ),
            ],
          ),
        ),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pumpAndSettle();
      expect(find.text('Brand guidelines.pdf'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(chosen, ['brand']);
    });
  });

  group('Fluent2Image and Fluent2DescriptionList', () {
    testWidgets('an image without a picture draws the placeholder at its '
        'size and says its label', (t) async {
      final s = t.ensureSemantics();
      await t.pumpWidget(
        _host(
          const Align(
            alignment: Alignment.topLeft,
            child: Fluent2Image(
              width: 120,
              aspectRatio: 4 / 3,
              semanticLabel: 'Team photo',
            ),
          ),
        ),
      );
      expect(t.getSize(find.byType(Fluent2Image)), const Size(120, 90));
      expect(_node(t, 'Team photo'), isSemantics(isImage: true));
      s.dispose();
    });

    testWidgets('properties read as label and value', (t) async {
      final s = t.ensureSemantics();
      await t.pumpWidget(
        _host(
          const Fluent2DescriptionList(
            title: 'Details',
            properties: [
              Fluent2DescriptionItem('Owner', 'Kai Tanaka'),
              Fluent2DescriptionItem('Size', '2.4 MB'),
            ],
          ),
        ),
      );
      expect(find.text('Kai Tanaka'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Owner')), findsWidgets);
      s.dispose();
    });
  });

  group('Fluent2BottomActionBar', () {
    testWidgets('both acts fire', (t) async {
      final heard = <String>[];
      await t.pumpWidget(
        _host(
          Fluent2BottomActionBar(
            primaryLabel: 'Send invite',
            onPrimaryPressed: () => heard.add('send'),
            secondaryLabel: 'Cancel',
            onSecondaryPressed: () => heard.add('cancel'),
          ),
        ),
      );
      await t.tap(find.text('Send invite'));
      await t.tap(find.text('Cancel'));
      expect(heard, ['send', 'cancel']);
    });
  });

  group('Fluent2SwipeActions', () {
    testWidgets('each act is a custom action; an open pane does its act', (
      t,
    ) async {
      final s = t.ensureSemantics();
      final heard = <String>[];
      await t.pumpWidget(
        _host(
          Fluent2SwipeActions(
            initiallyOpen: true,
            trailing: [
              Fluent2SwipeAction(
                label: 'Delete',
                icon: Fluent2Icons.delete,
                tone: Fluent2Tone.danger,
                onPressed: () => heard.add('delete'),
              ),
            ],
            child: const SizedBox(
              height: 56,
              width: double.infinity,
              child: Text('Kai Tanaka'),
            ),
          ),
        ),
      );
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();
      expect(heard, ['delete']);
      expect(find.text('Delete'), findsNothing);

      // The row's words and its acts are one node.
      final node = t.getSemantics(find.text('Kai Tanaka'));
      final labels = [
        for (final id
            in node.getSemanticsData().customSemanticsActionIds ??
                const <int>[])
          CustomSemanticsAction.getAction(id)?.label,
      ];
      expect(labels, contains('Delete'));
      s.dispose();
    });

    testWidgets('a drag past half the pane opens the leading edge', (t) async {
      await t.pumpWidget(
        _host(
          Fluent2SwipeActions(
            leading: [
              Fluent2SwipeAction(
                label: 'Archive',
                icon: Fluent2Icons.archive,
                tone: Fluent2Tone.success,
                onPressed: () {},
              ),
            ],
            child: const SizedBox(
              height: 56,
              width: double.infinity,
              child: Text('Mara Okafor'),
            ),
          ),
        ),
      );
      expect(find.text('Archive'), findsNothing);
      await t.drag(find.text('Mara Okafor'), const Offset(72, 0));
      await t.pumpAndSettle();
      expect(find.text('Archive'), findsOneWidget);
    });
  });

  group('Fluent2ListSection', () {
    testWidgets('a list section heads its rows', (t) async {
      final s = t.ensureSemantics();
      var taps = 0;
      await t.pumpWidget(
        _host(
          Fluent2ListSection(
            title: 'Recent files',
            aside: '1',
            rows: [Fluent2ListItem(title: 'Q3 plan.docx', onTap: () => taps++)],
          ),
        ),
      );
      expect(
        t.getSemantics(find.bySemanticsLabel(RegExp('^Recent files'))),
        isSemantics(isHeader: true),
      );
      await t.tap(find.text('Q3 plan.docx'));
      expect(taps, 1);
      s.dispose();
    });
  });

  testWidgets('nothing overflows at 390 wide at text scale 1.3, light or '
      'dark', (t) async {
    _window(t, const Size(390, 844));
    for (final b in Brightness.values) {
      await t.pumpWidget(
        _host(
          brightness: b,
          scale: 1.3,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Fluent2ListSection(
                title: 'Files shared with the Northwind product team',
                aside: '128',
                action: Fluent2SectionHeader.link('See all', onPressed: () {}),
                rows: [
                  Fluent2ListItem(
                    title: 'Quarterly planning document for the team.docx',
                    onTap: () {},
                  ),
                ],
              ),
              Fluent2ListItem(
                icon: Fluent2Icons.document,
                title: 'Brand guidelines for every Northwind product.pdf',
                subtitle: 'Mara Okafor edited yesterday afternoon',
                value: '8.1 MB',
                chevron: true,
                onTap: () {},
              ),
              Fluent2Card(
                onPressed: () {},
                children: const [
                  Fluent2CardHeader(
                    header: 'Mara Okafor mentioned you in a comment',
                    description: 'Brand guidelines.pdf · 5 minutes ago',
                  ),
                ],
              ),
              Fluent2Breadcrumb(
                items: [
                  Fluent2BreadcrumbItem('Northwind', onPressed: () {}),
                  Fluent2BreadcrumbItem('Shared documents', onPressed: () {}),
                  const Fluent2BreadcrumbItem('Brand guidelines.pdf'),
                ],
              ),
              Fluent2BottomActionBar(
                summary: '3 files selected for sharing',
                primaryLabel: 'Share with the team',
                onPrimaryPressed: () {},
                secondaryLabel: 'Download all',
                onSecondaryPressed: () {},
              ),
              const Fluent2DescriptionList(
                properties: [
                  Fluent2DescriptionItem(
                    'Location',
                    'Northwind / Planning / Q3',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      expect(t.takeException(), isNull);
    }
  });
}
