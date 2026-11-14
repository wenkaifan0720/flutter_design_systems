/// How wide a control and a form stand where the window has room (design6
/// P, 11-11 (a)): from 600 a select, a button that fills, a stepper or a
/// segmented control keeps its own width, at most [fluent2ControlMax], and
/// never runs to its column or the page; a form section's measure stops at
/// [fluent2FormMeasure]. Free text fields and tables may span the form.
library;

import 'package:flutter/widgets.dart';

/// The window width from which controls keep their own width.
const double fluent2RoomyFrom = 600;

/// The widest a select, a filling button or a stepper stands from
/// [fluent2RoomyFrom].
const double fluent2ControlMax = 320;

/// The widest a form section runs: a reading measure for its labels and
/// fields.
const double fluent2FormMeasure = 560;

/// Whether the window is [fluent2RoomyFrom] or wider.
bool fluent2Roomy(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= fluent2RoomyFrom;

/// [child] (a select's or a combobox's trigger): under [fluent2RoomyFrom]
/// at least 250 and its column's width, as a phone's form runs; from there
/// as wide as its [content] (its widest words with its room, chevron and
/// strokes), at least 250 (Fluent's Dropdown) and at most
/// [fluent2ControlMax], never wider than its cell, at the cell's start. Its
/// list, anchored to [child], matches it.
Widget fluent2KeepsOwnWidth(
  BuildContext context, {
  required Widget child,
  double content = 0,
}) {
  if (!fluent2Roomy(context)) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 250),
      child: child,
    );
  }
  return Align(
    alignment: AlignmentDirectional.centerStart,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: content.clamp(250.0, fluent2ControlMax),
      ),
      child: child,
    ),
  );
}

/// The widest of [lines] in [style], at the text scale of [context].
double fluent2WordsWidth(
  BuildContext context,
  Iterable<String> lines,
  TextStyle style,
) {
  var widest = 0.0;
  final scaler = MediaQuery.textScalerOf(context);
  for (final line in lines) {
    final painter = TextPainter(
      text: TextSpan(text: line, style: style),
      textScaler: scaler,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  return widest.ceilToDouble();
}

/// The text scale at which each of [lines] in [style] stands whole on one
/// line in [room]: the reader's own (at [style]'s size, from [context])
/// where they fit, else the largest that fits, never under [least]. A
/// navigation label is never cut: where its place cannot grow (the phone
/// tab bar) it is drawn at this scale, as iOS keeps a tab bar's words at
/// their size while the reader's text grows.
double fluent2FitScale(
  BuildContext context,
  Iterable<String> lines,
  TextStyle style,
  double room, {
  double least = 0,
}) {
  style = _drawn(context, style);
  final size = style.fontSize ?? 14;
  final reader = MediaQuery.textScalerOf(context).scale(size) / size;
  final widest = _widest(lines, style);
  if (widest <= 0 || !room.isFinite || room <= 0) return reader;
  final fits = room / widest;
  final floor = least < reader ? least : reader;
  return fits >= reader ? reader : (fits < floor ? floor : fits);
}

/// The text scale at which [words] in [style] stand whole in [room] on at
/// most [lines] lines, each word whole on its line (never "Calenda" over
/// "r"): [fluent2FitScale]'s one-line scale (never under 1) where the words
/// then break into [lines] or fewer, else the largest scale at which they
/// do, never under [least] (a page's long name on a phone: iOS shrinks a
/// title whole before it would cut it).
double fluent2WrapScale(
  BuildContext context,
  String words,
  TextStyle style,
  double room, {
  int lines = 2,
  double least = 0.75,
}) {
  style = _drawn(context, style);
  final one = fluent2FitScale(context, [words], style, room, least: 1);
  final split = words.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  // Each word measured at the scale itself: tracking does not grow or
  // shrink with the words, so a width is not the unscaled one times scale.
  bool whole(double scale) => _widest(split, style, scale) <= room;
  bool fits(double scale) {
    if (!whole(scale)) return false;
    final painter = TextPainter(
      text: TextSpan(text: words, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.linear(scale),
      maxLines: lines,
    )..layout(maxWidth: room);
    final held = !painter.didExceedMaxLines;
    painter.dispose();
    return held;
  }

  if (!room.isFinite || room <= 0 || fits(one)) return one;
  var lo = least < one ? least : one;
  var hi = one;
  // Past the floor a word longer than the room is drawn smaller still,
  // as small as the room asks, rather than broken.
  if (!fits(lo)) {
    final longest = _widest(split, style);
    var word = longest > 0 ? (room / longest * 100).floorToDouble() / 100 : lo;
    if (word >= lo) return lo;
    while (word > 0.05 && !whole(word)) {
      word -= 0.01;
    }
    return word;
  }
  for (var i = 0; i < 8; i++) {
    final mid = (lo + hi) / 2;
    if (fits(mid)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return lo;
}

/// [style] as a [Text] under [context] draws it: over the ambient style, so
/// what it inherits (a Material ancestor's tracking) is measured too.
TextStyle _drawn(BuildContext context, TextStyle style) =>
    style.inherit ? DefaultTextStyle.of(context).style.merge(style) : style;

/// The widest of [lines] in [style] on one line, at [scale] (unscaled by
/// default).
double _widest(Iterable<String> lines, TextStyle style, [double scale = 1]) {
  var widest = 0.0;
  for (final line in lines) {
    final painter = TextPainter(
      text: TextSpan(text: line, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.linear(scale),
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  return widest;
}
