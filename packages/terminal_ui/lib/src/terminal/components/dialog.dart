/// Dialogs: a raised pane in a doubled line over the screen, and the
/// terminal's question, `proceed? [y/N]`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../style.dart';
import '../theme.dart';
import 'button.dart';
import 'containers.dart';
import 'key_hint.dart';
import 'pane.dart';
import 'text_field.dart';

/// A dialog's face: a raised pane, its line doubled (it has the focus), its
/// [title] cut into the top line, [content] inside and [actions] along the
/// last line, at the end. At most [cols] cells wide.
///
/// Show one with [showTermDialog].
///
/// ```dart
/// TermDialog(
///   title: 'discard changes',
///   content: const Text('the form has edits that are not saved.'),
///   actions: [
///     TermButton(label: 'keep', onPressed: () {}),
///     TermButton.filled(label: 'discard', onPressed: () {}),
///   ],
/// )
/// ```
class TermDialog extends StatelessWidget {
  /// A dialog titled [title].
  const TermDialog({
    super.key,
    required this.title,
    this.content,
    this.actions = const [],
    this.footer,
    this.cols = 56,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.dialogStyle]: `fill` (the
  /// ground), `foreground` (the title) and `edge` (the box lines).
  final TermStyle? style;

  /// What it asks, cut into the top line; a screen reader hears it as the
  /// dialog's name.
  final String title;

  /// What it says.
  final Widget? content;

  /// Its buttons, the strongest last.
  final List<Widget> actions;

  /// The keys that work in it, cut into the bottom line: `esc cancel`.
  final String? footer;

  /// The most cells across it takes.
  final int cols;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final lh = grid.lineHeight;
    final theme = TermTheme.of(context);
    final pane = TermPane(
      title: title,
      footer: termKeysShown(context) ? footer : null,
      raised: true,
      focused: true,
      style: TermStyle.layered([style, theme.dialogStyle]),
      child: Padding(
        padding: EdgeInsets.only(top: lh),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Where the screen is too short for all of it (a phone at
            // 200% text), the words scroll and the actions stay.
            if (content != null)
              Flexible(
                child: TermWholeLines(
                  child: SingleChildScrollView(child: content),
                ),
              ),
            if (actions.isNotEmpty) ...[
              SizedBox(height: lh),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: cw,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: _OnCells(cols: cols, child: pane),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(IntProperty('cols', cols));
  }
}

/// Raises the dialog [builder] makes over the app, the screen behind dimmed,
/// and completes with what it pops. The dialog comes up where it stays, in
/// a very short fade ([TermMotion.screen]); under Reduce Motion it is
/// simply there.
Future<T?> showTermDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final theme = TermTheme.of(context);
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return navigator.push<T>(
    RawDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierLabel: DesignLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: theme.background.withValues(alpha: 0.72),
      transitionDuration: still ? Duration.zero : TermMotion.screen,
      pageBuilder: (dialogContext, _, _) => themes.wrap(
        SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.termGrid.cellWidth,
              ),
              child: Builder(builder: builder),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );
}

/// The terminal's question as a dialog: [message], then `proceed? [y/N]`,
/// answered with `y` or `n` (Return takes the capital: no) or the buttons.
///
/// With [typedConfirmation], the yes waits until that exact text is typed
/// in the field under the message: the guard before destroying something.
/// [isDestructiveAction] draws the yes in the danger ink.
///
/// Show one with [showTermConfirmDialog].
class TermConfirmDialog extends StatefulWidget {
  /// A y/N question.
  const TermConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'no',
    this.isDestructiveAction = false,
    this.typedConfirmation,
    this.sheet = false,
    required this.onConfirm,
    required this.onCancel,
    this.style,
  });

  /// Whether it stands as a [TermSheet] at the foot of the screen (a
  /// phone's thumb reaches it there) rather than a [TermDialog].
  final bool sheet;

  /// Overrides for its pane, over the theme's [TermThemeData.dialogStyle]
  /// (or [TermThemeData.sheetStyle] as a sheet).
  final TermStyle? style;

  /// What it asks, in the top line.
  final String title;

  /// What will happen.
  final String message;

  /// The yes button's words: `destroy`, `deploy`.
  final String confirmLabel;

  /// The no button's words.
  final String cancelLabel;

  /// Whether the yes destroys something.
  final bool isDestructiveAction;

  /// Text to type before the yes works, or null.
  final String? typedConfirmation;

  /// Called on yes.
  final VoidCallback onConfirm;

  /// Called on no.
  final VoidCallback onCancel;

  @override
  State<TermConfirmDialog> createState() => _TermConfirmDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('confirmLabel', confirmLabel))
      ..add(FlagProperty('sheet', value: sheet, ifTrue: 'sheet'))
      ..add(
        StringProperty(
          'typedConfirmation',
          typedConfirmation,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'isDestructiveAction',
          value: isDestructiveAction,
          ifTrue: 'destructive',
        ),
      );
  }
}

