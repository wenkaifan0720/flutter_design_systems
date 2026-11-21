import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/button_face.dart';
import '../../theme.dart';

enum _Kind { primary, secondary, start }

/// A button that says what happens next: a face with slightly rounded
/// corners on a solid bottom edge of a deeper tone, which a press sinks
/// onto. The unnamed constructor is the page's one action (Continue, Send
/// application), solid in the action colour; [CivicButton.secondary] is an
/// action beside it, a face of the action's tint with its words in the
/// action colour and no stroke round it; [CivicButton.start] begins a
/// service.
///
/// [isDestructiveAction] draws it in the error colour, for a button that
/// confirms or starts a loss: solid in a dialog, the error's tint
/// (secondary) on a page, never as a page's loudest thing. Below 600 wide it spans its
/// column, as a phone's action does; from 600 it keeps the width of its
/// words; [expand] says otherwise. A
/// pointer over it deepens its face; a keyboard focus floods the face
/// yellow and turns its edge to the ink bar.
///
/// While its press is being sent, [busy]: its words cross to a turning
/// arc and [busyLabel] ("Sending"), which a screen reader hears, and it
/// takes no press, so nobody sends twice, while keeping its focus and its
/// width (give [busyLabel] up front and the face is as wide as the wider of
/// the two words throughout).
///
/// Reads [CivicStyle]'s fill, foreground, edge, side (a stroke round the
/// face, none by default), padding, minimumSize (a face never stands lower than its 48
/// points), textStyle and iconSize:
/// its `style:` first, then its kind's theme
/// ([CivicThemeData.primaryButtonStyle], [CivicThemeData.secondaryButtonStyle],
/// [CivicThemeData.startButtonStyle], [CivicThemeData.destructiveButtonStyle]).
/// Its corners, its solid edge and the focus flood are the look's and take
/// no style.
///
/// ```dart
/// CivicButton(
///   onPressed: () => Navigator.of(context).pushNamed('/check'),
///   child: const Text('Continue'),
/// )
/// ```
class CivicButton extends StatelessWidget {
  /// The page's action.
  const CivicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDestructiveAction = false,
    this.icon,
    this.expand,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.busy = false,
    this.busyLabel,
  }) : _kind = _Kind.primary;

  /// The page's action from its words alone: `CivicButton.label('Continue',
  /// onPressed: ...)` is `CivicButton(child: Text('Continue'), ...)`. What
  /// generated code writes, where the words are all it has.
  CivicButton.label(
    String label, {
    super.key,
    required this.onPressed,
    this.isDestructiveAction = false,
    this.icon,
    this.expand,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.busy = false,
    this.busyLabel,
  }) : child = Text(label),
       _kind = _Kind.primary;

  /// An action beside the page's one: Save and come back later, Cancel.
  const CivicButton.secondary({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDestructiveAction = false,
    this.icon,
    this.expand,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.busy = false,
    this.busyLabel,
  }) : _kind = _Kind.secondary;

  /// The start of a service, larger, with an arrow: Start now.
  const CivicButton.start({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon = LucideIcons.arrowRight,
    this.expand,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.busy = false,
    this.busyLabel,
  }) : isDestructiveAction = false,
       _kind = _Kind.start;

  final _Kind _kind;

  /// Called on a press; null disables the button.
  final VoidCallback? onPressed;

  /// The words: what happens next.
  final Widget child;

  /// Whether the button confirms a loss: drawn in the error colour.
  final bool isDestructiveAction;

  /// A glyph after the words; the start button's arrow turns with the
  /// reading direction.
  final IconData? icon;

  /// Whether the button spans its column; null spans it below 600 wide and
  /// keeps the width of its words from 600, even in a column that
  /// stretches its children.
  final bool? expand;

  /// Overrides for this button's look.
  final CivicStyle? style;

  /// {@template civic.focusNode}
  /// The focus node, which the caller disposes; null makes one of its own.
  /// {@endtemplate}
  final FocusNode? focusNode;

  /// {@template civic.autofocus}
  /// Whether it takes the focus when it first appears.
  /// {@endtemplate}
  final bool autofocus;

  /// {@template civic.statesController}
  /// The states it is drawn in, as Flutter's buttons take them: add
  /// [WidgetState.focused] to show its focus without a keyboard (a
  /// specimen). The caller disposes it; null keeps its own.
  /// {@endtemplate}
  final WidgetStatesController? statesController;

  /// Whether its press is being sent: it shows [busyLabel] by a turning
  /// arc and takes no press.
  final bool busy;

  /// The words while [busy] ("Sending"); null: "Loading" in the reader's
  /// language.
  final String? busyLabel;

  static void _hold() {}

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.maybeSizeOf(context)?.width ?? 1024;
    final stretch = expand ?? width < CivicLayout.medium;
    // Spans a bounded column without a LayoutBuilder, so a dialog or a row
    // can still measure the button by its words.
    return _Stretch(
      stretch: stretch,
      child: TapTargetPadding(
        child: RawButton(
          // Busy, it keeps its focus and its look: it takes the press and
          // does nothing with it.
          onPressed: busy && onPressed != null ? _hold : onPressed,
          focusNode: focusNode,
          autofocus: autofocus,
          statesController: statesController,
          mouseCursor: onPressed == null
              ? SystemMouseCursors.basic
              : busy
              ? SystemMouseCursors.progress
              : SystemMouseCursors.click,
          builder: (context, states, _) => CivicButtonFace(
            states: states,
            kind: switch (_kind) {
              _Kind.primary => CivicButtonKind.primary,
              _Kind.secondary => CivicButtonKind.secondary,
              _Kind.start => CivicButtonKind.start,
            },
            destructive: isDestructiveAction,
            icon: icon,
            style: style,
            busy: busy,
            busyLabel: busyLabel,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<_Kind>('kind', _kind))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        FlagProperty(
          'isDestructiveAction',
          value: isDestructiveAction,
          ifTrue: 'destructive',
        ),
      )
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('expand', expand, defaultValue: null))
      ..add(DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(FlagProperty('busy', value: busy, ifTrue: 'busy'))
      ..add(StringProperty('busyLabel', busyLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<WidgetStatesController>(
          'statesController',
          statesController,
          defaultValue: null,
        ),
      );
  }
}

/// Gives its child the whole of a bounded width when [stretch]; otherwise
/// lets it keep its own width at the start of a column that would stretch
/// it. Every other constraint, and every measure, passes through.
class _Stretch extends SingleChildRenderObjectWidget {
  const _Stretch({required this.stretch, super.child});

  final bool stretch;

  @override
  _RenderStretch createRenderObject(BuildContext context) =>
      _RenderStretch(stretch, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderStretch renderObject) =>
      renderObject
        ..stretch = stretch
        ..direction = Directionality.of(context);
}

class _RenderStretch extends RenderShiftedBox {
  _RenderStretch(this._stretch, this._direction) : super(null);

  bool _stretch;
  set stretch(bool value) {
    if (value == _stretch) return;
    _stretch = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  BoxConstraints _inner(BoxConstraints constraints) => _stretch
      ? (constraints.hasBoundedWidth
            ? constraints.tighten(width: constraints.maxWidth)
            : constraints)
      : constraints.copyWith(minWidth: 0);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) => constraints
      .constrain(child?.getDryLayout(_inner(constraints)) ?? Size.zero);

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) => child?.getDryBaseline(_inner(constraints), baseline);

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_inner(constraints), parentUsesSize: true);
    size = constraints.constrain(child.size);
    final spare = size.width - child.size.width;
    (child.parentData! as BoxParentData).offset = Offset(
      _direction == TextDirection.rtl ? spare : 0,
      0,
    );
  }
}
