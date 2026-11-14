/// Toasts: the snackbar, with one action, above the FAB and the bar (CONTRACT
/// §4.1 `toast`; §4.2 `showExpressiveSnackBar`). Owner: w2-toast, with
/// `test/toast_test.dart` and the gallery's toast demo.
///
/// A port of Compose material3 1.5.0-alpha29 (wave decision F1):
///
/// - [ExpressiveSnackBar] is `Snackbar(snackbarData)`: a `Surface` in
///   `SnackbarTokens`' inverse colours, extra-small corners and level-3
///   shadow, the message in `bodyMedium`, one action (Compose's plain `TextButton`
///   — 12dp side padding, 58 × 40dp least — in `inversePrimary` as
///   `textButtonColors(contentColor = actionColor)`) and an optional dismiss (a standard icon button with the
///   close glyph). It lays out as the pin draws it —
///   `ComposeMaterial3Flags.isSnackbarStylingFixEnabled` is false there, so
///   `LegacyOneRowSnackbar` and `LegacyNewLineButtonSnackbar`: one line
///   centres in 48dp with the action on the text's baseline; more lines put
///   the first baseline 30dp down in at least 68dp; `actionOnNewLine`
///   stacks the action row under the text.
/// - [showExpressiveSnackBar] is `SnackbarHostState.showSnackbar` on a host
///   in the root overlay: one toast at a time, the rest queued in order; the
///   one leaving fades on `fastEffects` and scales to 0.8 on `fastSpatial`
///   while the next enters the same way (`FadeInFadeOutWithScale`); short
///   and long toasts time out as `SnackbarDuration.toMillis`. It stands
///   above the shell's bar and floating action button
///   ([ExpressiveShellInsets]), the system inset and the keyboard.
///
/// Deviations: a toast with an action defaults to
/// [ExpressiveSnackBarDuration.short] (4 s) rather than Compose's `Indefinite`:
/// a generated app's undo toast must not hold the queue until tapped, and
/// v2's promise (Cody's action toast lingers 4.2 s) is what generated-app
/// walkthroughs drain — two bounded 2.5 s pumps, which a 10 s timer would
/// outlive ("A Timer is still pending"). Android's accessibility timeout scaling is not applied.
/// The enter/exit springs settle at `Animatable`'s default visibility
/// threshold (animation-core's `Spring.DefaultDisplacementThreshold`,
/// 0.01) as Compose's do, not at the kit's finer [designSpringTolerance]. `icon`
/// is accepted and not drawn (CONTRACT §4.2).
library;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../elevation.dart';
import '../icons.dart';
import '../internal/docked_band.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/button_small_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/snackbar_tokens.g.dart';
import '../motion.dart';
import '../states.dart';
import '../internal/styled_content.dart';
import '../strings.dart';
import '../theme.dart';
import 'icon_buttons.dart';
import 'shell_insets.dart';

/// How long a snackbar stays up (Compose's `SnackbarDuration`).
enum ExpressiveSnackBarDuration {
  /// `SnackbarHostBehavior.shortDuration` (4 s).
  short,

  /// `SnackbarHostBehavior.longDuration` (10 s).
  long,

  /// Until its action or close button is tapped, or it is dismissed.
  indefinite;

  /// How long it keeps a snackbar up; null for [indefinite].
  Duration? get timeout => switch (this) {
    short => Duration(milliseconds: SnackbarHostBehavior.shortDuration),
    long => Duration(milliseconds: SnackbarHostBehavior.longDuration),
    indefinite => null,
  };
}

