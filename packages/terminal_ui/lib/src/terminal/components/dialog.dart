/// Dialogs: a raised pane in a doubled line over the screen, and the
/// terminal's question, `proceed? [y/N]`.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/words.dart';
import '../style.dart';
import '../theme.dart';
import '../localizations.dart';
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
    return _ModalPane(
      title: title,
      footer: footer,
      cols: cols,
      content: content,
      actions: actions,
      style: TermStyle.layered([style, TermTheme.of(context).dialogStyle]),
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
/// a very short fade on [TermMotion.surface] (under Reduce Motion, a fade
/// of the route's own); it keeps the focus inside while open and gives it
/// back as it closes, and Escape, Android's back or a tap outside (when
/// [barrierDismissible]) close it, through any `PopScope` in it.
///
/// [isAlert] makes it an alert, a question that wants an answer, to a
/// screen reader. [semanticLabel] names it; a [TermDialog] names it by its
/// title.
Future<T?> showTermDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool isAlert = false,
  String? semanticLabel,
  bool useRootNavigator = true,
}) {
  final cw = context.termGrid.cellWidth;
  return _pushSurface<T>(
    context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    isAlert: isAlert,
    semanticLabel: semanticLabel,
    page: (child) => SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: cw),
          child: child,
        ),
      ),
    ),
    builder: builder,
  );
}

// Terminal's modal surfaces on ui_core's dialog route: the screen behind
// dimmed in the theme's ground, [page] laying out what [builder] makes, the
// whole fading up in place on TermMotion.surface (critically damped, so the
// presence never passes 1). The route keeps the focus, gives it back, and
// closes on Escape, Back and the barrier.
Future<T?> _pushSurface<T>(
  BuildContext context, {
  required bool useRootNavigator,
  required bool barrierDismissible,
  required bool isAlert,
  required String? semanticLabel,
  required Widget Function(Widget child) page,
  required WidgetBuilder builder,
}) {
  final theme = TermTheme.of(context);
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<T>(
    RawModalDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      isAlert: isAlert,
      semanticLabel: semanticLabel,
      barrierColor: theme.background.withValues(alpha: 0.72),
      dampingRatio: TermMotion.surface.dampingRatio,
      stiffness: TermMotion.surface.stiffness,
      builder: (routeContext, details) => FadeTransition(
        opacity: details.animation,
        child: themes.wrap(page(Builder(builder: builder))),
      ),
    ),
  );
}

/// The terminal's question as a dialog: [message], then `proceed? [y/N]`,
/// answered with `y` or `n` (Return takes the capital: no) or the buttons.
/// The no is the default, so nothing outshines it: it has the focus, and
/// the yes is an ordinary key. The question states the keys once, and the
/// line under it says what `esc` does.
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
  ///
  /// Left as `'no'`, it is the reader's words for it
  /// (`TermLocalizations.noLabel`): Arabic or German in an app in either.
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
    final words = TermLocalizations.of(context);
    final grid = context.termGrid;
    final typed = widget.typedConfirmation;
    // Opening the keyboard in a phone sheet can scroll the warning away
    // before its first line can be read.
    final focusField = typed != null && !widget.sheet;
    final yes = _ready ? widget.onConfirm : null;
    final footer = termKeysShown(context) ? words.cancelKeyHint : null;
    // What to type, and the field it goes in, stand with the buttons, out
    // of the message's scroll: however long the message runs (twice the
    // text on a phone, a long name), only the message scrolls, and the
    // field is whole.
    final Widget? typedPart = typed == null
        ? null
        // What to type is in the field's label while the frame has room
        // for it; where it would be cut, it is a line of its own above, so
        // the words to type always show whole.
        : LayoutBuilder(
            builder: (context, c) {
              final ask = words.typedConfirmationLabel(typed);
              final fits =
                  !c.maxWidth.isFinite ||
                  grid.widthOf(ask) <= c.maxWidth - grid.cols(4);
              final field = TermTextField(
                controller: _typed,
                autofocus: focusField,
                labelText: fits ? ask : words.typedConfirmationFieldLabel,
                prompt: '>',
                autocorrect: false,
                onSubmitted: (_) => yes?.call(),
              );
              if (fits) return field;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The words to type in bold, wherever the language
                  // puts them.
                  Text.rich(
                    TextSpan(
                      children: switch (typed.isEmpty
                          ? -1
                          : ask.indexOf(typed)) {
                        < 0 => [TextSpan(text: ask)],
                        final at => [
                          TextSpan(text: ask.substring(0, at)),
                          TextSpan(text: typed, style: theme.boldStyle),
                          TextSpan(text: ask.substring(at + typed.length)),
                        ],
                      },
                    ),
                  ),
                  field,
                ],
              );
            },
          );
    final Widget content = typed != null
        ? Text(widget.message)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.message),
              SizedBox(height: grid.lineHeight),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${words.confirmPrompt} '),
                    TextSpan(text: '[y/', style: theme.dimStyle),
                    TextSpan(text: 'N', style: theme.boldStyle),
                    TextSpan(text: ']', style: theme.dimStyle),
                  ],
                ),
                semanticsLabel: words.confirmPromptLabel,
              ),
            ],
          );
    // The question's `[y/N]` names the keys; the buttons don't again.
    final actions = [
      TermButton(
        label: termWords(context, widget.cancelLabel, 'no', (w) => w.noLabel),
        autofocus: !focusField,
        onPressed: widget.onCancel,
      ),
      TermButton(
        label: widget.confirmLabel,
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
      child: typedPart == null
          ? dialog
          : _ModalFixed(part: typedPart, child: dialog),
    );
  }
}

