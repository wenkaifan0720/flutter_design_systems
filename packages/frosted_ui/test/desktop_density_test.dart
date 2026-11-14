// Frosted's text-entry parts under every configuration that could move a
// line. Left to itself, Material gives a ThemeData on macOS, Windows and
// Linux (and a web build opened on one) compact visual density, which takes
// 8 px off a decorated field and 4 off its baseline; and a host's
// InputDecorationTheme fills whatever a decoration leaves unset (an unpinned
// InputDecoration.collapsed takes its constraints). The other tests run as
// Android under Frosted's own theme, so none of them would see either.
// Frosted's own density is pinned to standard here (its platform default,
// compact on a desktop, is the look's choice, not a leak). Frosted pins
// standard density under its theme, and every text entry's
// decoration sets every field that sizes it (each entry's _bareDecoration,
// design6 I3). As Android, iOS and macOS, with and without a host
// InputDecorationTheme of padding 20, isDense and a 56 minimum height
// around the part, each part stands the size it does as Android under no
// host theme, its hint and typed words stand where they do there, and on a
// one-line part they are centred on the part's box within half a pixel; at
// text scale 1 and 1.5 (a box is at least its height and grows with larger
// text).
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';
import 'package:frosted_ui/src/frosted/internal/well.dart';

/// Frosted at standard density whatever the platform.
final FrostedThemeData _standard = FrostedThemeData(
  density: FrostedDensity.standard,
);

/// [_standard] by night.
final FrostedThemeData _standardDark = FrostedThemeData(
  brightness: Brightness.dark,
  density: FrostedDensity.standard,
);

const _part = ValueKey('part');

void _drop(Object? _) {}

/// One text-entry part: how to build it, the box its words stand in, the
/// [hint] it shows while empty, what to [type] into it, and where the words
/// then stand ([words]; the editable's own line when null).
class _Case {
  const _Case(
    this.name,
    this.build,
    this.box, {
    this.hint,
    this.type,
    this.words,
  });

  final String name;
  final Widget Function() build;
  final Finder Function() box;
  final String? hint;
  final String? type;
  final Finder Function()? words;
}

Finder _editable() => find.byType(EditableText).first;

Finder _wellOf(Finder of) =>
    find.ancestor(of: of, matching: find.byType(FrostedWell)).first;

Finder _faceOf(Finder of) =>
    find.ancestor(of: of, matching: find.byType(FrostedFace)).first;

/// A one-time code's drawn figure (the real input under the boxes holds
/// the same text).
Finder _figure(String figure) =>
    find.byWidgetPredicate((w) => w is Text && w.data == figure);

/// What one platform's pump measured, in the view's pixels.
class _Shot {
  const _Shot(this.part, this.box, this.hint, this.hintBox, this.words);

  final Size part;
  final Rect box;
  final Rect? hint;

  /// The box while the hint showed, before typing.
  final Rect? hintBox;
  final Rect? words;
}

/// The editable's line: its own box, as tall as one line of its words.
Rect _line(WidgetTester t) {
  final editable = t.state<EditableTextState>(_editable()).renderEditable;
  return editable.localToGlobal(Offset.zero) & editable.size;
}

/// A host's field theme that would move a line it reached: padding 20,
/// dense, at least 56 tall.
const _hostFields = InputDecorationThemeData(
  contentPadding: EdgeInsets.all(20),
  isDense: true,
  constraints: BoxConstraints(minHeight: 56),
);