/// Shows [message] as a snackbar (Material's `ScaffoldMessenger.showSnackBar`
/// with a `SnackBar`, Compose's `SnackbarHostState.showSnackbar`): a
/// transient bottom notification above the shell's bar and action — a
/// confirmation the page does not have to hold — after any snackbar already
/// showing or queued. [actionLabel] + [onAction] add ONE inline action — the
/// undo pattern; tapping it dismisses the snackbar and runs [onAction].
/// [withDismissAction] adds the close button; [actionOnNewLine] puts the
/// action under a long message. [duration] defaults to short, with or
/// without an action.
///
/// ```dart
/// showExpressiveSnackBar(context, 'Message archived', actionLabel: 'Undo', onAction: undo);
/// ```
void showExpressiveSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  bool withDismissAction = false,
  bool actionOnNewLine = false,
  ExpressiveSnackBarDuration? duration,
  ExpressiveComponentThemeData? style,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final media = MediaQuery.of(overlay.context);
  // The shell's allowance is measured from the display edge and already
  // spans the device inset (and the FAB with its gap), so the insets are
  // a max, not a sum.
  final bottom = math.max(
    math.max(media.padding.bottom, media.viewInsets.bottom),
    // The shell's bar, or the route's own docked footer or bar.
    math.max(
      ExpressiveShellInsets.of(context),
      expressiveDockedBandOf(context),
    ),
  );
  final queue = _queues[overlay] ??= _ToastQueue(overlay);
  queue.enqueue(
    _ToastRequest(
      message: message,
      style: style,
      actionLabel: actionLabel,
      onAction: onAction,
      withDismissAction: withDismissAction,
      actionOnNewLine: actionOnNewLine,
      duration: duration ?? ExpressiveSnackBarDuration.short,
      bottom: bottom,
      themes: InheritedTheme.capture(from: context, to: overlay.context),
    ),
  );
}

/// Dismisses the snackbar showing over [context]'s root overlay, if any; the
/// next queued one follows (Material's
/// `ScaffoldMessenger.hideCurrentSnackBar`).
void hideCurrentExpressiveSnackBar(BuildContext context) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _queues[overlay]?.current?.dismiss();
}

/// The snackbar itself (Compose's `Snackbar`, Material's `SnackBar`):
/// [message] on the inverse surface, with an optional action and close
/// button. [showExpressiveSnackBar] raises one; place it yourself only to
/// show one inline (a gallery, a custom host).
class ExpressiveSnackBar extends StatelessWidget {
  /// A snackbar showing [message].
  const ExpressiveSnackBar(
    this.message, {
    this.actionLabel,
    this.onAction,
    this.withDismissAction = false,
    this.onDismiss,
    this.actionOnNewLine = false,
    this.content,
    this.style,
    super.key,
  });

  /// Stateful visual overrides before the snackbar theme.
  final ExpressiveComponentThemeData? style;

  /// The message: one line, or several.
  final String message;

  /// The message as a widget, in place of [message]'s text (Compose's
  /// content slot): it inherits `bodyMedium` in the content colour, and
  /// must be one text of that style for the layout to tell its lines.
  final Widget? content;

  /// The action's label; no action when null.
  final String? actionLabel;

  /// What the action does.
  final VoidCallback? onAction;

  /// Whether a close button follows the action.
  final bool withDismissAction;

  /// What the close button does.
  final VoidCallback? onDismiss;

