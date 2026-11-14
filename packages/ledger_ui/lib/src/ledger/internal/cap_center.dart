import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// Each Ledger face's capitals over its em (OS/2 `sCapHeight` over
/// `unitsPerEm`, read from the bundled files): Inter Tight 1490/2048,
/// Instrument Serif 720/1000, Plex Mono 698/1000.
const Map<String, double> _capHeights = {
  'InterTight': 1490 / 2048,
  'InstrumentSerif': .72,
  'PlexMono': .698,
};

/// The cap height, over its size, of the face [style] sets (its family
/// with or without the package's prefix); Inter Tight's when it names none.
double ledgerCapHeight(TextStyle? style) {
  final family = style?.fontFamily ?? '';
  return _capHeights[family.substring(family.lastIndexOf('/') + 1)] ??
      _capHeights['InterTight']!;
}

/// [label], a one-line label set in [style], drawn with its capitals on its
/// box's middle: every face's label in Ledger's own widgets goes through it,
/// never an icon.
Widget ledgerCapCenter(TextStyle? style, Widget label) =>
    DesignCapCenter(capHeightFactor: ledgerCapHeight(style), child: label);
