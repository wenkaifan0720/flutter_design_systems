/// A place to drop or pick files, and the files on their way up.
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'button.dart';
import 'icon_button.dart';
import 'pressable.dart';
import 'progress.dart';

/// One file in a [MinimalFileUpload]'s list: its [name], its size in
/// [bytes], and its [progress] (0..1) while it uploads; [error] when it
/// failed.
@immutable
class MinimalUploadFile {
  /// A file the upload lists.
  const MinimalUploadFile({
    required this.name,
    this.bytes,
    this.progress,
    this.error,
  });

  /// Its name.
  final String name;

  /// Its size, printed beside the name.
  final int? bytes;

  /// 0..1 while it uploads; null once it is up (or before it starts).
  final double? progress;

  /// Why it failed, printed in the destructive ink.
  final String? error;
}

/// A drop zone for files — an attachment, an import, a profile picture: a
/// dashed frame on the `shapes.medium` step with an upload glyph, [title]
/// and a quiet [hint] (the kinds and the size it takes), and under it the
/// [files] on their way up, each with its size, its progress and a remove
/// button.
///
/// The zone is a control: a tap (or Enter) calls [onBrowse], where the app
/// opens its file picker. [link] names the words in [title] that say so
/// (`browse`): they print as a [MinimalLink]'s do, in the accent's ink with
/// a thin underline, while the whole zone stays the one control. Dropping
/// is the app's: it wires its platform's drop target and passes [dragOver]
/// while a drag hovers, and only then the zone's dash and glyph turn to the
/// full ink, no tint — the zone saying it will take the drop. A hovering
/// pointer alone changes nothing.
///
/// ```dart
/// MinimalFileUpload(title: 'Drop a CSV here, or browse', link: 'browse', hint: 'Up to 10 MB', onBrowse: pick, files: uploads, onRemove: remove)
/// ```
class MinimalFileUpload extends StatelessWidget {
  /// A drop target titled [title].
  const MinimalFileUpload({
    super.key,
    required this.title,
    this.link,
    this.hint,
    this.onBrowse,
    this.dragOver = false,
    this.files = const [],
    this.onRemove,
  });

  /// What to drop or choose.
  final String title;

  /// The words in [title] that open the picker (`browse`), marked as a
  /// link's while [onBrowse] is set; null, or words [title] does not hold,
  /// mark nothing.
  final String? link;

  /// A line under the title: the types and the size allowed.
  final String? hint;

  /// Opens the app's file picker; null disables the zone.
  final VoidCallback? onBrowse;

  /// A drag carrying files hovers over the zone.
  final bool dragOver;

  /// The files chosen so far, listed under it.
  final List<MinimalUploadFile> files;

  /// Removes a file from the list; null shows no remove buttons.
  final ValueChanged<MinimalUploadFile>? onRemove;

