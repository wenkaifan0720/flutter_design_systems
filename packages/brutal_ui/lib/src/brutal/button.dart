/// Brutal's buttons: [BrutalButton] (a framed button with its hard shadow,
/// `.filled` for a screen's main action, `.text` for a quiet one),
/// [BrutalIconButton] and [BrutalSplitButton].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'feedback.dart' show BrutalSpinner;
import 'menu.dart';
import 'internal/focus_ink.dart';
import 'surface.dart';
import 'theme.dart';

enum _ButtonKind { framed, filled, text }

/// A button. Its face is square, in the look's one rule, and casts the hard
/// shadow; a press slides the face into the shadow until it is gone.
///
/// The unnamed constructor is the ordinary button (a white face);
/// [BrutalButton.filled] is a screen's one main action, in the signal
/// colour; [BrutalButton.text] has no frame, only its words on a rule that
/// thickens under a press. [isDestructiveAction] draws any of them in the
/// danger colour.
///
/// A null [onPressed] disables it: the rule and words go grey and the shadow
/// goes. It takes the width it is given when that is tight (a column that
/// stretches its children), and its content's otherwise.
///
/// Reads [style]'s `fill`, `foreground`, `edge`, `padding`, `minimumSize`,
/// `textStyle` and `iconSize`, then its kind's theme slot
/// ([BrutalThemeData.framedButtonStyle], [BrutalThemeData.filledButtonStyle]
/// or [BrutalThemeData.textButtonStyle]), with
/// [BrutalThemeData.destructiveButtonStyle] between them for a destructive
/// one. The rule's weight, the shadow and the square corners stay the
/// look's.
///
/// ```dart
/// BrutalButton.filled('Buy tickets', onPressed: () => checkout(), icon: const Icon(LucideIcons.ticket))
/// ```
class BrutalButton extends StatelessWidget {
  /// An ordinary button: a white face in the rule, with its shadow.
  const BrutalButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
    this.busy = false,
  }) : _kind = _ButtonKind.framed;

  /// A screen's one main action: a face in the signal colour.
  const BrutalButton.filled(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
    this.busy = false,
  }) : _kind = _ButtonKind.filled;

  /// A quiet action: its words on a 2 px rule, no frame and no shadow; a
  /// press thickens the rule. Its words stand on the line its neighbours
  /// start on, as it has no padding of its own.
  const BrutalButton.text(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
    this.busy = false,
  }) : _kind = _ButtonKind.text;

  /// What a press does; null disables the button.
  final VoidCallback? onPressed;

  /// What a long press does, when anything.
  final VoidCallback? onLongPress;

  /// The words: one line, cut short with an ellipsis when the button is
  /// narrower than they are.
  final String label;

  /// A glyph before the words, 20 px.
  final Widget? icon;

  /// Whether the action destroys something (cancels a ticket, deletes an
  /// account): drawn in the danger colour, as `CupertinoDialogAction` names
  /// it.
  final bool isDestructiveAction;

  /// This button's style, over its kind's theme slot.
  final BrutalStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Whether its action is under way: the words give way to a spinner in
  /// their colour (the button keeps its size) and a press does nothing.
  final bool busy;

  final _ButtonKind _kind;

  BrutalFace _face(BrutalThemeData theme, Set<WidgetState> states) =>
      _buttonFace(
        theme,
        states,
        kind: _kind,
        destructive: isDestructiveAction,
        style: style,
      );

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    return DesignPressable(
      onPressed: busy && onPressed != null ? _stay : onPressed,
      onLongPress: busy ? null : onLongPress,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticValue: busy ? 'busy' : null,
      builder: (context, states, _) {
        final layered = DesignStyleOf(
          _buttonLayers(theme, _kind, isDestructiveAction, style),
          states,
        );
        final face = _face(theme, states);
        final text = _kind == _ButtonKind.text;
        final padding =
            layered.padding(Directionality.of(context)) ??
            (text
                ? EdgeInsets.zero
                : EdgeInsets.symmetric(
                    horizontal: 20 + theme.density.paddingDelta,
                  ));
        final minimum = layered.minimumSize ?? Size(0, theme.controlHeight);
        final words = DefaultTextStyle.merge(
          // The face's words: the label's own colour is ink, which on
          // signal by night would be light words on orange.
          style: theme.textTheme.label
              .copyWith(color: face.foreground)
              .merge(layered.textStyle),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: DesignCapCenter(
            capHeightFactor: BrutalTheme.of(context).capHeightFactor,
            child: Text(label),
          ),
        );
        final row = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              IconTheme.merge(
                data: IconThemeData(size: layered.iconSize ?? 20),
                child: icon!,
              ),
              const SizedBox(width: BrutalSpacing.small),
            ],
            Flexible(
              child: text
                  ? _Underlined(
                      color: face.foreground,
                      width: theme.borderWidth,
                      pressed: states.contains(WidgetState.pressed),
                      child: words,
                    )
                  : words,
            ),
          ],
        );
        final Widget content = busy
            ? Stack(
                alignment: Alignment.center,
                children: [
                  // The words hold its size and still name it.
                  Opacity(opacity: 0, alwaysIncludeSemantics: true, child: row),
                  BrutalSpinner(size: 20, color: face.foreground),
                ],
              )
            : row;
        return DesignTapTarget(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minimum.width,
              minHeight: minimum.height,
            ),
            child: text
                ? BrutalSurface(
                    face: face.copyWith(travel: 0),
                    child: Padding(
                      padding: padding,
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: content,
                      ),
                    ),
                  )
                : AnimatedBrutalSurface(
                    face: face,
                    child: Padding(
                      padding: padding,
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: content,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(EnumProperty<_ButtonKind>('kind', _kind))
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      )
      ..add(FlagProperty('busy', value: busy, ifTrue: 'busy'))
      ..add(
        FlagProperty(
          'isDestructiveAction',
          value: isDestructiveAction,
          ifTrue: 'destructive',
        ),
      )
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A button's style layers, nearest first: its own, the destructive slot
/// for a destructive one, then its kind's slot.
List<BrutalStyle?> _buttonLayers(
  BrutalThemeData theme,
  _ButtonKind kind,
  bool destructive,
  BrutalStyle? style,
) => [
  style,
  if (destructive) theme.destructiveButtonStyle,
  switch (kind) {
    _ButtonKind.framed => theme.framedButtonStyle,
    _ButtonKind.filled => theme.filledButtonStyle,
    _ButtonKind.text => theme.textButtonStyle,
  },
];

/// A button's face in [states]: what [BrutalButton] and each half of
/// [BrutalSplitButton] draw.
BrutalFace _buttonFace(
  BrutalThemeData theme,
  Set<WidgetState> states, {
  required _ButtonKind kind,
  required bool destructive,
  BrutalStyle? style,
  List<BrutalStyle?>? layers,
}) {
  final c = theme.colors;
  final layered = DesignStyleOf(
    layers ?? _buttonLayers(theme, kind, destructive, style),
    states,
  );
  final disabled = states.contains(WidgetState.disabled);
  final pressed = states.contains(WidgetState.pressed);
  final focus = states.contains(WidgetState.focused)
      ? brutalFocusInk(c, kind == _ButtonKind.text ? c.surface : c.ink)
      : c.ink.withValues(alpha: 0);
  const clear = Color(0x00000000);
  if (kind == _ButtonKind.text) {
    final words = disabled
        ? c.disabled
        : destructive
        ? c.danger
        : c.ink;
    return BrutalFace(
      fill: clear,
      border: clear,
      foreground: layered.foreground ?? words,
      focus: focus,
      borderWidth: 0,
      travel: pressed ? 1 : 0,
    );
  }
  if (disabled) {
    return BrutalFace(
      fill: layered.fill ?? c.surface,
      border: layered.edge ?? c.disabled,
      foreground: layered.foreground ?? c.disabled,
      shadow: c.ink.withValues(alpha: 0),
    );
  }
  final fill = switch (kind) {
    _ButtonKind.filled => destructive ? c.danger : c.signal,
    _ => c.surface,
  };
  final words = switch (kind) {
    _ButtonKind.filled => destructive ? c.onDanger : c.onSignal,
    _ => destructive ? c.danger : c.ink,
  };
  // A fill of the caller's own takes black or white words by contrast.
  final given = layered.fill;
  return BrutalFace(
    fill: given ?? fill,
    border: layered.side?.color ?? layered.edge ?? c.ink,
    foreground:
        layered.foreground ?? (given == null ? words : c.onColor(given)),
    shadow: c.ink,
    travel: pressed ? 1 : 0,
    focus: focus,
  );
}

/// A text button's words over its rule: 2 px at rest, 4 px under a press,
/// on the look's press spring.
class _Underlined extends StatefulWidget {
  const _Underlined({
    required this.color,
    required this.width,
    required this.pressed,
    required this.child,
  });

  final Color color;
  final double width;
  final bool pressed;
  final Widget child;

  @override
  State<_Underlined> createState() => _UnderlinedState();
}

class _UnderlinedState extends State<_Underlined>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(vsync: this)
    ..value = widget.pressed ? 1 : 0;

  @override
  void didUpdateWidget(_Underlined old) {
    super.didUpdateWidget(old);
    if (old.pressed != widget.pressed) {
      _press.springTo(
        widget.pressed ? 1 : 0,
        DesignMotionPolicy.of(context).spatial(
          dampingRatio: BrutalMotion.dampingRatio,
          stiffness: BrutalMotion.pressStiffness,
        ),
      );
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _RulePainter(_press, widget.color, widget.width),
    child: Padding(
      padding: const EdgeInsets.only(bottom: BrutalSpacing.tight),
      child: widget.child,
    ),
  );
}

class _RulePainter extends CustomPainter {
  _RulePainter(this.press, this.color, this.width) : super(repaint: press);

  final Animation<double> press;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final height = width + width * press.value;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - height, size.width, height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_RulePainter old) =>
      old.color != color || old.width != width;
}

