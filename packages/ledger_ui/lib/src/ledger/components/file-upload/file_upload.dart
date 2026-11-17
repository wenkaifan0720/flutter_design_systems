/// Files attached to an entry (a receipt's photo, a statement), in Ledger's
/// hand: a ruled slip to attach them and a line for each.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../format.dart';
import '../../internal/face.dart';
import '../../theme.dart';
import '../icon-button/icon_button.dart';
import '../pressable/pressable.dart';

/// One attached file: its [name], its [bytes], how far it has gone up
/// ([progress], 0 to 1; null once it is in) and what went wrong ([error]).
@immutable
class LedgerFile {
  /// A file named [name] of [bytes].
  const LedgerFile(this.name, {required this.bytes, this.progress, this.error});

  /// Its name, as shown.
  final String name;

  /// Its size.
  final int bytes;

  /// How far it has gone up, 0 to 1; null once it is in.
  final double? progress;

  /// Why it did not go up; null when nothing went wrong.
  final String? error;
}

/// Files attached to an entry: a slip ruled round in the dashed rule, a
/// paperclip and [hint] on it, that opens the app's picker ([onPick]) when
/// pressed (its rule turns to the ink under a pointer, the stamp's sink
/// while held, the double rule with focus); then each of [files] on a line
/// of its own, its name in the medium and its size in the mono, a rule
/// filling under it in the ink as it goes up, its error in the vermilion,
/// and the cross that takes it off ([onRemove]). Its [label] in the small
/// capitals over the slip. [onPick] null holds the slip in the third ink.
///
/// ```dart
/// LedgerFileUpload(label: 'Receipts', files: const [LedgerFile('Blue Fern.jpg', bytes: 182000)], onPick: () {}, onRemove: (f) {})
/// ```
class LedgerFileUpload extends StatelessWidget {
  /// A slip to attach files, and [files] under it.
  const LedgerFileUpload({
    required this.onPick,
    this.files = const [],
    this.onRemove,
    this.label,
    this.hint = 'Attach a photo or a PDF',
    this.note = 'Up to 10 MB each',
    super.key,
  });

  /// Opens the picker; null holds the slip.
  final VoidCallback? onPick;

  /// The files attached.
  final List<LedgerFile> files;

  /// Takes a file off; null shows no cross.
  final ValueChanged<LedgerFile>? onRemove;

  /// The small capitals over the slip.
  final String? label;

  /// The slip's words.
  final String hint;

  /// The note under the slip's words, in the mono.
  final String? note;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<VoidCallback>.has('onPick', onPick))
      ..add(IterableProperty<LedgerFile>('files', files))
      ..add(
        ObjectFlagProperty<ValueChanged<LedgerFile>>.has('onRemove', onRemove),
      )
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint))
      ..add(StringProperty('note', note, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final live = onPick != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LedgerSpacing.s8,
      children: [
        if (label case final l?)
          ExcludeSemantics(
            child: Text(
              l.toUpperCase(),
              style: t.label.colored(t.textSecondary),
            ),
          ),
        LedgerPressable(
          onTap: onPick,
          label: label == null ? hint : '$label: $hint',
          radius: t.controlRadius,
          child: Builder(
            builder: (context) {
              final hot = LedgerPressStates.isHot(context);
              return LedgerFace(
                style: LedgerFaceStyle(
                  ink: !live
                      ? t.textTertiary
                      : hot
                      ? t.textPrimary
                      : t.textSecondary,
                  rule: !live
                      ? t.border
                      : hot
                      ? t.textPrimary
                      : t.borderStrong,
                ),
                builder: (context, s, _) => CustomPaint(
                  painter: _Dashed(color: s.rule!, radius: t.controlRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LedgerSpacing.s16,
                      vertical: LedgerSpacing.s20,
                    ),
                    child: Row(
                      spacing: LedgerSpacing.s12,
                      children: [
                        Icon(LucideIcons.paperclip, size: _glyph, color: s.ink),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: LedgerSpacing.s2,
                            children: [
                              Text(hint, style: t.rowTitle.colored(s.ink)),
                              if (note case final n?)
                                Text(
                                  n.toUpperCase(),
                                  style: t.meta.colored(t.textTertiary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        for (final f in files) _FileLine(file: f, onRemove: onRemove),
      ],
    );
  }

  static const double _glyph = 20;
}

/// A file's line: its name and size, the rule filling as it goes up, its
/// cross.
class _FileLine extends StatelessWidget {
  const _FileLine({required this.file, required this.onRemove});

  final LedgerFile file;
  final ValueChanged<LedgerFile>? onRemove;

  static String _size(int bytes) => bytes >= 1000000
      ? '${(bytes / 1000000).toStringAsFixed(1)} MB'
      : '${(bytes / 1000).round()} KB';

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final p = file.progress;
    final wrong = file.error != null;
    final state = wrong
        ? file.error!
        : p == null
        ? _size(file.bytes)
        : '${(p * 100).round()}% · ${_size(file.bytes)}';
    return Semantics(
      container: true,
      label: '${file.name}, $state',
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.hairline)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: LedgerSpacing.s4),
              child: Row(
                spacing: LedgerSpacing.s12,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      wrong ? LucideIcons.circleAlert : LucideIcons.fileText,
                      size: _glyph,
                      color: wrong ? t.danger : t.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LedgerFormat.unbroken(file.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.rowTitle.colored(t.textPrimary),
                          ),
                          Text(
                            state.toUpperCase(),
                            maxLines: 2,
                            style: t.meta.colored(
                              wrong ? t.danger : t.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (onRemove case final remove?)
                    LedgerIconButton(
                      LucideIcons.x,
                      semanticLabel: 'Remove ${file.name}',
                      size: LedgerIconButtonSize.small,
                      tapAlignment: AlignmentDirectional.centerEnd,
                      onPressed: () => remove(file),
                    ),
                ],
              ),
            ),
            // The rule under the line fills in the ink as the file goes up.
            if (p != null && !wrong)
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                height: 2,
                child: LedgerEase(
                  value: p.clamp(0.0, 1.0),
                  builder: (context, at, _) => FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: at.clamp(0.0, 1.0),
                    child: ColoredBox(color: t.textPrimary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const double _glyph = 18;
}

/// The slip's dashed rule: 4 on, 3 off, round its corners.
class _Dashed extends CustomPainter {
  _Dashed({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(.5),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _on + _off) {
        canvas.drawPath(metric.extractPath(d, d + _on), paint);
      }
    }
  }

  static const double _on = 4;
  static const double _off = 3;

  @override
  bool shouldRepaint(_Dashed old) => old.color != color || old.radius != radius;
}
