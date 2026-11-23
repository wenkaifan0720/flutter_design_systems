// A text field on a route of a Navigator set in StudioScaffold's body keeps
// its place in the semantics tree when a list opens over the route, as it
// does on the app's own navigator. Were the route's node made only when the
// list opened, the web would move the field's input into that node and the
// browser would blur it: a combobox would take two taps on a phone.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

const _shows = ['Night Desk', 'Field Notes', 'Room Tone'];

// The ids of the semantics nodes from the root down to the text field.
List<int> _path() {
  final root = RendererBinding
      .instance
      .renderViews
      .first
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  List<int>? found;
  bool walk(SemanticsNode node, List<int> above) {
    final here = [...above, node.id];
    if (node.getSemanticsData().flagsCollection.isTextField) {
      found = here;
      return false;
    }
    var more = true;
    node.visitChildren((child) => more = more && walk(child, here));
    return more;
  }

  walk(root, const []);
  return found!;
}

Route<void> _page(WidgetBuilder builder) =>
    PageRouteBuilder<void>(pageBuilder: (context, _, _) => builder(context));

// The navigator's first page, which pushes the page with the combobox, as an
// app opens a task over its list.
class _List extends StatefulWidget {
  const _List();

  @override
  State<_List> createState() => _ListState();
}

class _ListState extends State<_List> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Navigator.of(context).push(
        _page(
          (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: 320,
                child: StudioCombobox<String>(
                  labelText: 'Show',
                  options: _shows,
                  labelOf: (s) => s,
                  value: null,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const Text('Episodes');
}

void main() {
  for (final width in const [390.0, 1440.0]) {
    testWidgets('at $width a combobox opened over a route of a navigator in '
        "StudioScaffold's body keeps its field's node and its focus", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, app) => StudioHost(child: app!),
          home: StudioScaffold(
            body: Navigator(
              onGenerateRoute: (_) => _page((_) => const _List()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final before = _path();
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Room Tone'),
        findsOneWidget,
        reason: 'the list is open',
      );
      expect(_path(), before);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      semantics.dispose();
    });
  }
}