  /// Whether the action sits on its own line under the message (for a
  /// long action label). Without an action it has no effect.
  final bool actionOnNewLine;

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final colors = theme.colors;
    const states = <WidgetState>{};
    final resolved = theme.snackBarTheme.merge(style);
    final container = ExpressiveComponentThemeData.resolve(
      resolved.backgroundColor,
      states,
      colors.role(SnackbarTokens.containerColor),
    );
    Color inked(Color fallback) => ExpressiveComponentThemeData.resolve(
      resolved.foregroundColor,
      states,
      fallback,
    );
    final ink = inked(colors.role(SnackbarTokens.supportingTextColor));
    final textStyle = theme.type
        .of(SnackbarTokens.supportingTextFont)
        .merge(resolved.textStyle?.resolve(states))
        .copyWith(color: ink);
    final label = actionLabel;
    final action = label == null
        ? null
        : _SnackbarAction(
            label: label,
            color: colors.role(SnackbarTokens.actionLabelTextColor),
            onTap: onAction,
          );
    final dismiss = withDismissAction
        ? IconTheme.merge(
            data: IconThemeData(
              color: inked(colors.role(SnackbarTokens.iconColor)),
            ),
            child: ExpressiveIconButton(
              ExpressiveSymbols.close,
              onPressed: onDismiss,
              semanticLabel: ExpressiveLocalizations.of(context).toastDismiss,
              tooltip: ExpressiveLocalizations.of(context).toastDismiss,
            ),
          )
        : null;
    return ExpressiveSurface(
      style: style,
      componentStyle: theme.snackBarTheme,
      shape: theme.shapes.of(SnackbarTokens.containerShape),
      color: container,
      contentColor: ink,
      shadowElevation: SnackbarTokens.containerElevation,
      child: DefaultTextStyle.merge(
        style: textStyle,
        child: _SnackbarLayout(
          actionOnNewLine: actionOnNewLine && action != null,
          density: theme.density,
          customPadding: resolved.padding?.resolve(states) != null,
          lineHeight: _lineHeight(context, textStyle),
          textDirection: Directionality.of(context),
          text: content ?? Text(message, style: textStyle),
          action: action,
          dismiss: dismiss,
        ),
      ),
    );
  }

  /// One line of [style] at the ambient text scale: how the layout tells
  /// one line from several (Compose compares the first and last baselines).
  static double _lineHeight(BuildContext context, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      textHeightBehavior: DefaultTextHeightBehavior.maybeOf(context),
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }
}

