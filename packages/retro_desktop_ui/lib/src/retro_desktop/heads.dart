// Heads and small type. A window's title bar is the section head, so there are few: a sentence, an eyebrow, a label.
import 'package:flutter/widgets.dart';

import 'controls.dart';
import 'layout.dart';
import 'theme.dart';
import 'component_themes.dart';

/// Text that sets `*words*` in italic, and keeps all else as given: a sentence with one title in it.
///
/// ```dart
/// RetroDesktopText('Read *The Lamp Room*, ch. 3 to 4', style: t.type.row)
/// ```
class RetroDesktopText extends StatelessWidget {
  /// Creates a [RetroDesktopText].
  const RetroDesktopText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// The text displayed by this part.
  final String text;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final TextStyle style;

  /// How text is aligned within its available width.
  final TextAlign? textAlign;

  /// The maximum number of text lines to display.
  final int? maxLines;

  /// How text beyond the available lines is handled.
  final TextOverflow? overflow;
  @override
  Widget build(BuildContext context) {
    if (!text.contains('*')) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    final parts = text.split('*');
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < parts.length; i++)
            if (parts[i].isNotEmpty)
              TextSpan(
                text: parts[i],
                style: i.isOdd
                    ? style.copyWith(fontStyle: FontStyle.italic)
                    : style,
              ),
        ],
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// A small line over a head: who it is for, what it is, when.
///
/// ```dart
/// RetroDesktopEyebrow('Good morning · 09:20')
/// ```
class RetroDesktopEyebrow extends StatelessWidget {
  /// Creates a [RetroDesktopEyebrow].
  const RetroDesktopEyebrow(this.text, {super.key});

  /// The text displayed by this part.
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return Text(
      text,
      style: t.type.caption.copyWith(color: t.colors.textTertiary),
    );
  }
}

/// A page's sentence in the system face, 30 lp to 34: what the active window is saying. One to a window.
///
/// ```dart
/// RetroDesktopHeadline('4 left today')
/// ```
class RetroDesktopHeadline extends StatelessWidget {
  /// Creates a [RetroDesktopHeadline].
  const RetroDesktopHeadline(this.text, {super.key});

  /// The text displayed by this part.
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: RetroDesktopTheme.of(context).type.head);
}

/// A small head in the system face, with its line: inside a window, over what belongs to it.
///
/// ```dart
/// RetroDesktopSectionHeader('Storage and sync', note: 'All changes saved', trailing: RetroDesktopButton('Manage', size: RetroDesktopButtonSize.small))
/// ```
class RetroDesktopSectionHeader extends StatelessWidget {
  /// Creates a [RetroDesktopSectionHeader].
  const RetroDesktopSectionHeader(
    this.title, {
    super.key,
    this.note,
    this.trailing,
    this.leading,
  });

  /// The heading displayed above the content.
  final String title;

  /// Supporting text shown with the main content.
  final String? note;

  /// Optional content after the main content in reading order.
  final Widget? trailing;

  /// A drawing before the words, about 40 square: a `RetroDesktopDeskArt`.
  final Widget? leading;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final text = RetroDesktopColumn(
      gap: 2,
      children: [
        Text(title, style: t.type.pixel(18, 18)),
        if (note != null)
          Text(
            note!,
            style: t.type.meta.copyWith(color: t.colors.textSecondary),
          ),
      ],
    );
    final words = leading == null
        ? text
        : RetroDesktopFitRow(fill: 1, gap: 12, children: [leading!, text]);
    if (trailing == null) return words;
    return RetroDesktopFitRow(
      fill: 0,
      gap: 8,
      fillShare: .5,
      children: [words, trailing!],
    );
  }
}

/// A small head over what follows inside a window: a triangle if [open] says it can fold, a small note at its end.
///
/// ```dart
/// RetroDesktopPartHead('Next 12 hours', note: 'sky, °C, rain %', open: true)
/// ```
class RetroDesktopPartHead extends StatelessWidget {
  /// Creates a [RetroDesktopPartHead].
  const RetroDesktopPartHead(this.title, {super.key, this.note, this.open});

  /// The heading displayed above the content.
  final String title;

  /// Supporting text shown with the main content.
  final String? note;

  /// Whether the part under the head is open: a triangle pointing down, or right when false; null draws none.
  final bool? open;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(2, 2, 4, 8),
      child: RetroDesktopFitRow(
        fill: 0,
        gap: 8,
        fillShare: .5,
        children: [
          Row(
            children: [
              if (open != null) ...[
                RetroDesktopTriangleMark(
                  open!
                      ? AxisDirection.down
                      : (rtl ? AxisDirection.left : AxisDirection.right),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: t.type.pixel(18, 18),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (note != null)
            Text(
              note!,
              style: t.type.caption.copyWith(color: t.colors.textTertiary),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

/// A small label over a value or a field.
///
/// ```dart
/// RetroDesktopLabel('Notebook')
/// ```
class RetroDesktopLabel extends StatelessWidget {
  /// Creates a [RetroDesktopLabel].
  const RetroDesktopLabel(this.text, {super.key});

  /// The text displayed by this part.
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: RetroDesktopTheme.of(context).type.caption);
}

/// Whose it is: two letters on a small ink chip, at the menu bar's end or a row's start.
///
/// ```dart
/// RetroDesktopMonogram('AC')
/// ```
class RetroDesktopMonogram extends StatelessWidget {
  /// Creates a [RetroDesktopMonogram].
  const RetroDesktopMonogram(this.initials, {super.key, this.style});

  /// The letters displayed when an image is unavailable.
  final String initials;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) get) =>
        RetroDesktopStyle.first([style, t.avatarTheme], get, const {});
    final text = t.type
        .pixel(15, 15, color: t.colors.paper)
        .merge(slot((s) => s.textStyle))
        .copyWith(color: slot((s) => s.foreground));
    final factor =
        (MediaQuery.textScalerOf(context).scale(text.fontSize ?? 15) / 15)
            .clamp(1.0, double.infinity);
    final minimum = slot((s) => s.minimumSize) ?? Size.zero;
    final width = (26 * factor).clamp(minimum.width, double.infinity);
    final height = (19 * factor).clamp(minimum.height, double.infinity);
    return retroDesktopOwnSize(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: slot((s) => s.fill) ?? t.colors.text,
          shape: (slot((s) => s.shape) ?? t.shapes.full).copyWith(
            side: slot((s) => s.side) ?? BorderSide.none,
          ),
        ),
        child: Center(
          child: Padding(
            padding: slot((s) => s.padding) ?? EdgeInsets.zero,
            child: Text(initials, style: text, maxLines: 1, softWrap: false),
          ),
        ),
      ),
    );
  }
}