/// A part a dialog's pane keeps out of its body's scroll, between the body
/// and the buttons: a typed confirmation's field.
class _ModalFixed extends InheritedWidget {
  const _ModalFixed({required this.part, required super.child});

  final Widget part;

  static Widget? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ModalFixed>()?.part;

  @override
  bool updateShouldNotify(_ModalFixed old) => old.part != part;
}

/// Asks [message] as a y/N question and completes with true for yes, false
/// for no and null when dismissed. See [TermConfirmDialog]. Under 600 wide
/// it stands as a sheet at the foot of the screen, where a thumb reaches;
/// [sheet] decides it instead when given.
///
/// ```dart
/// final sure = await showTermConfirmDialog(
///   context: context,
///   title: 'delete logs',
///   message: "run #1482's logs go for good",
///   confirmLabel: 'delete',
///   isDestructiveAction: true,
/// );
/// ```
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
  // A question that wants an answer: an alert to a screen reader, though a
  // tap outside still answers null, as Escape does.
  return asSheet
      ? showTermSheet<bool>(
          context: context,
          isAlert: true,
          barrierDismissible: true,
          builder: question,
        )
      : showTermDialog<bool>(
          context: context,
          isAlert: true,
          barrierDismissible: true,
          builder: question,
        );
}

/// A sheet: a raised pane standing at the foot of the screen (on a phone's
/// window list, where there is one), [title] cut
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
  ///
  /// Left as `'esc close'`, it is the reader's words for it
  /// (`TermLocalizations.closeKeyHint`): Arabic or German in an app in either.
  final String? footer;

  /// The most cells across it takes on a wide screen.
  final int cols;

  @override
  Widget build(BuildContext context) {
    return _ModalPane(
      title: title,
      footer: switch (footer) {
        final f? => termWords(context, f, 'esc close', (w) => w.closeKeyHint),
        null => null,
      },
      cols: cols,
      content: child,
      actions: actions,
      style: TermStyle.layered([style, TermTheme.of(context).sheetStyle]),
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

// Dialogs and sheets share their title, scrolling body and fixed actions.
class _ModalPane extends StatefulWidget {
  const _ModalPane({
    this.title,
    this.footer,
    required this.cols,
    this.content,
    required this.actions,
    required this.style,
  });
  final String? title;
  final String? footer;
  final int cols;
  final Widget? content;
  final List<Widget> actions;
  final TermStyle style;

  @override
  State<_ModalPane> createState() => _ModalPaneState();
}

class _ModalPaneState extends State<_ModalPane> {
  // Which way the body has more than it shows: '↓' below, '↑' above only,
  // null when it shows it all.
  final _more = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _more.dispose();
    super.dispose();
  }

  bool _measure(ScrollMetrics m) {
    if (m.axis == Axis.vertical) {
      _more.value = m.extentAfter > 0.5
          ? '↓'
          : m.extentBefore > 0.5
          ? '↑'
          : null;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final theme = TermTheme.of(context);
    final title = widget.title;
    final footer = widget.footer;
    final content = widget.content;
    final actions = widget.actions;
    final fixed = _ModalFixed.of(context);
    // The line after the body. Where the body is cut, its end says which
    // way the rest is, as a pager's last line does: a cut line reads as a
    // window onto more, not as a part left open.
    final cue = SizedBox(
      height: grid.lineHeight,
      child: ValueListenableBuilder<String?>(
        valueListenable: _more,
        builder: (context, more, _) => more == null
            ? const SizedBox.shrink()
            : Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ExcludeSemantics(
                  child: Text(more, style: theme.dimStyle),
                ),
              ),
      ),
    );
    return Semantics(
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: _OnCells(
        cols: widget.cols,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heading = title;
            final inside =
                heading != null &&
                grid.widthOf(heading) > constraints.maxWidth - grid.cols(4);
            return TermPane(
              title: inside ? null : heading,
              footer: termKeysShown(context) ? footer : null,
              raised: true,
              focused: true,
              style: widget.style,
              child: Padding(
                padding: EdgeInsets.only(top: grid.lineHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (content != null || inside)
                      Flexible(
                        child: NotificationListener<ScrollMetricsNotification>(
                          onNotification: (n) => _measure(n.metrics),
                          child: NotificationListener<ScrollUpdateNotification>(
                            onNotification: (n) => _measure(n.metrics),
                            child: TermWholeLines(
                              child: SingleChildScrollView(
                                child: inside
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Semantics(
                                            header: true,
                                            child: Text(
                                              heading,
                                              style: TermTheme.of(context)
                                                  .boldStyle,
                                            ),
                                          ),
                                          if (content != null) ...[
                                            SizedBox(height: grid.lineHeight),
                                            content,
                                          ],
                                        ],
                                      )
                                    : content,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (fixed != null) ...[cue, fixed],
                    if (actions.isNotEmpty) ...[
                      if (fixed == null)
                        cue
                      else
                        SizedBox(height: grid.lineHeight),
                      // One row at the end when they fit, else one column
                      // of one width, the strongest on top, as every look's
                      // dialog stacks them: never two on a line and one
                      // alone under them. Each button already stands on a
                      // whole tap target, so stacked buttons need no blank
                      // line between them: at large text that line cut the
                      // body short of a field's last line.
                      RawActionBar(
                        spacing: grid.cellWidth,
                        overflowSpacing: 0,
                        children: actions,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Raises the sheet [builder] makes at the foot of the screen, the screen
/// behind dimmed, and completes with what it pops. On ui_core's bottom sheet
/// route, as the family's sheets: it stands on the window list and the
/// status line (the bar shows under the dimmed screen, and a tap on it
/// closes the sheet), it keeps the focus inside while open, and a tap
/// outside (when [barrierDismissible]), Escape or Android's back closes it.
/// Like a dialog it comes up where it stays, in a very short fade on
/// [TermMotion.surface]. [isAlert] and [semanticLabel] are
/// [showTermDialog]'s.
Future<T?> showTermSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool isAlert = false,
  String? semanticLabel,
  bool useRootNavigator = true,
}) {
  final theme = TermTheme.of(context);
  final words = RawWidgetsLocalizations.of(context);
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<T>(
    _TermSheetRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierColor: theme.background.withValues(alpha: 0.72),
      barrierLabel: words.modalBarrierDismissLabel,
      semanticLabel: isAlert
          ? semanticLabel ?? words.alertDialogLabel
          : semanticLabel,
      builder: (context, details) {
        final grid = context.termGrid;
        // The sheet's ground runs edge to edge and down to the foot of
        // its room, so nothing of the screen shows in a margin beside it;
        // half a line under the top of the screen stays clear.
        Widget sheet = LayoutBuilder(
          builder: (context, room) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: math.max(0, room.maxHeight - grid.lineHeight * 0.5),
            ),
            child: ColoredBox(
              color: TermTheme.of(context).background,
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
        );
        // A question that wants an answer is an alert to a screen reader.
        if (isAlert) {
          sheet = Semantics(role: SemanticsRole.alertDialog, child: sheet);
        }
        // The route raises its panel from the foot by its animation;
        // Terminal's surfaces come up where they stay, so the panel is held at
        // its rest by that same animation (under Reduce Motion the route's
        // panel already stands, and its presence is always complete).
        final presence = ModalRoute.of(context)!.animation!;
        final stands = details.animation == kAlwaysCompleteAnimation;
        return themes.wrap(
          AnimatedBuilder(
            animation: presence,
            builder: (context, child) => FractionalTranslation(
              translation: Offset(
                0,
                stands ? 0 : presence.value.clamp(0.0, 1.0) - 1,
              ),
              child: child,
            ),
            child: sheet,
          ),
        );
      },
    ),
  );
}

// ui_core's bottom sheet on Terminal's surface spring: it fades up where it
// stays, as Terminal's dialogs and side sheets do (showTermSheet holds the
// panel at its rest), and, as before, no drag moves it.
class _TermSheetRoute<T> extends RawBottomSheetRoute<T> {
  _TermSheetRoute({
    required super.builder,
    required super.barrierDismissible,
    required super.barrierColor,
    required super.barrierLabel,
    super.semanticLabel,
  }) : super(
         useSafeArea: true,
         enableDrag: false,
         dampingRatio: TermMotion.surface.dampingRatio,
         stiffness: TermMotion.surface.stiffness,
       );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
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