/// The snackbar's action: Compose's plain `TextButton(colors =
/// textButtonColors(contentColor = actionColor))` — `textShape` (the small
/// round shape, no press morph), `TextButtonContentPadding` (12dp at the
/// sides, 8dp above and below), `ButtonDefaults.MinWidth` × `MinHeight`
/// (58 × 40dp) inside the 48dp touch target, the label in `labelLarge`.
/// The buttons family's text button pads at its size's 16dp, which would
/// take up to 8dp from the message, so the snackbar draws its own (F3's
/// smallest extension, on the shared pressable).
class _SnackbarAction extends StatelessWidget {
  const _SnackbarAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    return ExpressivePressable(
      componentStyle: theme.buttonTheme,
      shapes: ExpressivePressShapes.all(
        theme.shapes.of(ButtonSmallTokens.containerShapeRound),
      ),
      motion: ButtonBehavior.pressMotion,
      color: expressiveTransparent,
      contentColor: color,
      onPressed: onTap,
      child: ExpressiveStyledContent(
        minimumSize: const Size(
          ButtonBehavior.minWidth,
          ButtonSmallTokens.containerHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AlertDialogBehavior.actionHorizontalPadding,
          vertical: ButtonBehavior.verticalPadding,
        ),
        textStyle: theme.type.of(ExpressiveTypeKey.labelLarge),
        child: Text(label),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout: LegacyOneRowSnackbar and LegacyNewLineButtonSnackbar.

enum _Slot { text, action, dismiss }

class _SnackbarLayout
    extends SlottedMultiChildRenderObjectWidget<_Slot, RenderBox> {
  const _SnackbarLayout({
    required this.actionOnNewLine,
    required this.lineHeight,
    required this.textDirection,
    required this.text,
    required this.density,
    required this.customPadding,
    this.action,
    this.dismiss,
  });

  final bool actionOnNewLine;
  final ExpressiveDensity density;
  final bool customPadding;
  final double lineHeight;
  final TextDirection textDirection;
  final Widget text;
  final Widget? action;
  final Widget? dismiss;

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => switch (slot) {
    _Slot.text => text,
    _Slot.action => action,
    _Slot.dismiss => dismiss,
  };

  @override
  _RenderSnackbar createRenderObject(BuildContext context) => _RenderSnackbar(
    actionOnNewLine: actionOnNewLine,
    density: density,
    customPadding: customPadding,
    lineHeight: lineHeight,
    textDirection: textDirection,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderSnackbar renderObject) {
    renderObject
      ..actionOnNewLine = actionOnNewLine
      ..density = density
      ..customPadding = customPadding
      ..lineHeight = lineHeight
      ..textDirection = textDirection;
  }
}

class _RenderSnackbar extends RenderBox
    with SlottedContainerRenderObjectMixin<_Slot, RenderBox> {
  _RenderSnackbar({
    required this._actionOnNewLine,
    required this._density,
    required this._customPadding,
    required this._lineHeight,
    required this._textDirection,
  });

  ExpressiveDensity _density;
  set density(ExpressiveDensity value) {
    if (value == _density) return;
    _density = value;
    markNeedsLayout();
  }

  bool _customPadding;
  set customPadding(bool value) {
    if (value == _customPadding) return;
    _customPadding = value;
    markNeedsLayout();
  }

  double get _start => _customPadding
      ? 0
      : _density
            .padding(const EdgeInsets.all(SnackbarBehavior.horizontalSpacing))
            .left;
  double get _end => _customPadding
      ? 0
      : _density
            .padding(
              const EdgeInsets.all(
                SnackbarBehavior.horizontalSpacingButtonSide,
              ),
            )
            .right;
  double _height(double token) => _density.height(token);

  bool _actionOnNewLine;
  set actionOnNewLine(bool value) {
    if (value == _actionOnNewLine) return;
    _actionOnNewLine = value;
    markNeedsLayout();
  }

  double _lineHeight;
  set lineHeight(double value) {
    if (value == _lineHeight) return;
    _lineHeight = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _text => childForSlot(_Slot.text)!;
  RenderBox? get _action => childForSlot(_Slot.action);
  RenderBox? get _dismiss => childForSlot(_Slot.dismiss);

  /// Paint order, and hit-test order reversed: the buttons over the text.
  @override
  Iterable<RenderBox> get children => <RenderBox>[
    ?childForSlot(_Slot.text),
    ?_action,
    ?_dismiss,
  ];

  double get _textPadding => _customPadding
      ? 0
      : _density
            .padding(const EdgeInsets.all(SnackbarBehavior.verticalPadding))
            .top;

  /// The text's first and last baselines from its own top (its lines are
  /// of one height, so the last sits the text's height less a line below
  /// the first).
  (double, double) _baselines(RenderBox text) {
    final first =
        text.getDistanceToBaseline(TextBaseline.alphabetic) ?? text.size.height;
    return (first, first + math.max(0, text.size.height - _lineHeight));
  }

  bool _isOneLine(RenderBox text) => text.size.height < _lineHeight * 1.5;

  void _place(RenderBox child, double x, double y) {
    final data = child.parentData! as BoxParentData;
    data.offset = Offset(
      _textDirection == TextDirection.rtl
          ? size.width - x - child.size.width
          : x,
      y,
    );
  }

  @override
  void performLayout() {
    if ((_actionOnNewLine || constraints.maxWidth < 200) && _action != null) {
      _layoutNewLine();
    } else {
      _layoutOneRow();
    }
  }

  /// `LegacyOneRowSnackbar`.
  void _layoutOneRow() {
    final action = _action;
    final dismiss = _dismiss;
    final text = _text;
    final start = _start;
    final end = dismiss == null ? _end : 0.0;
    final innerMax = math.max(0.0, constraints.maxWidth - start - end);
    // At most the container's 600dp; a parent that sizes the bar wider (a
    // column that stretches it) gets a container that wide, its action at
    // the end of it.
    final containerWidth = math.max(
      math.min(innerMax, SnackbarBehavior.containerMaxWidth),
      math.min(innerMax, constraints.minWidth - start - end),
    );
    final loose = BoxConstraints(maxWidth: innerMax);
    action?.layout(loose, parentUsesSize: true);
    dismiss?.layout(loose, parentUsesSize: true);
    final actionWidth = action?.size.width ?? 0;
    final actionHeight = action?.size.height ?? 0;
    final dismissWidth = dismiss?.size.width ?? 0;
    final dismissHeight = dismiss?.size.height ?? 0;
    final extra = dismissWidth == 0 ? SnackbarBehavior.textEndExtraSpacing : 0;
    final textMaxWidth = math.max(
      0.0,
      containerWidth - actionWidth - dismissWidth - extra,
    );
    text.layout(BoxConstraints(maxWidth: textMaxWidth), parentUsesSize: true);
    // Compose pads the text's box above and below.
    final textBoxHeight = text.size.height + _textPadding + _textPadding;
    final (first, _) = _baselines(text);
    final firstBaseline = first + _textPadding;

    final double containerHeight;
    final double textY;
    final double actionY;
    if (_isOneLine(text)) {
      // Compose's max(48, the buttons); the padded text too, so a line of
      // large text keeps its 6dp above and below.
      containerHeight = math.max(
        _height(SnackbarTokens.singleLineContainerHeight),
        math.max(math.max(actionHeight, dismissHeight), textBoxHeight),
      );
      textY = (containerHeight - textBoxHeight) / 2;
      final actionBaseline = action?.getDistanceToBaseline(
        TextBaseline.alphabetic,
      );
      actionY = actionBaseline == null
          ? 0
          : textY + firstBaseline - actionBaseline;
    } else {
      textY = SnackbarBehavior.heightToFirstLine - firstBaseline;
      containerHeight = math.max(
        _height(SnackbarTokens.twoLinesContainerHeight),
        textY + textBoxHeight,
      );
      actionY = (containerHeight - actionHeight) / 2;
    }
    final dismissY = (containerHeight - dismissHeight) / 2;
    size = constraints.constrain(
      Size(start + containerWidth + end, containerHeight),
    );
    final dismissX = start + containerWidth - dismissWidth;
    final actionX = dismissX - actionWidth;
    _place(text, start, textY + _textPadding);
    if (action != null) _place(action, actionX, actionY);
    if (dismiss != null) _place(dismiss, dismissX, dismissY);
  }

  /// `LegacyNewLineButtonSnackbar`: the text over the action row.
  void _layoutNewLine() {
    final action = _action!;
    final dismiss = _dismiss;
    final text = _text;
    final start = _start;
    final width = math.max(
      math.min(constraints.maxWidth, SnackbarBehavior.containerMaxWidth),
      constraints.minWidth,
    );
    final textEnd = _end;
    text.layout(
      BoxConstraints(maxWidth: math.max(0.0, width - start - textEnd)),
      parentUsesSize: true,
    );
    // paddingFromBaseline(top = HeightToFirstLine, bottom =
    // LongButtonVerticalOffset).
    final (first, last) = _baselines(text);
    final textTop = math.max(0.0, SnackbarBehavior.heightToFirstLine - first);
    final textBottom = math.max(
      0.0,
      SnackbarBehavior.longButtonVerticalOffset - (text.size.height - last),
    );
    final rowEnd = dismiss == null ? _end : 0.0;
    final loose = BoxConstraints(maxWidth: math.max(0.0, width - start));
    action.layout(loose, parentUsesSize: true);
    dismiss?.layout(loose, parentUsesSize: true);
    final rowWidth = action.size.width + (dismiss?.size.width ?? 0);
    final stacked = dismiss != null && rowWidth > width - start - rowEnd;
    final rowHeight = stacked
        ? action.size.height + dismiss.size.height
        : math.max(action.size.height, dismiss?.size.height ?? 0);
    final rowTop = textTop + text.size.height + textBottom;
    size = constraints.constrain(
      Size(width, rowTop + rowHeight + SnackbarBehavior.separateButtonExtraY),
    );
    _place(text, start, textTop);
    final actionX = width - rowEnd - (stacked ? action.size.width : rowWidth);
    _place(action, actionX, rowTop);
    if (dismiss != null) {
      _place(
        dismiss,
        stacked
            ? width - rowEnd - dismiss.size.width
            : actionX + action.size.width,
        stacked ? rowTop + action.size.height : rowTop,
      );
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) {
    final end = _dismiss == null ? _end : 0.0;
    final content =
        _text.getMaxIntrinsicWidth(height) +
        (_action?.getMaxIntrinsicWidth(height) ?? 0) +
        (_dismiss?.getMaxIntrinsicWidth(height) ??
            SnackbarBehavior.textEndExtraSpacing);
    return _start + math.min(content, SnackbarBehavior.containerMaxWidth) + end;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(SnackbarTokens.singleLineContainerHeight);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(SnackbarTokens.singleLineContainerHeight);

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    Size(
      math.max(
        math.min(constraints.maxWidth, SnackbarBehavior.containerMaxWidth),
        constraints.minWidth,
      ),
      _height(SnackbarTokens.singleLineContainerHeight),
    ),
  );

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      final data = child.parentData! as BoxParentData;
      context.paintChild(child, offset + data.offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children.toList().reversed) {
      final data = child.parentData! as BoxParentData;
      final hit = result.addWithPaintOffset(
        offset: data.offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  /// A `Surface` takes every touch on it.
  @override
  bool hitTestSelf(Offset position) => true;
}

// ---------------------------------------------------------------------------
// The host: SnackbarHostState's queue and FadeInFadeOutWithScale.

/// Each root overlay's queue of toasts.
final Expando<_ToastQueue> _queues = Expando<_ToastQueue>('ExpressiveSnackBar');

class _ToastRequest {
  _ToastRequest({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.withDismissAction,
    required this.actionOnNewLine,
    required this.duration,
    required this.bottom,
    required this.themes,
    required this.style,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool withDismissAction;
  final bool actionOnNewLine;
  final ExpressiveSnackBarDuration duration;
  final double bottom;
  final CapturedThemes themes;
  final ExpressiveComponentThemeData? style;

  /// Set by the queue while this toast is the current one.
  VoidCallback? _resolve;

  /// Takes the toast down (the timeout, the close button, the action,
  /// assistive technology's dismiss); the queue moves on.
  void dismiss() => _resolve?.call();
}

class _ToastQueue {
  _ToastQueue(this.overlay);

  final OverlayState overlay;
  final Queue<_ToastRequest> _pending = Queue<_ToastRequest>();

  /// The toast showing now.
  _ToastRequest? current;

  /// The current toast and those still animating out behind it.
  final List<_ToastRequest> _shown = <_ToastRequest>[];
  OverlayEntry? _entry;
  Timer? _timer;

  void enqueue(_ToastRequest request) {
    _pending.add(request);
    if (current == null) _next();
  }

  /// `SnackbarHostState`'s mutex: the next request becomes current the
  /// moment the last resolves, so the two cross-fade.
  void _next() {
    _timer?.cancel();
    _timer = null;
    if (_pending.isEmpty) {
      current = null;
      _entry?.markNeedsBuild();
      return;
    }
    final request = _pending.removeFirst();
    current = request;
    _shown.add(request);
    request._resolve = () {
      request._resolve = null;
      _next();
    };
    if (request.duration.timeout case final timeout?) {
      _timer = Timer(timeout, request.dismiss);
    }
    final entry = _entry;
    if (entry == null) {
      overlay.insert(_entry = OverlayEntry(builder: _build));
    } else {
      entry.markNeedsBuild();
    }
  }

  void _exited(_ToastRequest request) {
    _shown.remove(request);
    final entry = _entry;
    if (entry == null) return;
    if (_shown.isEmpty && current == null) {
      _entry = null;
      _queues[overlay] = null;
      entry
        ..remove()
        ..dispose();
    } else {
      entry.markNeedsBuild();
    }
  }

  /// The overlay went with the tree the toast stood in (a page, a preview,
  /// a test torn down): the timeout has nothing left to take down.
  void _abandon() {
    _timer?.cancel();
    _timer = null;
  }

  Widget _build(BuildContext context) =>
      _QueueLifetime(onDispose: _abandon, child: _layer());

  Widget _layer() => Positioned.fill(
    child: Stack(
      children: <Widget>[
        for (final request in _shown)
          Positioned(
            key: ObjectKey(request),
            left: 0,
            right: 0,
            bottom: request.bottom,
            child: Semantics(
              container: true,
              liveRegion: identical(request, current),
              onDismiss: identical(request, current) ? request.dismiss : null,
              child: ExcludeSemantics(
                excluding: !identical(request, current),
                child: IgnorePointer(
                  ignoring: !identical(request, current),
                  child: ExpressiveSnackBarTransition(
                    visible: identical(request, current),
                    onExited: () => _exited(request),
                    // `Snackbar(snackbarData)`'s margin, centred as
                    // `Scaffold` places the host.
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(SnackbarBehavior.margin),
                        child: request.themes.wrap(
                          ExpressiveSnackBar(
                            request.message,
                            style: request.style,
                            actionLabel: request.actionLabel,
                            onAction: request.actionLabel == null
                                ? null
                                : () {
                                    request.dismiss();
                                    request.onAction?.call();
                                  },
                            withDismissAction: request.withDismissAction,
                            onDismiss: request.dismiss,
                            actionOnNewLine: request.actionOnNewLine,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// How a toast enters and leaves (Compose's `FadeInFadeOutWithScale`
/// item): opacity on `SnackbarHostBehavior.opacityMotion` and scale about
/// the centre on `scaleMotion`, from and to `hiddenScale`. [child] enters
/// when first built [visible] and leaves when [visible] turns false, then
/// [onExited] runs. [showExpressiveSnackBar]'s host wraps every toast in one;
/// use it directly only for a toast in a custom host.
class ExpressiveSnackBarTransition extends StatefulWidget {
  /// A transition of [child], entering when [visible].
  const ExpressiveSnackBarTransition({
    required this.child,
    this.visible = true,
    this.onExited,
    super.key,
  });

  /// Whether the toast is showing: it springs in while true, out after.
  final bool visible;

  /// Runs once the toast has faded out.
  final VoidCallback? onExited;

  /// The toast.
  final Widget child;

  @override
  State<ExpressiveSnackBarTransition> createState() =>
      _ExpressiveSnackBarTransitionState();
}

class _ExpressiveSnackBarTransitionState
    extends State<ExpressiveSnackBarTransition>
    with TickerProviderStateMixin {
  late final AnimationController _opacity = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: SnackbarHostBehavior.hiddenScale,
  );

  @override
  void initState() {
    super.initState();
    // Compose starts the springs from a LaunchedEffect, after the frame
    // that composes the snackbar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animate(widget.visible);
    });
  }

  @override
  void didUpdateWidget(ExpressiveSnackBarTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) _animate(widget.visible);
  }

  /// `Animatable(Float)`'s default visibility threshold
  /// (`Spring.DefaultDisplacementThreshold`): Compose ends the host's
  /// springs once their envelope is inside it. The velocity bound is that
  /// distance at the spring's natural frequency, so an underdamped spring
  /// crossing the target at speed does not end early.
  static Tolerance _tolerance(SpringDescription spring) {
    const distance = 0.01;
    return Tolerance(
      distance: distance,
      velocity: math.sqrt(spring.stiffness / spring.mass) * distance,
    );
  }

  void _animate(bool visible) {
    final motion = ExpressiveMotion.of(context);
    final scale = motion.spring(SnackbarHostBehavior.scaleMotion);
    final opacity = motion.spring(SnackbarHostBehavior.opacityMotion);
    _scale.springTo(
      visible ? 1 : SnackbarHostBehavior.hiddenScale,
      scale,
      tolerance: _tolerance(scale),
    );
    _opacity
        .springTo(visible ? 1 : 0, opacity, tolerance: _tolerance(opacity))
        .orCancel
        .then((_) {
          if (mounted && !widget.visible) widget.onExited?.call();
        }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _opacity.dispose();
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge(<Listenable>[_opacity, _scale]),
    builder: (context, child) => Opacity(
      opacity: _opacity.value.clamp(0.0, 1.0),
      child: Transform.scale(scale: _scale.value, child: child),
    ),
    child: widget.child,
  );
}

/// Runs [onDispose] when the toast layer leaves the tree.
class _QueueLifetime extends StatefulWidget {
  const _QueueLifetime({required this.onDispose, required this.child});

  final VoidCallback onDispose;
  final Widget child;

  @override
  State<_QueueLifetime> createState() => _QueueLifetimeState();
}

class _QueueLifetimeState extends State<_QueueLifetime> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
