// A combobox's and a tag input's search, as it takes time and fails: a
// debounce, a loading state a screen reader hears, the latest query's
// result only, and a failure with a way to try again (Down, Enter), the
// focus staying in the field.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/src/internal/option_list.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _fieldKey = ValueKey('field');
const _loadingKey = ValueKey('loading');
const _errorKey = ValueKey('error');

late FocusNode _focus;
DesignSearchError? _error;

// A search the test answers: each query waits on its own completer.
class _Searches {
  final List<String> _all = [];
  final Map<String, Completer<Iterable<String>>> pending = {};

  // The searches for words typed: the field also searches for no words as
  // it takes the focus (every option), which these tests leave pending.
  List<String> get queries => _all.where((q) => q.isNotEmpty).toList();

  Future<Iterable<String>> call(String query) {
    _all.add(query);
    return (pending[query] = Completer<Iterable<String>>()).future;
  }

  void answer(String query, List<String> found) =>
      pending.remove(query)!.complete(found);

  void fail(String query, Object error) =>
      pending.remove(query)!.completeError(error);
}

Widget _field(DesignComboboxField field) {
  _focus = field.focusNode;
  return SizedBox(
    key: _fieldKey,
    width: 200,
    child: EditableText(
      controller: field.controller,
      focusNode: field.focusNode,
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF808080),
      onEditingComplete: field.submit,
    ),
  );
}

Widget _failure(BuildContext context, DesignSearchError error) {
  _error = error;
  return Column(
    key: _errorKey,
    mainAxisSize: MainAxisSize.min,
    children: [
      const ExcludeSemantics(child: Text('Offline')),
      DesignPressable(
        onPressed: error.retry,
        semanticLabel: 'Try again',
        minimumSize: const Size(44, 44),
        builder: (context, states, _) =>
            Text(error.focused ? '[Try again]' : 'Try again'),
      ),
    ],
  );
}

Widget _combobox(
  DesignOptionSearch<String> search, {
  Duration? debounce,
  bool loading = true,
  bool failure = true,
  ValueChanged<String>? onSelected,
}) => DesignCombobox<String>(
  search: search,
  debounceDuration: debounce,
  onSelected: onSelected,
  semanticLabel: 'Fruit',
  loadingBuilder: loading
      ? (context) => const SizedBox(
          key: _loadingKey,
          height: 44,
          child: Text('Looking…'),
        )
      : null,
  errorBuilder: failure ? _failure : null,
  fieldBuilder: (context, field) => _field(field),
  optionBuilder: (context, option, states) => SizedBox(
    height: 44,
    child: Text(states.contains(WidgetState.focused) ? '>$option' : option),
  ),
);

Widget _page(Widget child) => harness(
  Align(
    alignment: Alignment.topCenter,
    child: Padding(padding: const EdgeInsets.only(top: 40), child: child),
  ),
);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump();
}

