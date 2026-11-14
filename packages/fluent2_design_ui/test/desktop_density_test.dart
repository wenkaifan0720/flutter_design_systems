/// Text entry on a desktop: Material adds
/// `ThemeData.visualDensity` (compact on macOS, Windows and Linux) to any
/// decorated field, so a hint can sit low on a Mac while every test, run as
/// Android, passes. Under macOS, at text scale 1 and 1.5, each
/// text-entry part keeps its hint and its
/// typed words centred in its frame (within half a pixel; a text area's first
/// line keeps its place; a one-line entry and a select's closed face by their capitals), and stands the size it stands under Android's
/// density laid out for a pointer. (Android itself grows a field to the 48
/// touch target, so the reference keeps Android's density and
/// takes a pointer's layout.) And under a host theme whose
/// `InputDecorationTheme` sets padding 20, dense and a 56 least height, on
/// Android, iOS and macOS at both scales, each part stands as it does
/// without it, its words centred (the bare editable).
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart';
import 'package:fluent2_design_ui/src/fluent2_design/internal/cap_label.dart';

void _drop(Object? _) {}

const _sizes = [
  Fluent2Option('s', 'Small'),
  Fluent2Option('m', 'Medium'),
  Fluent2Option('l', 'Large'),
];

/// One text-entry part: [build] it empty (its [hint] shows) or [filled]
/// (holding [words]); [type] writes [words] into it instead. [centred] false
/// for a part whose words sit at the top of a taller frame.
class _Entry {
  const _Entry(
    this.name,
    this.build, {
    required this.words,
    this.hint,
    this.type = true,
    this.centred = true,
    this.capitals = false,
  });

  final String name;
  final Widget Function(bool filled) build;
  final String? hint;
  final String words;
  final bool type;
  final bool centred;

  /// The words are a closed face's, centred by their capitals
  /// ([fluent2CapCentred]): their capitals' middle, as drawn, is held to
  /// the frame's, not their line box's.
  final bool capitals;
}

final _entries = <_Entry>[
  _Entry(
    'text field',
    (_) => const Fluent2TextField(
      label: 'Name',
      hint: 'Your name',
      onChanged: _drop,
    ),
    hint: 'Your name',
    words: 'Ana Ruiz',
    capitals: true,
  ),
  _Entry(
    'text area',
    (_) => const Fluent2TextArea(
      label: 'Notes',
      hint: 'Add a note',
      onChanged: _drop,
    ),
    hint: 'Add a note',
    words: 'Bring the deck',
    centred: false,
  ),
  _Entry(
    'search field',
    (_) => const Fluent2SearchBox(hint: 'Search files', onChanged: _drop),
    hint: 'Search files',
    words: 'budget',
    capitals: true,
  ),
  _Entry(
    'password field',
    (_) => const Fluent2PasswordField(
      label: 'Password',
      hint: 'At least 8 characters',
      onChanged: _drop,
    ),
    hint: 'At least 8 characters',
    words: 'secret12',
    capitals: true,
  ),
  _Entry(
    'input group',
    (_) => const Fluent2InputGroup(
      label: 'Website',
      hint: 'example.com',
      onChanged: _drop,
    ),
    hint: 'example.com',
    words: 'fluent2.dev',
    capitals: true,
  ),
  _Entry(
    'combobox',
    (_) => const Fluent2Combobox<String>(
      label: 'Size',
      hint: 'Type a size',
      value: null,
      options: _sizes,
      onChanged: _drop,
    ),
    hint: 'Type a size',
    words: 'Med',
    capitals: true,
  ),
  _Entry(
    'multi select',
    (_) => Fluent2MultiSelect<String>(
      label: 'Sizes',
      hint: 'Add sizes',
      options: _sizes,
      selected: const [],
      onChanged: _drop,
    ),
    hint: 'Add sizes',
    words: 'Lar',
    capitals: true,
  ),
  _Entry(
    'composer',
    (_) => Fluent2Composer(label: 'Message', hint: 'Message', onSend: _drop),
    hint: 'Message',
    words: 'On my way',
  ),
  _Entry(
    'number field',
    (_) => const Fluent2SpinButton(label: 'Copies', value: 2, onChanged: _drop),
    words: '2',
    type: false,
    capitals: true,
  ),
  _Entry(
    'select',
    (filled) => Fluent2Select<String>(
      label: 'Size',
      prompt: 'Pick a size',
      value: filled ? 'm' : null,
      options: _sizes,
      onChanged: _drop,
    ),
    hint: 'Pick a size',
    words: 'Medium',
    type: false,
    capitals: true,
  ),
];

/// Where [words] stand in their frame: the frame's size and the words'
/// line box's offset from the frame's top and its centre's from the frame's.
typedef _Place = ({Size frame, double top, double off});