class _TermConfirmDialogState extends State<TermConfirmDialog> {
  final _typed = TextEditingController();

  @override
  void initState() {
    super.initState();
    _typed.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  bool get _ready =>
      widget.typedConfirmation == null ||
      _typed.text == widget.typedConfirmation;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final typed = widget.typedConfirmation;
    final yes = _ready ? widget.onConfirm : null;
    final footer = !termKeysShown(context)
        ? null
        : typed == null
        ? 'y yes · n no · esc'
        : 'esc cancel';
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.message),
        SizedBox(height: grid.lineHeight),
        if (typed != null)
          // What to type is in the field's label while the frame has room
          // for it; where it would be cut, it is a line of its own above,
          // so the words to type always show whole.
          LayoutBuilder(
            builder: (context, c) {
              final ask = 'type $typed to confirm';
              final fits =
                  !c.maxWidth.isFinite ||
                  grid.widthOf(ask) <= c.maxWidth - grid.cols(4);
              final field = TermTextField(
                controller: _typed,
                autofocus: true,
                labelText: fits ? ask : 'confirm',
                prompt: '>',
                autocorrect: false,
                onSubmitted: (_) => yes?.call(),
              );
              if (fits) return field;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'type '),
                        TextSpan(text: typed, style: theme.boldStyle),
                        const TextSpan(text: ' to confirm'),
                      ],
                    ),
                  ),
                  field,
                ],
              );
            },
          )
        else
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'proceed? '),
                TextSpan(text: '[y/', style: theme.dimStyle),
                TextSpan(text: 'N', style: theme.boldStyle),
                TextSpan(text: ']', style: theme.dimStyle),
              ],
            ),
            semanticsLabel: 'proceed? yes or no, no by default',
          ),
      ],
    );
    final actions = [
      TermButton(
        label: widget.cancelLabel,
        shortcut: typed == null
            ? const SingleActivator(LogicalKeyboardKey.keyN)
            : null,
        autofocus: typed == null,
        onPressed: widget.onCancel,
      ),
      TermButton.filled(
        label: widget.confirmLabel,
        shortcut: typed == null
            ? const SingleActivator(LogicalKeyboardKey.keyY)
            : null,
        isDestructiveAction: widget.isDestructiveAction,
        onPressed: yes,
      ),
    ];
    final dialog = widget.sheet
        ? TermSheet(
            style: widget.style,
            title: widget.title,
            footer: footer,
            actions: actions,
            child: content,
          )
        : TermDialog(
            style: widget.style,
            title: widget.title,
            footer: footer,
            content: content,
            actions: actions,
          );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onCancel,
        if (typed == null) ...{
          const SingleActivator(LogicalKeyboardKey.keyY): widget.onConfirm,
          const SingleActivator(LogicalKeyboardKey.keyN): widget.onCancel,
        },
      },
      child: dialog,
    );
  }
}

/// Asks [message] as a y/N question and completes with true for yes, false
/// for no and null when dismissed. See [TermConfirmDialog]. Under 600 wide
/// it stands as a sheet at the foot of the screen, where a thumb reaches;
/// [sheet] decides it instead when given.
Future<bool?> showTermConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'no',
  bool isDestructiveAction = false,
  String? typedConfirmation,
  bool? sheet,
}) {
  final asSheet = sheet ?? MediaQuery.sizeOf(context).width < 600;
  TermConfirmDialog question(BuildContext routeContext) => TermConfirmDialog(
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    isDestructiveAction: isDestructiveAction,
    typedConfirmation: typedConfirmation,
    sheet: asSheet,
    onConfirm: () => Navigator.of(routeContext).pop(true),
    onCancel: () => Navigator.of(routeContext).pop(false),
  );
  return asSheet
      ? showTermSheet<bool>(context: context, builder: question)
      : showTermDialog<bool>(context: context, builder: question);
}