  /// [title], its [link] words in a link's ink and underline (as
  /// [MinimalLink] draws them) while the zone can browse. Words only: the
  /// zone takes the tap.
  TextSpan _title(MinimalThemeData t) {
    final link = this.link;
    if (link == null || link.isEmpty || onBrowse == null) {
      return TextSpan(text: title);
    }
    final at = title.lastIndexOf(link);
    if (at < 0) return TextSpan(text: title);
    return TextSpan(
      children: [
        TextSpan(text: title.substring(0, at)),
        TextSpan(
          text: link,
          style: TextStyle(
            color: t.primaryInk,
            decoration: TextDecoration.underline,
            decorationColor: t.primaryInk.withValues(alpha: 0.5),
            decorationThickness: 1,
          ),
        ),
        TextSpan(text: title.substring(at + link.length)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final shape = t.shapes.medium;
    final hint = this.hint;
    final zone = MinimalPressable(
      onPressed: onBrowse,
      enabled: onBrowse != null,
      shape: shape,
      semanticLabel: hint == null ? title : '$title. $hint',
      child: CustomPaint(
        painter: _DashPainter(
          shape: shape,
          color: dragOver ? t.foreground : t.input,
          fill: t.card,
          width: t.rim,
          textDirection: Directionality.of(context),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MinimalSpacing.s20,
            vertical: MinimalSpacing.s24,
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MinimalIcon(
                  LucideIcons.upload,
                  size: MinimalIconSize.i24,
                  color: dragOver ? t.foreground : t.mutedForeground,
                ),
                const MinimalGap(MinimalSpacing.s12),
                Text.rich(
                  _title(t),
                  textAlign: TextAlign.center,
                  style: t.body.medium.c(t.foreground),
                ),
                if (hint != null) ...[
                  const MinimalGap(MinimalSpacing.s4),
                  Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: t.bodySmall.c(t.mutedForeground),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (files.isEmpty) return zone;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        zone,
        const MinimalGap(MinimalSpacing.s8),
        for (final file in files) _FileRow(file: file, onRemove: onRemove),
      ],
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onRemove});

  final MinimalUploadFile file;
  final ValueChanged<MinimalUploadFile>? onRemove;

  static String size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final progress = file.progress;
    final error = file.error;
    final bytes = file.bytes;
    final remove = onRemove;
    return Container(
      constraints: BoxConstraints(minHeight: t.rowHeight),
      decoration: BoxDecoration(border: Border(bottom: t.rule)),
      padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s8),
      // The glyph, the name, the size and the remove button share the first
      // line, centred on it; the progress or the error runs under the name
      // alone, ending where the remove button starts.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MinimalIcon(
                error == null ? LucideIcons.file : LucideIcons.fileX,
                size: MinimalIconSize.i16,
                color: error == null ? t.mutedForeground : t.destructiveInk,
              ),
              const MinimalGap(MinimalChromeMetrics.rowIconGap),
              Expanded(
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.body.c(t.foreground),
                ),
              ),
              if (bytes != null) ...[
                const MinimalGap(MinimalSpacing.s8),
                Text(size(bytes), style: t.mono.c(t.mutedForeground)),
              ],
              if (remove != null) ...[
                const MinimalGap(MinimalSpacing.s8),
                MinimalIconButton(
                  LucideIcons.x,
                  size: MinimalButtonSize.small,
                  variant: MinimalIconButtonVariant.ghost,
                  label: MinimalLocalizations.of(context).removeFile(file.name),
                  onPressed: () => remove(file),
                ),
              ],
            ],
          ),
          if (error != null || progress != null)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: MinimalIconSize.i16 + MinimalChromeMetrics.rowIconGap,
                // The remove button's square and the gap before it; the
                // button's square already leaves air under the name.
                end: remove == null
                    ? 0
                    : MinimalSpacing.s8 +
                          t.density.height(MinimalChromeMetrics.controlSm),
                top: error == null && remove == null ? MinimalSpacing.s4 : 0,
              ),
              child: error != null
                  ? Text(error, style: t.bodySmall.c(t.destructiveInk))
                  : MinimalLinearProgressIndicator(
                      value: progress,
                      label: file.name,
                    ),
            ),
        ],
      ),
    );
  }
}

/// The zone's frame: [fill] inside [shape] and its outline dashed, so the
/// zone reads as a place to put something rather than a card.
class _DashPainter extends CustomPainter {
  const _DashPainter({
    required this.shape,
    required this.color,
    required this.fill,
    required this.width,
    required this.textDirection,
  });

  final OutlinedBorder shape;
  final Color color;
  final Color fill;
  final double width;
  final TextDirection textDirection;

  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawPath(
      shape.getOuterPath(rect, textDirection: textDirection),
      Paint()..color = fill,
    );
    // The dash runs on its own centre line, concentric with the edge.
    final outline = MinimalShapes.inset(
      shape,
      width / 2,
    ).getOuterPath(rect.deflate(width / 2), textDirection: textDirection);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    for (final metric in outline.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
        d += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.shape != shape ||
      old.color != color ||
      old.fill != fill ||
      old.width != width ||
      old.textDirection != textDirection;
}
