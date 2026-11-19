/// How a screen stands while it can't show its content yet: lines of
/// shade where the words will be, and the loading, failed and done states
/// of a whole view; and a field for files.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../internal/words.dart';
import '../style.dart';
import '../theme.dart';
import '../localizations.dart';
import 'button.dart';
import 'chips.dart';
import 'feedback.dart';
import 'pane.dart';

/// Where words will be: [lines] lines of shade a font's height tall, in
/// whole cells, the last one shorter, still (a terminal doesn't shimmer);
/// a screen reader hears [semanticLabel] once.
///
/// ```dart
/// const TermSkeleton(lines: 3)
/// ```
class TermSkeleton extends StatelessWidget {
  /// [lines] lines of shade.
  const TermSkeleton({
    super.key,
    this.lines = 3,
    this.cols,
    this.semanticLabel = 'loading',
    this.style,
  });

  /// How many lines.
  final int lines;

  /// The lines' width in cells; null: the room there is.
  final int? cols;

  /// What a screen reader hears.
  ///
  /// Left as `'loading'`, it is the reader's words for it
  /// (`TermLocalizations.loadingLabel`): Arabic or German in an app in either.
  final String semanticLabel;

  /// Overrides, over the theme's [TermThemeData.skeletonStyle]: `fill`
  /// (the shade).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final shade =
        TermStyleOf([style, theme.skeletonStyle], const {}).fill ??
        Color.alphaBlend(theme.rule.withValues(alpha: 0.35), theme.background);
    return Semantics(
      label: termWords(
        context,
        semanticLabel,
        'loading',
        (w) => w.loadingLabel,
      ),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, c) {
          final room =
              cols ?? (c.maxWidth.isFinite ? grid.colsIn(c.maxWidth) : 40);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lines; i++)
                SizedBox(
                  height: grid.lineHeight,
                  child: Center(
                    child: Container(
                      width: grid.cols(
                        i == lines - 1 && lines > 1
                            ? (room * 0.6).round()
                            : room,
                      ),
                      height: grid.fontSize,
                      color: shade,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// How a [TermStatusView] stands.
enum TermStatus {
  /// Working: the spinner.
  loading,

  /// It failed: `✗` in red.
  error,

  /// It worked: `✓` in green.
  success,
}

/// A whole view's state, in the middle of its room: the spinner (or `✗`,
/// or `✓`) and [title] on one line, [message] dim under it, and [action]
/// (a retry, say) under that. A screen reader hears the change as it
/// happens.
///
/// ```dart
/// TermStatusView(
///   status: TermStatus.error,
///   title: "couldn't load runs",
///   message: 'the server did not answer in 30s',
///   action: TermButton(label: 'retry', onPressed: reload),
/// )
/// ```
class TermStatusView extends StatelessWidget {
  /// A view [status], saying [title].
  const TermStatusView({
    super.key,
    required this.status,
    required this.title,
    this.message,
    this.action,
    this.style,
  });

  /// Where it stands.
  final TermStatus status;

  /// What is happening, or what happened.
  final String title;

  /// More, dim.
  final String? message;

  /// What to do about it.
  final Widget? action;

  /// Overrides, over the theme's [TermThemeData.emptyStateStyle]:
  /// `foreground` (the title).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.emptyStateStyle], const {});
    final Widget mark = switch (status) {
      TermStatus.loading => const TermSpinner(),
      TermStatus.error => Text(
        '✗',
        style: theme.boldStyle.copyWith(color: theme.danger),
      ),
      TermStatus.success => Text(
        '✓',
        style: theme.boldStyle.copyWith(color: theme.success),
      ),
    };
    return Center(
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(child: mark),
                SizedBox(width: grid.cellWidth),
                Flexible(
                  child: Text(
                    title,
                    style: theme.boldStyle.copyWith(
                      color: own.foreground ?? theme.foreground,
                    ),
                  ),
                ),
              ],
            ),
            if (message != null)
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.dimStyle,
              ),
            if (action != null) ...[SizedBox(height: grid.lineHeight), action!],
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<TermStatus>('status', status))
      ..add(StringProperty('title', title));
  }
}

/// A field for files: a framed box titled [labelText] saying where they
/// come from, a `browse` button that calls [onBrowse] (the app opens its
/// own picker), and each file chosen as a tag with `×` to take it away.
///
/// ```dart
/// TermFileField(
///   labelText: 'attach logs',
///   files: picked,
///   onBrowse: pickFiles,
///   onRemoved: (i) => setState(() => picked.removeAt(i)),
/// )
/// ```
class TermFileField extends StatelessWidget {
  /// A field holding [files].
  const TermFileField({
    super.key,
    required this.files,
    required this.onBrowse,
    this.onRemoved,
    this.labelText,
    this.hintText = 'no file chosen',
    this.helperText,
    this.style,
  });

  /// The files' names.
  final List<String> files;

  /// Opens the app's picker; null disables the field.
  final VoidCallback? onBrowse;

  /// Takes the file at an index away; null: they stay.
  final ValueChanged<int>? onRemoved;

  /// What the field is for, cut into its top line.
  final String? labelText;

  /// What it says with no file.
  ///
  /// Left as `'no file chosen'`, it is the reader's words for it
  /// (`TermLocalizations.noFileLabel`): Arabic or German in an app in either.
  final String hintText;

  /// Help, dim, under the box.
  final String? helperText;

  /// Overrides, over the theme's [TermThemeData.textFieldStyle]: `edge`
  /// (the frame) and `foreground` (the names).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    return Semantics(
      container: true,
      label: labelText,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TermPane(
            title: labelText,
            style: TermStyle.layered([style, theme.textFieldStyle]),
            child: Wrap(
              spacing: grid.cellWidth,
              runSpacing: grid.lineHeight / 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (files.isEmpty)
                  Text(
                    termWords(
                      context,
                      hintText,
                      'no file chosen',
                      (w) => w.noFileLabel,
                    ),
                    style: theme.dimStyle,
                  )
                else
                  for (final (i, f) in files.indexed)
                    TermTag(
                      label: f,
                      onDeleted: onRemoved == null ? null : () => onRemoved!(i),
                    ),
                TermButton(
                  label: TermLocalizations.of(context).browseLabel,
                  onPressed: onBrowse,
                ),
              ],
            ),
          ),
          if (helperText != null)
            Padding(
              padding: EdgeInsetsDirectional.only(start: grid.cols(2)),
              child: Text(helperText!, style: theme.dimStyle),
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('files', files.length))
      ..add(StringProperty('labelText', labelText, defaultValue: null));
  }
}
