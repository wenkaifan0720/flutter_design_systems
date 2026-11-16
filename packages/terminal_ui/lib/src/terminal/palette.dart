/// Terminal's sixteen colours: the ANSI palette a terminal program draws
/// with, designed per brightness rather than taken raw.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The sixteen ANSI colours and the terminal's own background and
/// foreground, as a terminal emulator's colour scheme holds them.
///
/// Every colour is designed against its [background]: each reads at 4.5:1
/// or more as words on it, and the background reads at 4.5:1 or more when
/// a colour is used as an inverse fill under it. [night] and [paper] are the
/// two Terminal ships; an app may write its own.
///
/// ```dart
/// final palette = TermPalette.night.copyWith(cyan: const Color(0xFF7DD3FC));
/// ```
@immutable
class TermPalette with Diagnosticable {
  /// A palette of the eighteen given colours.
  const TermPalette({
    required this.background,
    required this.foreground,
    required this.black,
    required this.red,
    required this.green,
    required this.yellow,
    required this.blue,
    required this.magenta,
    required this.cyan,
    required this.white,
    required this.brightBlack,
    required this.brightRed,
    required this.brightGreen,
    required this.brightYellow,
    required this.brightBlue,
    required this.brightMagenta,
    required this.brightCyan,
    required this.brightWhite,
  });

  /// The dark palette, Terminal's default: a near-black screen with a cool
  /// cast, warm-neutral words, and colours lifted until each reads at 6:1 or
  /// more on it.
  static const TermPalette night = TermPalette(
    background: Color(0xFF0E1013),
    foreground: Color(0xFFD9DCE1),
    black: Color(0xFF1C1F25),
    red: Color(0xFFF0787A),
    green: Color(0xFF8FD18F),
    yellow: Color(0xFFE3C46F),
    blue: Color(0xFF7FA9F5),
    magenta: Color(0xFFD195E6),
    cyan: Color(0xFF6CCFD8),
    white: Color(0xFFBFC4CC),
    brightBlack: Color(0xFF8A919C),
    brightRed: Color(0xFFFF9C9C),
    brightGreen: Color(0xFFAEE6A8),
    brightYellow: Color(0xFFF2DA8C),
    brightBlue: Color(0xFFA3C2FF),
    brightMagenta: Color(0xFFE3B3F2),
    brightCyan: Color(0xFF9BE3E9),
    brightWhite: Color(0xFFF2F4F7),
  );

  /// The light palette: ink on warm paper, as a terminal printed on a
  /// teletype's roll. Its "bright" colours are the deeper ones, so they
  /// still read as emphasis on a light ground.
  static const TermPalette paper = TermPalette(
    background: Color(0xFFF6F3EB),
    foreground: Color(0xFF1D1E21),
    black: Color(0xFF2A2B2F),
    red: Color(0xFFB42318),
    green: Color(0xFF2F6E2F),
    yellow: Color(0xFF835C00),
    blue: Color(0xFF1F55B8),
    magenta: Color(0xFF8A3399),
    cyan: Color(0xFF0B6870),
    white: Color(0xFF55575D),
    brightBlack: Color(0xFF62646A),
    brightRed: Color(0xFF8F1B12),
    brightGreen: Color(0xFF22561F),
    brightYellow: Color(0xFF674700),
    brightBlue: Color(0xFF173F8C),
    brightMagenta: Color(0xFF6B2577),
    brightCyan: Color(0xFF07525A),
    brightWhite: Color(0xFF101114),
  );

  /// The screen behind everything.
  final Color background;

  /// The words.
  final Color foreground;

  /// ANSI 0.
  final Color black;

  /// ANSI 1.
  final Color red;

  /// ANSI 2.
  final Color green;

  /// ANSI 3.
  final Color yellow;

  /// ANSI 4.
  final Color blue;

  /// ANSI 5.
  final Color magenta;

  /// ANSI 6.
  final Color cyan;

  /// ANSI 7.
  final Color white;

  /// ANSI 8, the dim words of secondary text.
  final Color brightBlack;