/// A sheet: a raised pane standing on the foot of the screen, [title] cut
/// into its top line, [child], then [actions] at the end, the strongest
/// last. It is a [TermDialog] that stands where a thumb reaches; show one
/// with [showTermSheet].
///
/// ```dart
/// showTermSheet<void>(
///   context: context,
///   builder: (context) => TermSheet(
///     title: 'share run #1482',
///     actions: [TermButton.filled(label: 'copy link', onPressed: () {})],
///     child: const Text('a link anyone on the team can open'),
///   ),
/// );
/// ```
class TermSheet extends StatelessWidget {
  /// A sheet showing [child].
  const TermSheet({
    super.key,
    this.title,
    required this.child,
    this.actions = const [],
    this.footer = 'esc close',
    this.cols = 64,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.sheetStyle]: `fill` (the
  /// ground), `foreground` (the title) and `edge` (the box lines).
  final TermStyle? style;

  /// What it is about, cut into the top line; a screen reader hears it as
  /// the sheet's name.
  final String? title;

  /// What it shows.
  final Widget child;

  /// Its buttons, the strongest last.
  final List<Widget> actions;

  /// The keys that work in it, cut into the bottom line.
  final String? footer;

  /// The most cells across it takes on a wide screen.
  final int cols;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final lh = grid.lineHeight;
    final theme = TermTheme.of(context);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: _OnCells(
        cols: cols,
        child: TermPane(
          title: title,
          footer: termKeysShown(context) ? footer : null,
          raised: true,
          focused: true,
          style: TermStyle.layered([style, theme.sheetStyle]),
          child: Padding(
            padding: EdgeInsets.only(top: lh),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Where the screen is too short for all of it, the words
                // scroll and the actions stay.
                Flexible(
                  child: TermWholeLines(
                    child: SingleChildScrollView(child: child),
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  SizedBox(height: lh),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: grid.cellWidth,
                    runSpacing: lh,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(IntProperty('actions', actions.length))
      ..add(IntProperty('cols', cols, defaultValue: 64));
  }
}

/// Raises the sheet [builder] makes at the foot of the screen, the screen
/// behind dimmed, and completes with what it pops. Like a dialog it comes
/// up where it stays in a very short fade, and a tap outside or Escape
/// closes it.
Future<T?> showTermSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final theme = TermTheme.of(context);
  final grid = context.termGrid;
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return navigator.push<T>(
    RawDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierLabel: DesignLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: theme.background.withValues(alpha: 0.72),
      transitionDuration: still ? Duration.zero : TermMotion.screen,
      // The foot of the screen is cleared under the sheet, edge to edge and
      // to the bottom, so nothing of the status line or the window list
      // shows in the margin beside it.
      pageBuilder: (sheetContext, _, _) => themes.wrap(
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(top: grid.lineHeight * 0.5),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ColoredBox(
                color: theme.background,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      grid.cellWidth,
                      grid.lineHeight * 0.5,
                      grid.cellWidth,
                      grid.lineHeight * 0.5,
                    ),
                    child: Builder(builder: builder),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );
}

/// A dialog's or a sheet's pane, at most [cols] cells wide: narrower than
/// that, it takes the line from margin to margin, as the page's own panes
/// do, so its frame stands on theirs.
class _OnCells extends StatelessWidget {
  const _OnCells({required this.cols, required this.child});

  final int cols;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    return LayoutBuilder(
      builder: (context, c) =>
          c.maxWidth.isFinite && c.maxWidth < grid.cols(cols)
          ? SizedBox(width: c.maxWidth, child: child)
          : ConstrainedBox(
              constraints: BoxConstraints(maxWidth: grid.cols(cols)),
              child: child,
            ),
    );
  }
}