Future<_Shot> _shoot(
  WidgetTester t,
  _Case c,
  TargetPlatform platform, {
  bool host = false,
}) async {
  debugDefaultTargetPlatformOverride = platform;
  // A fresh tree per configuration: nothing kept from the last one.
  await t.pumpWidget(const SizedBox.shrink());
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? page) =>
          FrostedHost(light: _standard, dark: _standardDark, child: page!),
      home: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeyedSubtree(
              key: _part,
              child: host
                  ? Builder(
                      builder: (context) => Theme(
                        data: Theme.of(context)
                            .copyWith(inputDecorationTheme: _hostFields),
                        child: c.build(),
                      ),
                    )
                  : c.build(),
            ),
          ],
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
  expect(Theme.of(t.element(find.byKey(_part))).platform, platform);
  final part = t.getSize(find.byKey(_part));
  final hint = c.hint == null ? null : t.getRect(find.text(c.hint!).first);
  // Typing can move or grow the box (a palette's matches shrink and the
  // column centres it again; a composer shows its send): the hint is read
  // against the box it stood in.
  final hintBox = hint == null ? null : t.getRect(c.box());
  if (c.type case final words?) {
    await t.enterText(_editable(), words);
    await t.pumpAndSettle();
  }
  final words = c.words != null
      ? t.getRect(c.words!())
      : (c.type == null ? null : _line(t));
  return _Shot(part, t.getRect(c.box()), hint, hintBox, words);
}

final _cases = <_Case>[
  _Case(
    'Text field',
    () => const FrostedTextField(
      label: 'Name',
      hint: 'What are you saving for?',
      onChanged: _drop,
    ),
    () => _wellOf(_editable()),
    hint: 'What are you saving for?',
    type: 'A new bike',
  ),
  _Case(
    'Password field',
    () => const FrostedPasswordField(
      label: 'Password',
      hint: 'At least 8 characters',
      onChanged: _drop,
    ),
    () => _wellOf(_editable()),
    hint: 'At least 8 characters',
    type: 'hunter22',
  ),
  _Case(
    'Text area',
    () => const FrostedTextArea(
      label: 'Notes',
      hint: 'Anything the team should know',
      onChanged: _drop,
    ),
    () => _wellOf(_editable()),
    hint: 'Anything the team should know',
    type: 'Bring the keys',
  ),
  _Case(
    'Search field',
    () => const FrostedSearchField(hint: 'Search activity', onChanged: _drop),
    () => _faceOf(_editable()),
    hint: 'Search activity',
    type: 'coffee',
  ),
  _Case(
    'Input group',
    () => const FrostedInputGroup(
      label: 'Website',
      prefix: Text('https://'),
      suffix: Text('.com'),
      hint: 'example',
      onChanged: _drop,
    ),
    () => _wellOf(_editable()),
    hint: 'example',
    type: 'frosted',
  ),
  _Case(
    'Combobox',
    () => const FrostedCombobox<String>(
      label: 'Fruit',
      options: ['Apple', 'Banana', 'Cherry'],
      hint: 'Pick a fruit',
      onSelected: _drop,
    ),
    () => _wellOf(_editable()),
    hint: 'Pick a fruit',
    type: 'Ban',
  ),
  _Case(
    'Multi-select',
    () => const FrostedMultiSelect<String>(
      label: 'Tags',
      values: [],
      options: ['Home', 'Work', 'Travel'],
      hint: 'Add a tag',
      onChanged: _drop,
    ),
    () => _wellOf(_editable()),
    hint: 'Add a tag',
    type: 'Wo',
  ),
  _Case(
    'Composer',
    () => const FrostedComposer(hint: 'Message', onSend: _drop),
    () => _faceOf(_editable()),
    hint: 'Message',
    type: 'See you at eight',
  ),
  _Case(
    'Composer, assistant',
    () => const FrostedComposer(
      hint: 'Ask anything',
      onSend: _drop,
      variant: FrostedComposerVariant.assistant,
    ),
    () => _faceOf(_editable()),
    hint: 'Ask anything',
    type: 'Plan a week of dinners',
  ),
  _Case(
    'One-time code',
    () => const FrostedInputOtp(label: 'Code from your text'),
    () => _faceOf(_figure('4')),
    type: '4',
    words: () => _figure('4'),
  ),
  _Case(
    'Number field',
    () =>
        const FrostedNumberField(value: 40, onChanged: _drop, label: 'Budget'),
    () => _wellOf(_editable()),
    type: '45',
  ),
  _Case(
    'Amount field',
    () => const FrostedAmountField(label: 'Amount', onChanged: _drop),
    () => _wellOf(_editable()),
    hint: '0',
    type: '250',
  ),
  _Case(
    'Amount field, small',
    () => const FrostedAmountField(
      label: 'Target',
      size: FrostedAmountFieldSize.small,
      onChanged: _drop,
    ),
    () => _wellOf(_editable()),
    hint: '0',
    type: '250',
  ),
  _Case(
    "Select's field, its prompt",
    () => const FrostedSelect<String>(
      label: 'Room',
      prompt: 'Pick a room',
      options: [
        FrostedSelectOption('k', 'Kitchen'),
        FrostedSelectOption('s', 'Study'),
      ],
      onChanged: _drop,
    ),
    () => _wellOf(find.text('Pick a room')),
    hint: 'Pick a room',
  ),
  _Case(
    "Select's field, its choice",
    () => const FrostedSelect<String>(
      label: 'Room',
      value: 'k',
      options: [
        FrostedSelectOption('k', 'Kitchen'),
        FrostedSelectOption('s', 'Study'),
      ],
      onChanged: _drop,
    ),
    () => _wellOf(find.text('Kitchen')),
    words: () => find.text('Kitchen'),
  ),
  _Case(
    "Command palette's field",
    () => const FrostedCommand(
      hint: 'Type a command',
      commands: [
        DesignCommand(label: 'New payment', group: 'Money'),
        DesignCommand(label: 'Settings'),
      ],
    ),
    () => find
        .ancestor(
          of: _editable(),
          matching: find.byWidgetPredicate(
            (w) =>
                w is ConstrainedBox &&
                w.constraints.minHeight == FrostedChromeMetrics.field,
          ),
        )
        .first,
    hint: 'Type a command',
    type: 'Set',
  ),
];

