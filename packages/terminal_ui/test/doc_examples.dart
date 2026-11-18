/// Compiled doc examples, for any package: each `/// Example:` line and each
/// fenced dart block in its lib is written out in a test file as the body of
/// an entry, so an example that stops compiling fails analysis, and
/// [testDocExamples] checks that none is missing and runs each one.
///
/// A look copies this file into its own `test/` beside a
/// `doc_examples_test.dart` of its own:
///
/// ```dart
/// void main() {
///   testDocExamples(
///     self: 'test/doc_examples_test.dart',
///     examples: {
///       'ComicButton': (context) =>
///           ComicButton(onPressed: () {}, child: const Text('Save')),
///     },
///     wrap: (child) => ComicApp(home: child),
///   );
/// }
/// ```
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// One doc example, as its entry writes it: a widget to show, a route to
/// push, or a call to run.
typedef DocExample = Object? Function(BuildContext context);

/// Tests [examples], the doc examples of the package's [lib] written out in
/// [self]: one test that every example in [lib] (files named in [skip]
/// aside) is written out in [self], layout aside, and one per entry that
/// builds it in [wrap] at [size] (pushing it when it is a route) without an
/// exception.
void testDocExamples({
  required String self,
  required Map<String, DocExample> examples,
  required Widget Function(Widget child) wrap,
  Set<String> skip = const {},
  String lib = 'lib',
  Size size = const Size(480, 480),
}) {
  test('every example in $lib is compiled here', () {
    final here = bareCode(File(self).readAsStringSync());
    final found = libExamples(lib, skip: skip);
    expect(found, isNotEmpty);
    expect(
      [
        for (final example in found)
          if (!here.contains(bareCode(example))) example,
      ],
      isEmpty,
      reason: 'each example in $lib is written out in $self',
    );
  });

  for (final MapEntry(key: name, value: example) in examples.entries) {
    testWidgets('$name\'s example runs', (tester) async {
      await tester.pumpWidget(
        wrap(
          Center(
            child: SizedBox.fromSize(size: size, child: _Once(example)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _finish(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

/// The futures the examples returned (an async call, as loading the faces),
/// not yet seen to their end.
final List<Future<Object?>> _running = [];

/// Lets each async example run to its end, then draws the frames its end
/// asked for, so nothing is left scheduled when the tree goes: a font
/// loaded tells the fonts changed, and from Flutter 3.50 the text's relayout
/// waits for the next frame.
Future<void> _finish(WidgetTester tester) async {
  if (_running.isEmpty) return;
  var done = false;
  (Object, StackTrace)? failed;
  Future.wait(_running.toList())
      .then<void>(
        (_) => done = true,
        onError: (Object error, StackTrace stack) {
          failed = (error, stack);
          done = true;
        },
      )
      .ignore();
  _running.clear();
  // The example's own work happens outside the test's fake clock (a font
  // is read by the engine): let real time pass, a little at a time.
  for (var i = 0; i < 200 && !done; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
  }
  final (error, stack) = failed ?? (null, null);
  if (error != null) Error.throwWithStackTrace(error, stack!);
  expect(done, isTrue, reason: 'an async example never ended');
  // The message the end sent, then the frame it scheduled.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// [code] with its layout gone: no whitespace, no trailing comma, and no
/// `const`, which `prefer_const_constructors` moves outward in the test file
/// (`const A(child: B())` there for `A(child: const B())` in the doc).
String bareCode(String code) => code
    .replaceAll(RegExp(r'\bconst\s+'), '')
    .replaceAll(RegExp(r'\s+'), '')
    .replaceAll(RegExp(r',(?=[)\]}])'), '');

/// Each example in [lib]: a `/// Example:` line, or a fenced dart block; files
/// named in [skip] aside.
List<String> libExamples(String lib, {Set<String> skip = const {}}) {
  final out = <String>[];
  final files = Directory(lib).listSync(recursive: true).whereType<File>();
  for (final file in files) {
    if (!file.path.endsWith('.dart')) continue;
    if (skip.contains(file.uri.pathSegments.last)) continue;
    final lines = file.readAsLinesSync().map((l) => l.trim()).toList();
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('/// Example: ')) {
        out.add(lines[i].substring('/// Example: '.length));
      } else if (lines[i] == '/// ```dart') {
        final code = <String>[];
        while (lines[++i] != '/// ```') {
          code.add(lines[i].replaceFirst(RegExp(r'^///'), ''));
        }
        out.add(code.join('\n'));
      }
    }
  }
  return out;
}

/// Runs [example] once, in the tree, and shows it when it is a widget.
class _Once extends StatefulWidget {
  const _Once(this.example);

  final DocExample example;

  @override
  State<_Once> createState() => _OnceState();
}

class _OnceState extends State<_Once> {
  Object? _made;
  bool _ran = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ran) return;
    _ran = true;
    _made = widget.example(context);
    final made = _made;
    if (made is Future<Object?>) _running.add(made);
    if (made is Route<void>) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).push(made).ignore();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final made = _made;
    return made is Widget ? made : const SizedBox();
  }
}