enum _IconButtonKind { framed, plain }

/// A square button holding one glyph. The unnamed constructor frames it in
/// the rule with its hard shadow, as [BrutalButton]; [BrutalIconButton.plain]
/// has no frame of its own, for a bar or a cell that frames it (the app bar's
/// actions), and inverts under a press.
///
/// [tooltip] names it for a screen reader. A null [onPressed] disables it.
///
/// Reads [style]'s `fill`, `foreground`, `edge`, `minimumSize` (its height
/// is the square's side) and `iconSize`, then
/// [BrutalThemeData.iconButtonStyle]'s.
///
/// ```dart
/// BrutalIconButton(onPressed: () => share(), tooltip: 'Share', icon: const Icon(LucideIcons.share2))
/// ```
class BrutalIconButton extends StatelessWidget {
  /// A framed glyph button with its shadow.
  const BrutalIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.selected,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _IconButtonKind.framed;

  /// A glyph button with no frame, which inverts under a press.
  const BrutalIconButton.plain({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.selected,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _IconButtonKind.plain;

  /// What a press does; null disables it.
  final VoidCallback? onPressed;

  /// The glyph, usually an [Icon].
  final Widget icon;

  /// What a screen reader calls it.
  final String tooltip;

  /// Whether it is on: an ink face with paper glyph. Null (the default)
  /// makes it a plain button; true or false, a toggle a screen reader
  /// reads as on or off.
  final bool? selected;

  /// This button's style, over [BrutalThemeData.iconButtonStyle].
  final BrutalStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  final _IconButtonKind _kind;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      selected: selected ?? false,
      semanticSelected: selected,
      semanticLabel: tooltip,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.iconButtonStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        final on = states.contains(WidgetState.selected);
        final plain = _kind == _IconButtonKind.plain;
        final inverted = on || (plain && pressed);
        final focus = states.contains(WidgetState.focused)
            ? brutalFocusInk(
                c,
                plain && !inverted ? (layered.fill ?? c.surface) : c.ink,
              )
            : c.ink.withValues(alpha: 0);
        final face = BrutalFace(
          fill:
              layered.fill ??
              (inverted
                  ? c.ink
                  : (plain ? c.ink.withValues(alpha: 0) : c.surface)),
          border: plain
              ? c.ink.withValues(alpha: 0)
              : layered.edge ?? (disabled ? c.disabled : c.ink),
          foreground:
              layered.foreground ??
              (layered.fill != null
                  ? c.onColor(layered.fill!)
                  : disabled
                  ? c.disabled
                  : (inverted ? c.paper : c.ink)),
          shadow: plain || disabled ? c.ink.withValues(alpha: 0) : c.ink,
          travel: !plain && pressed ? 1 : 0,
          focus: focus,
          borderWidth: plain ? 0 : null,
        );
        final side = layered.minimumSize?.height ?? theme.controlHeight;
        return DesignTapTarget(
          child: SizedBox.square(
            dimension: side,
            child: AnimatedBrutalSurface(
              face: face,
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(size: layered.iconSize ?? 20),
                  child: icon,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('tooltip', tooltip))
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      )
      ..add(
        DiagnosticsProperty<bool>('selected', selected, defaultValue: null),
      );
  }
}

/// A main action with a menu of other ways to do it beside it: two framed
/// faces 4 px apart, each with its hard shadow and its own press, the second
/// holding a triangle that turns over while the menu is open. [filled]
/// draws them in the signal colour, as a screen's main action.
///
/// A null [onPressed] disables the main half; the menu half stays. An
/// action whose `onPressed` is null shows disabled in the menu.
///
/// Reads [style]'s `fill`, `foreground`, `edge`, `padding`, `minimumSize`
/// (its height) and `textStyle` on both halves, then
/// [BrutalThemeData.filledButtonStyle]'s or
/// [BrutalThemeData.framedButtonStyle]'s.
///
/// ```dart
/// BrutalSplitButton(label: 'Save', onPressed: save, actions: [BrutalMenuItem(label: 'Save a copy', onPressed: saveCopy), BrutalMenuItem(label: 'Save as template', onPressed: saveTemplate)])
/// ```
class BrutalSplitButton extends StatelessWidget {
  /// A split button whose main action is [onPressed].
  const BrutalSplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.actions,
    this.filled = false,
    this.menuLabel,
    this.style,
  });