void main() {
  for (final (scale, c) in [
    for (final scale in [1.0, 1.5])
      for (final c in _cases) (scale, c),
  ]) {
    testWidgets(
      '${c.name} as Android, iOS and macOS, under a host field theme or '
      'none, stands as on Android under none, its words where they stand '
      'there (text scale $scale)',
      (WidgetTester t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        late final _Shot android;
        final shots = <String, _Shot>{};
        try {
          android = await _shoot(t, c, TargetPlatform.android);
          for (final platform in [
            TargetPlatform.android,
            TargetPlatform.iOS,
            TargetPlatform.macOS,
          ]) {
            for (final host in [false, true]) {
              if (platform == TargetPlatform.android && !host) continue;
              final name =
                  '${platform.name}${host ? ' under the host field theme' : ''}';
              shots[name] = await _shoot(t, c, platform, host: host);
            }
          }
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
        for (final MapEntry(key: name, value: shot) in shots.entries) {
          expect(shot.part, android.part, reason: 'the part as $name');
          expect(shot.box.size, android.box.size, reason: 'the box as $name');
          for (final (what, rect, box, androidRect, androidBox) in [
            ('hint', shot.hint, shot.hintBox, android.hint, android.hintBox),
            ('typed words', shot.words, shot.box, android.words, android.box),
          ]) {
            if (rect == null || androidRect == null) continue;
            if (box == null || androidBox == null) continue;
            final here = rect.shift(-box.topLeft);
            final there = androidRect.shift(-androidBox.topLeft);
            expect(
              (here.top - there.top).abs(),
              lessThanOrEqualTo(.5),
              reason:
                  "the $what's top in the box: as $name $here, "
                  'on Android $there',
            );
            expect(
              (here.height - there.height).abs(),
              lessThanOrEqualTo(.5),
              reason: "the $what's height: as $name $here, on Android $there",
            );
            // A one-line entry's capitals, not its line box, stand on the
            // box's middle (DesignCapCenter); ui_core's label and row checks
            // read them.
          }
        }
      },
    );
  }
}
