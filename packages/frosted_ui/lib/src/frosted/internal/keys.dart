import 'package:flutter/widgets.dart';

import '../glyphs.dart';

/// The modifier keys a shortcut writes as symbols, each drawn as its glyph
/// and read aloud as its name. The look's typefaces carry none of these
/// symbols: set as text they fall back to whatever font the platform has,
/// and on the web the engine fetches one.
const Map<String, (IconData, String)> _modifiers = {
  '⌘': (FrostedGlyphs.command, 'Command'),
  '⇧': (FrostedGlyphs.shift, 'Shift'),
  '⌥': (FrostedGlyphs.option, 'Option'),
  '⌃': (FrostedGlyphs.control, 'Control'),
};

/// [keys] as a screen reader says them: each modifier symbol named
/// ("⇧⌘Z" is "Shift Command Z").
String frostedKeysSpoken(String keys) {
  final words = <String>[];
  final run = StringBuffer();
  for (final char in keys.characters) {
    final modifier = _modifiers[char];
    if (modifier == null) {
      run.write(char);
      continue;
    }
    if (run.isNotEmpty) words.add(run.toString());
    run.clear();
    words.add(modifier.$2);
  }
  if (run.isNotEmpty) words.add(run.toString());
  return words.join(' ');
}

/// A shortcut's [keys] as written (⌘K, ⇧⌘Z, Ctrl+K) in [style] over the
/// ambient text style: the modifier symbols drawn as glyphs at the type's
/// size and colour, the rest as text, read aloud with the symbols named
/// ("Shift Command Z"). Plumbing of the components; pages never place one.
class FrostedKeys extends StatelessWidget {
  /// Creates [FrostedKeys] for [keys].
  const FrostedKeys(this.keys, {this.style, super.key});

  /// The shortcut as written.
  final String keys;

  /// The type over the ambient style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Directionality(
    // Figures, codes and marks read left to right in any language.
    textDirection: TextDirection.ltr,
    child: Builder(builder: _ltrBuild),
  );

  Widget _ltrBuild(BuildContext context) {
    final type = DefaultTextStyle.of(context).style.merge(style);
    final size = type.fontSize ?? 14;
    final spans = <InlineSpan>[];
    final run = StringBuffer();
    void flush() {
      if (run.isEmpty) return;
      spans.add(TextSpan(text: run.toString()));
      run.clear();
    }

    for (final char in keys.characters) {
      final modifier = _modifiers[char];
      if (modifier == null) {
        run.write(char);
        continue;
      }
      flush();
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(modifier.$1, size: size * 0.9, color: type.color),
        ),
      );
    }
    flush();
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      semanticsLabel: frostedKeysSpoken(keys),
    );
  }
}
