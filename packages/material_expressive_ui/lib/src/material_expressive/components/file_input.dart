/// File input: a drop area that also opens the platform's picker, and the
/// files chosen so far.
///
/// Material 3 has no file input (an Android app opens the system picker
/// from a button); this one is for the web and desktop, drawn from
/// Expressive's surface, buttons, type and scheme roles. The package takes
/// no plugin: the app wires its own drop target and picker, and tells the
/// input when a drag hovers ([ExpressiveFileUpload.dragging]).
library;

import 'package:flutter/widgets.dart';

import '../elevation.dart';
import '../icons.dart';
import '../spacing.dart';
import '../strings.dart';
import '../theme.dart';
import 'buttons.dart';
import 'icon_buttons.dart';
import 'text_fields.dart';

/// A file chosen in an [ExpressiveFileUpload]: its [name] and an optional
/// [detail] (its size, `2.4 MB`).
@immutable
class ExpressiveChosenFile {
  /// A file named [name].
  const ExpressiveChosenFile(this.name, {this.detail});

  /// The file's name: `receipt.pdf`.
  final String name;

  /// A second line: its size or type; none when null.
  final String? detail;
}

/// A file input: a drop area on `surfaceContainerLow` at the large corner
/// step, its edge a solid `outline` hairline as a field's (Material draws
/// no dashed edges: a surface's edge is a line), holding an `upload` glyph in
/// `primary`, [label] in `titleSmall`, [supportingText] in `bodySmall` and
/// a tonal button that calls [onBrowse] (the app opens its picker). While
/// [dragging] (the app's drop target says a drag hovers) the area fills
/// `primaryContainer` under a solid 2dp `primary` edge; an [errorText]
/// draws the edge solid in `error` and says what is wrong under the area.
/// The chosen [files] list under it, each with a remove button calling
/// [onRemove] with its index. Material 3 has no file input; this is drawn
/// from its surface and buttons, and takes no plugin: the app wires its own
/// drop target and picker.
///
/// ```dart
/// ExpressiveFileUpload(label: 'Drop a receipt here', supportingText: 'PDF or JPG, up to 10 MB', onBrowse: pickFiles, files: chosen, onRemove: remove)
/// ```
class ExpressiveFileUpload extends StatelessWidget {
  /// A drop area saying [label], opening the picker through [onBrowse].
  const ExpressiveFileUpload({
    required this.label,
    required this.onBrowse,
    this.supportingText,
    this.browseLabel,
    this.dragging = false,
    this.errorText,
    this.files = const <ExpressiveChosenFile>[],
    this.onRemove,
    this.semanticLabel,
    super.key,
  });

  /// What the area asks for: `Drop a receipt here`.
  final String label;

  /// What it takes, under the label: `PDF or JPG, up to 10 MB`; none when
  /// null.
  final String? supportingText;

  /// Opens the platform's picker; the button is disabled when null.
  final VoidCallback? onBrowse;

  /// The button's words; `Choose files` when null.
  final String? browseLabel;

  /// Whether a drag carrying files hovers over the area (the app's drop
  /// target sets it).
  final bool dragging;

  /// What is wrong with the last drop or choice, under the area; none when
  /// null.
  final String? errorText;

  /// The files chosen so far, listed under the area.
  final List<ExpressiveChosenFile> files;

  /// Removes the file at an index of [files]; no remove buttons when null.
  final ValueChanged<int>? onRemove;

  /// What a screen reader calls the area; `File input` when null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final colors = t.colors;
    final strings = ExpressiveLocalizations.of(context);
    final shape = t.shapes.large;
    final error = errorText != null;
    final edge = error
        ? colors.error
        : dragging
        ? colors.primary
        : colors.outline;
    final edgeWidth = error || dragging ? ExpressiveSpacing.s2 : 1.0;
    final area = Semantics(
      container: true,
      label: semanticLabel ?? strings.fileInput,
      hint: label,
      child: CustomPaint(
        foregroundPainter: _Edge(
          shape: shape,
          color: edge,
          width: edgeWidth,
          textDirection: Directionality.of(context),
        ),
        child: ExpressiveSurface(
          shape: shape,
          color: dragging
              ? colors.primaryContainer
              : colors.surfaceContainerLow,
          contentColor: dragging ? colors.onPrimaryContainer : colors.onSurface,
          padding: const EdgeInsets.all(ExpressiveSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: ExpressiveSpacing.s8,
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(
                  ExpressiveSymbols.upload,
                  size: ExpressiveSpacing.s32,
                  color: dragging ? colors.onPrimaryContainer : colors.primary,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: t.type.titleSmall.copyWith(
                  color: dragging
                      ? colors.onPrimaryContainer
                      : colors.onSurface,
                ),
              ),
              if (supportingText case final text?)
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: t.type.bodySmall.copyWith(
                    color: dragging
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: ExpressiveSpacing.s8),
                child: ExpressiveFilledButton.tonal(
                  browseLabel ?? strings.chooseFiles,
                  icon: ExpressiveSymbols.attachFile,
                  onPressed: onBrowse,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        area,
        if (errorText case final message?) ExpressiveFieldError(message),
        for (var i = 0; i < files.length; i++)
          _FileRow(
            file: files[i],
            onRemove: onRemove == null ? null : () => onRemove!(i),
          ),
      ],
    );
  }
}

/// A chosen file: a document glyph, its name over its detail, a remove
/// button.
class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onRemove});

  final ExpressiveChosenFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final strings = ExpressiveLocalizations.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: ExpressiveSpacing.s56),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: ExpressiveSpacing.s16),
        child: Row(
          spacing: ExpressiveSpacing.s16,
          children: <Widget>[
            ExcludeSemantics(
              child: Icon(
                ExpressiveSymbols.description,
                size: ExpressiveSpacing.s24,
                color: t.colors.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.type.bodyLarge.copyWith(color: t.colors.onSurface),
                  ),
                  if (file.detail case final detail?)
                    Text(
                      detail,
                      maxLines: 1,
                      style: t.type.bodySmall.copyWith(
                        color: t.colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (onRemove case final remove?)
              ExpressiveIconButton(
                ExpressiveSymbols.close,
                semanticLabel: strings.removeFile(file.name),
                onPressed: remove,
              ),
          ],
        ),
      ),
    );
  }
}

/// The area's edge on its own shape.
class _Edge extends CustomPainter {
  const _Edge({
    required this.shape,
    required this.color,
    required this.width,
    required this.textDirection,
  });

  final OutlinedBorder shape;
  final Color color;
  final double width;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final path = shape.getOuterPath(rect, textDirection: textDirection);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(_Edge old) =>
      old.shape != shape ||
      old.color != color ||
      old.width != width ||
      old.textDirection != textDirection;
}