Future<void> _pump(WidgetTester tester, Widget part) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          Fluent2Host(brightness: Brightness.light, child: page!),
      home: Material(
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(width: 320, child: part),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

_Place _measure(WidgetTester tester, String words, {bool capitals = false}) {
  final target = find.text(words).first;
  final frame = find
      .ancestor(of: target, matching: find.byType(Fluent2FieldFrame))
      .first;
  final box = tester.getRect(frame);
  var line = tester.getRect(target);
  var middle = line.center.dy;
  if (capitals) {
    // The capitals as drawn (the view's ratio is 1): the line's baseline
    // on a whole pixel, the capitals Selawik's 1434/2048 of the size. The
    // line is the words' own box (a paragraph, or the editable's line) where
    // it is painted, DesignCapCenter's move included.
    RenderBox? words;
    void visit(RenderObject r) {
      if (words != null) return;
      if (r is RenderParagraph || r is RenderEditable) {
        words = r as RenderBox;
        return;
      }
      r.visitChildren(visit);
    }

    visit(tester.renderObject(target));
    final w = words!;
    line = MatrixUtils.transformRect(
      w.getTransformTo(null),
      Offset.zero & w.size,
    );
    final (text, scaler) = switch (w) {
      final RenderEditable e => (e.text!, e.textScaler),
      final RenderParagraph p => (p.text, p.textScaler),
      _ => throw StateError('no words'),
    };
    final size = scaler.scale(text.style?.fontSize ?? 14);
    // Read off a painter of its own: the paragraph's baseline may be asked
    // only while it lays out.
    final painter = TextPainter(
      text: text,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final base = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter.dispose();
    middle =
        (line.top + base.roundToDouble()).roundToDouble() -
        size * fluent2CapHeight / 2;
  }
  return (
    frame: box.size,
    top: line.top - box.top,
    off: middle - box.center.dy,
  );
}

/// [part] as Android's density lays it out for a pointer: Android's theme,
/// a desktop's targets.
Widget _pointer(Widget part) => Builder(
  builder: (context) => Theme(
    data: Theme.of(context).copyWith(platform: TargetPlatform.linux),
    child: part,
  ),
);

/// [part] under a host theme whose `InputDecorationTheme` sizes any
/// decoration it reaches: 20 of
/// padding, dense, 56 least. A bare editable takes none of it.
Widget _hostile(Widget part) => Builder(
  builder: (context) => Theme(
    data: Theme.of(context).copyWith(
      inputDecorationTheme: const InputDecorationThemeData(
        contentPadding: EdgeInsets.all(20),
        isDense: true,
        constraints: BoxConstraints(minHeight: 56),
      ),
    ),
    child: part,
  ),
);

Future<_Place> _shown(
  WidgetTester tester,
  _Entry e, {
  required bool filled,
  required bool reference,
  bool hostile = false,
}) async {
  var part = e.build(filled && !e.type);
  if (reference) part = _pointer(part);
  if (hostile) part = _hostile(part);
  await _pump(tester, part);
  if (filled && e.type) {
    await tester.enterText(find.byType(EditableText).first, e.words);
    await tester.pump(const Duration(milliseconds: 400));
  }
  return _measure(tester, filled ? e.words : e.hint!, capitals: e.capitals);
}

void main() {
  for (final e in _entries) {
    for (final scale in const [1.0, 1.5]) {
      testWidgets('${e.name} at text scale $scale: under macOS its words stand '
          'where Android\'s density puts them, centred, the part its size', (
        tester,
      ) async {
        await _check(tester, e, scale);
      });
      testWidgets('${e.name} at text scale $scale: a host '
          'InputDecorationTheme (padding 20, dense, 56 least) moves nothing '
          'on Android, iOS or macOS', (tester) async {
        await _checkHost(tester, e, scale);
      });
    }
  }
}

Future<void> _checkHost(WidgetTester tester, _Entry e, double scale) async {
  tester.view.physicalSize = const Size(600, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final faults = <String>[];
  try {
    for (final platform in const [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      for (final filled in [if (e.hint != null) false, true]) {
        final what = '${platform.name}, ${filled ? 'typed' : 'hint'}';
        final plain = await _shown(tester, e, filled: filled, reference: false);
        final host = await _shown(
          tester,
          e,
          filled: filled,
          reference: false,
          hostile: true,
        );
        if (host.frame != plain.frame) {
          faults.add(
            '$what: frame ${host.frame} under the host, ${plain.frame}',
          );
        }
        if ((host.top - plain.top).abs() > .5) {
          faults.add('$what: ${host.top} down under the host, ${plain.top}');
        }
        if (e.centred && host.off.abs() > .5) {
          faults.add(
            '$what: centre ${host.off} off the frame\'s under the host',
          );
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
  expect(faults, isEmpty);
}

Future<void> _check(WidgetTester tester, _Entry e, double scale) async {
  tester.view.physicalSize = const Size(600, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final faults = <String>[];
  try {
    for (final filled in [if (e.hint != null) false, true]) {
      final what = filled ? 'typed "${e.words}"' : 'hint';
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final android = await _shown(tester, e, filled: filled, reference: true);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final mac = await _shown(tester, e, filled: filled, reference: false);
      if (mac.frame != android.frame) {
        faults.add('$what: frame ${mac.frame} on macOS, ${android.frame}');
      }
      if ((mac.top - android.top).abs() > .5) {
        faults.add('$what: ${mac.top} down on macOS, ${android.top}');
      }
      if (e.centred && mac.off.abs() > .5) {
        faults.add('$what: centre ${mac.off} off the frame\'s on macOS');
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
  expect(faults, isEmpty);
}