  /// ANSI 9.
  final Color brightRed;

  /// ANSI 10.
  final Color brightGreen;

  /// ANSI 11.
  final Color brightYellow;

  /// ANSI 12.
  final Color brightBlue;

  /// ANSI 13.
  final Color brightMagenta;

  /// ANSI 14.
  final Color brightCyan;

  /// ANSI 15.
  final Color brightWhite;

  /// The sixteen ANSI colours in their order (0 to 15), as an escape
  /// sequence's `30`–`37` and `90`–`97` name them.
  List<Color> get ansi => [
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    brightBlack,
    brightRed,
    brightGreen,
    brightYellow,
    brightBlue,
    brightMagenta,
    brightCyan,
    brightWhite,
  ];

  /// This palette with the given colours changed.
  TermPalette copyWith({
    Color? background,
    Color? foreground,
    Color? black,
    Color? red,
    Color? green,
    Color? yellow,
    Color? blue,
    Color? magenta,
    Color? cyan,
    Color? white,
    Color? brightBlack,
    Color? brightRed,
    Color? brightGreen,
    Color? brightYellow,
    Color? brightBlue,
    Color? brightMagenta,
    Color? brightCyan,
    Color? brightWhite,
  }) => TermPalette(
    background: background ?? this.background,
    foreground: foreground ?? this.foreground,
    black: black ?? this.black,
    red: red ?? this.red,
    green: green ?? this.green,
    yellow: yellow ?? this.yellow,
    blue: blue ?? this.blue,
    magenta: magenta ?? this.magenta,
    cyan: cyan ?? this.cyan,
    white: white ?? this.white,
    brightBlack: brightBlack ?? this.brightBlack,
    brightRed: brightRed ?? this.brightRed,
    brightGreen: brightGreen ?? this.brightGreen,
    brightYellow: brightYellow ?? this.brightYellow,
    brightBlue: brightBlue ?? this.brightBlue,
    brightMagenta: brightMagenta ?? this.brightMagenta,
    brightCyan: brightCyan ?? this.brightCyan,
    brightWhite: brightWhite ?? this.brightWhite,
  );

  /// The palette [t] of the way from [a] to [b], colour by colour.
  static TermPalette lerp(TermPalette a, TermPalette b, double t) {
    if (identical(a, b)) return a;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return TermPalette(
      background: c(a.background, b.background),
      foreground: c(a.foreground, b.foreground),
      black: c(a.black, b.black),
      red: c(a.red, b.red),
      green: c(a.green, b.green),
      yellow: c(a.yellow, b.yellow),
      blue: c(a.blue, b.blue),
      magenta: c(a.magenta, b.magenta),
      cyan: c(a.cyan, b.cyan),
      white: c(a.white, b.white),
      brightBlack: c(a.brightBlack, b.brightBlack),
      brightRed: c(a.brightRed, b.brightRed),
      brightGreen: c(a.brightGreen, b.brightGreen),
      brightYellow: c(a.brightYellow, b.brightYellow),
      brightBlue: c(a.brightBlue, b.brightBlue),
      brightMagenta: c(a.brightMagenta, b.brightMagenta),
      brightCyan: c(a.brightCyan, b.brightCyan),
      brightWhite: c(a.brightWhite, b.brightWhite),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TermPalette &&
      other.background == background &&
      other.foreground == foreground &&
      listEquals(other.ansi, ansi);

  @override
  int get hashCode => Object.hash(background, foreground, Object.hashAll(ansi));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('background', background))
      ..add(ColorProperty('foreground', foreground));
    const names = [
      'black',
      'red',
      'green',
      'yellow',
      'blue',
      'magenta',
      'cyan',
      'white',
      'brightBlack',
      'brightRed',
      'brightGreen',
      'brightYellow',
      'brightBlue',
      'brightMagenta',
      'brightCyan',
      'brightWhite',
    ];
    final colours = ansi;
    for (var i = 0; i < names.length; i++) {
      properties.add(ColorProperty(names[i], colours[i]));
    }
  }
}