void main() {
  setUp(() => _error = null);

  group('a debounce', () {
    testWidgets('one search per pause, for the words then', (tester) async {
      final searches = _Searches();
      await tester.pumpWidget(
        _page(
          _combobox(searches.call, debounce: const Duration(milliseconds: 300)),
        ),
      );
      await _type(tester, 'a');
      await tester.pump(const Duration(milliseconds: 100));
      await _type(tester, 'ap');
      await tester.pump(const Duration(milliseconds: 100));
      await _type(tester, 'app');
      await tester.pump(const Duration(milliseconds: 299));
      expect(searches.queries, isEmpty);
      expect(find.byKey(_loadingKey), findsOneWidget, reason: 'it waits');
      await tester.pump(const Duration(milliseconds: 1));
      expect(searches.queries, ['app']);
      searches.answer('app', ['Apple']);
      await tester.pumpAndSettle();
      expect(find.text('>Apple'), findsOneWidget);
    });
  });

  group('loading', () {
    testWidgets('shows while the search runs, and a screen reader hears '
        'Loading; then the options', (tester) async {
      final semantics = tester.ensureSemantics();
      final searches = _Searches();
      await tester.pumpWidget(_page(_combobox(searches.call)));
      await _type(tester, 'pe');
      expect(find.byKey(_loadingKey), findsOneWidget);
      expect(
        semanticsOf(tester, find.byKey(_loadingKey)),
        isSemantics(label: 'Loading', isLiveRegion: true),
      );
      expect(semanticsWords(), isNot(contains('Looking…')));
      searches.answer('pe', ['Pear', 'Peach']);
      await tester.pumpAndSettle();
      expect(find.byKey(_loadingKey), findsNothing);
      expect(find.text('>Pear'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('only the latest words\' options show: an earlier search '
        'that ends late is dropped', (tester) async {
      final searches = _Searches();
      await tester.pumpWidget(_page(_combobox(searches.call)));
      await _type(tester, 'a');
      await _type(tester, 'b');
      searches.answer('b', ['Banana']);
      await tester.pumpAndSettle();
      searches.answer('a', ['Apple']);
      await tester.pumpAndSettle();
      expect(find.text('>Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('>Apple'), findsNothing);
    });

    testWidgets('without a loadingBuilder, the options found last stay '
        'until the new ones come', (tester) async {
      final searches = _Searches();
      await tester.pumpWidget(_page(_combobox(searches.call, loading: false)));
      await _type(tester, 'b');
      searches.answer('b', ['Banana', 'Blueberry']);
      await tester.pumpAndSettle();
      await _type(tester, 'bl');
      expect(find.text('Blueberry'), findsOneWidget);
      searches.answer('bl', ['Blueberry']);
      await tester.pumpAndSettle();
      expect(find.text('>Blueberry'), findsOneWidget);
      expect(find.textContaining('Banana'), findsNothing);
    });

    testWidgets('a search pending when the list closes is dropped; the '
        'list opened again searches again', (tester) async {
      final searches = _Searches();
      await tester.pumpWidget(_page(_combobox(searches.call)));
      await _type(tester, 'ch');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(_loadingKey), findsNothing);
      searches.answer('ch', ['Cherry']);
      await tester.pumpAndSettle();
      expect(find.textContaining('Cherry'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(searches.queries, ['ch', 'ch']);
      searches.answer('ch', ['Cherry']);
      await tester.pumpAndSettle();
      expect(find.text('>Cherry'), findsOneWidget);
    });
  });

  group('a failure', () {
    testWidgets('shows with Try again; a screen reader hears it as it '
        'appears; the focus stays in the field; Down lights Try again and '
        'Enter runs the search again', (tester) async {
      final semantics = tester.ensureSemantics();
      final searches = _Searches();
      await tester.pumpWidget(_page(_combobox(searches.call)));
      await _type(tester, 'fi');
      tester.takeAnnouncements();
      searches.fail('fi', StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.byKey(_errorKey), findsOneWidget);
      expect(_error!.error, isA<StateError>());
      expect(_error!.focused, isFalse);
      expect(_focus.hasFocus, isTrue);
      expect(
        liveRegionWords().any((w) => w.contains("Couldn't load results")) ||
            tester.takeAnnouncements().any(
              (a) => a.message == "Couldn't load results",
            ),
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_error!.focused, isTrue);
      expect(find.text('[Try again]'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(searches.queries, ['fi', 'fi']);
      expect(find.byKey(_loadingKey), findsOneWidget);
      searches.answer('fi', ['Fig']);
      await tester.pumpAndSettle();
      expect(find.text('>Fig'), findsOneWidget);
      expect(_focus.hasFocus, isTrue);
      semantics.dispose();
    });

    testWidgets('a tap on Try again runs it again', (tester) async {
      final searches = _Searches();
      await tester.pumpWidget(_page(_combobox(searches.call)));
      await _type(tester, 'fi');
      searches.fail('fi', StateError('offline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(searches.queries, ['fi', 'fi']);
    });

    testWidgets('Enter in the field, Try again not lit, takes nothing and '
        'retries nothing', (tester) async {
      final searches = _Searches();
      String? taken;
      await tester.pumpWidget(
        _page(_combobox(searches.call, onSelected: (o) => taken = o)),
      );
      await _type(tester, 'fi');
      searches.fail('fi', StateError('offline'));
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(searches.queries, ['fi']);
      expect(taken, isNull);
    });

    testWidgets('without an errorBuilder the list closes and the error is '
        'reported', (tester) async {
      final searches = _Searches();
      await tester.pumpWidget(_page(_combobox(searches.call, failure: false)));
      await _type(tester, 'fi');
      searches.fail('fi', StateError('offline'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isA<StateError>());
      expect(find.byKey(_loadingKey), findsNothing);
      expect(_focus.hasFocus, isTrue);
    });

    testWidgets('with no builders at all, the same: reported, closed', (
      tester,
    ) async {
      final searches = _Searches();
      await tester.pumpWidget(
        _page(_combobox(searches.call, loading: false, failure: false)),
      );
      await _type(tester, 'fi');
      searches.fail('fi', StateError('offline'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isA<StateError>());
      expect(find.byType(DesignOptionList<String>), findsNothing);
    });

    testWidgets('a search that throws at once fails the same way', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(_combobox((query) => throw StateError('no'))),
      );
      await _type(tester, 'x');
      await tester.pumpAndSettle();
      expect(find.byKey(_errorKey), findsOneWidget);
    });
  });

  group('a tag input', () {
    testWidgets('loads, fails, and Enter on Try again searches again '
        'without adding a tag', (tester) async {
      final searches = _Searches();
      var values = <String>[];
      await tester.pumpWidget(
        _page(
          StatefulBuilder(
            builder: (context, setState) => DesignTagInput<String>(
              values: values,
              onChanged: (next) => setState(() => values = next),
              onCreate: (text) => text,
              search: searches.call,
              debounceDuration: const Duration(milliseconds: 200),
              loadingBuilder: (context) => const SizedBox(
                key: _loadingKey,
                height: 44,
                child: Text('Looking…'),
              ),
              errorBuilder: _failure,
              fieldBuilder: (context, field) => _field(field),
              optionBuilder: (context, option, states) =>
                  SizedBox(height: 44, child: Text(option)),
              tagBuilder: (context, value, tag) => Text('tag $value'),
            ),
          ),
        ),
      );
      await _type(tester, 're');
      expect(find.byKey(_loadingKey), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      searches.fail('re', StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.byKey(_errorKey), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(values, isEmpty, reason: 'Try again, not a tag');
      expect(searches.queries, ['re', 're']);
      searches.answer('re', ['red', 'rose']);
      await tester.pumpAndSettle();
      expect(find.text('red'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(values, ['red']);
    });
  });

  testWidgets('its properties', (tester) async {
    final properties = DiagnosticPropertiesBuilder();
    _combobox(
      (q) => const [],
      debounce: const Duration(milliseconds: 250),
    ).debugFillProperties(properties);
    final text = properties.properties.map((p) => p.toString()).join('\n');
    expect(text, contains('debounceDuration: 0:00:00.250000'));
    expect(text, contains('loadingBuilder'));
    expect(text, contains('errorBuilder'));
  });

  behaviourContract(
    'DesignCombobox, a search that failed',
    build: (c) => Align(
      alignment: Alignment.topCenter,
      child: _combobox((query) => throw StateError('offline')),
    ),
    open: (tester) async {
      await tester.tap(find.byKey(_fieldKey));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'fi');
    },
    node: () => find.byType(DesignSearchFailure),
    semantics: isSemantics(label: "Couldn't load results", isLiveRegion: true),
    noDisabledState:
        'a failed search has no disabled state; its field has one, and a '
        'disabled field never searches',
    keyboard: (p) async {
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(_error!.focused, isTrue);
      await p.key(LogicalKeyboardKey.arrowUp);
      expect(_error!.focused, isTrue, reason: 'one row: it stays lit');
      await p.key(LogicalKeyboardKey.escape);
      expect(find.byType(DesignSearchFailure), findsNothing);
      expect(_focus.hasFocus, isTrue);
    },
    motion: (p) async {
      await p.tester.enterText(find.byType(EditableText), 'fig');
    },
  );
}