  /// The main action's words.
  final String label;

  /// The main action; null disables the main half.
  final VoidCallback? onPressed;

  /// The menu's actions.
  final List<BrutalMenuItem> actions;

  /// Whether the halves are a screen's main action, in the signal colour.
  final bool filled;

  /// What a screen reader calls the menu half; null: "More options".
  final String? menuLabel;

  /// Both halves' style, over the kind's theme slot.
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final kind = filled ? _ButtonKind.filled : _ButtonKind.framed;
    final layers = _buttonLayers(theme, kind, false, style);
    return DesignSplitButton(
      label: label,
      onPressed: onPressed,
      actions: [
        for (final item in actions)
          DesignSplitAction(
            label: item.label,
            onPressed: item.onPressed,
            data: item,
          ),
      ],
      menuLabel: menuLabel,
      minimumSize: Size.zero,
      layoutBuilder: (context, main, toggle) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          main,
          const SizedBox(width: BrutalSpacing.tight),
          toggle,
        ],
      ),
      buttonBuilder: (context, part, states, open) {
        // The menu half stays pressed home while its menu is open.
        final now = {
          ...states,
          if (open && part == DesignSplitPart.toggle) WidgetState.pressed,
        };
        final layered = DesignStyleOf(layers, now);
        final face = _buttonFace(
          theme,
          now,
          kind: kind,
          destructive: false,
          layers: layers,
        );
        final height = layered.minimumSize?.height ?? theme.controlHeight;
        return DesignTapTarget(
          child: SizedBox(
            height: height,
            width: part == DesignSplitPart.toggle ? height : null,
            child: AnimatedBrutalSurface(
              face: face,
              child: part == DesignSplitPart.main
                  ? Padding(
                      padding:
                          layered.padding(Directionality.of(context)) ??
                          EdgeInsets.symmetric(
                            horizontal: 20 + theme.density.paddingDelta,
                          ),
                      child: Center(
                        widthFactor: 1,
                        child: DesignCapCenter(
                          capHeightFactor: BrutalTheme.of(context)
                              .capHeightFactor,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: layered.text(
                              theme.textTheme.label.copyWith(
                                color: face.foreground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: _Turned(
                        open: open,
                        child: CustomPaint(
                          size: const Size(12, 8),
                          painter: _TrianglePainter(face.foreground),
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
      surfaceBuilder: (context, info, items) => FadeTransition(
        opacity: info.animation,
        child: BrutalMenuPanel(
          maxHeight: info.maxSize.height - theme.shadowOffset,
          children: items,
        ),
      ),
      itemBuilder: (context, action, states) {
        final item = action.data! as BrutalMenuItem;
        return BrutalMenuRow(
          label: item.label,
          icon: item.icon,
          states: states,
          isDestructiveAction: item.isDestructiveAction,
          trailing: switch (item.shortcutLabel(context)) {
            final keys? => Text(keys),
            null => null,
          },
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(IntProperty('actions', actions.length))
      ..add(FlagProperty('filled', value: filled, ifTrue: 'filled'));
  }
}

/// [child] turned over (a half turn) while [open], on the look's quick
/// tween; still under Reduce Motion.
class _Turned extends StatelessWidget {
  const _Turned({required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: open ? 0.5 : 0),
    duration: designReduceMotionOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 140),
    builder: (context, turns, child) =>
        Transform.rotate(angle: turns * 6.283185307179586, child: child),
    child: child,
  );
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close(),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

/// A screen's one main action held over its content at the bottom end: a
/// 64 px signal square on its hard shadow, or, given a [label], a wider
/// slab with its words. Stand it in a Stack's bottom end, the page's
/// margin in from the edges, clear of the bottom bar.
///
/// Reads [style]'s `fill`, `foreground`, `edge`, `padding`, `minimumSize`
/// (its height, and its width without a label), `textStyle` and `iconSize`,
/// then [BrutalThemeData.floatingButtonStyle]'s.
///
/// ```dart
/// BrutalFloatingButton(icon: Icon(LucideIcons.plus), tooltip: 'New event', onPressed: create)
/// ```
class BrutalFloatingButton extends StatelessWidget {
  /// A floating button reading [tooltip] to a screen reader.
  const BrutalFloatingButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.label,
    this.style,
  });

  /// What it does; null disables it.
  final VoidCallback? onPressed;

  /// Its icon.
  final Widget icon;

  /// What a screen reader calls it (and the label, when there is none).
  final String tooltip;

  /// Words beside the icon, making it the wide slab.
  final String? label;

  /// Its style, over [BrutalThemeData.floatingButtonStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    return DesignPressable(
      onPressed: onPressed,
      semanticLabel: label ?? tooltip,
      excludeSemantics: true,
      builder: (context, states, _) {
        final layers = [style, theme.floatingButtonStyle];
        final layered = DesignStyleOf(layers, states);
        final face = _buttonFace(
          theme,
          states,
          kind: _ButtonKind.filled,
          destructive: false,
          layers: layers,
        );
        final side = layered.minimumSize?.height ?? 64;
        return SizedBox(
          height: side,
          width: label == null ? side : null,
          child: AnimatedBrutalSurface(
            face: face,
            child: Padding(
              padding:
                  layered.padding(Directionality.of(context)) ??
                  EdgeInsets.symmetric(
                    horizontal: label == null ? 0 : BrutalSpacing.large,
                  ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme.merge(
                    data: IconThemeData(
                      size: layered.iconSize ?? 28,
                      color: face.foreground,
                    ),
                    child: icon,
                  ),
                  if (label != null) ...[
                    const SizedBox(width: BrutalSpacing.medium),
                    DesignCapCenter(
                      capHeightFactor: BrutalTheme.of(context).capHeightFactor,
                      child: Text(
                        label!,
                        maxLines: 1,
                        style: layered.text(
                          theme.textTheme.label.copyWith(
                            color: face.foreground,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('tooltip', tooltip))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

void _stay() {}
