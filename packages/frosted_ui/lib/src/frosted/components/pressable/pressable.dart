import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/dim.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../theme.dart';

/// What a [FrostedPressable] is to assistive technology.
enum FrostedPressRole {
  /// A button: it acts.
  button,

  /// A link: it goes somewhere.
  link,

  /// A tab: one of a tab bar's, saying whether it is the chosen one
  /// ([FrostedPressable.selected]).
  tab,

  /// A control that says its own role through [FrostedPressable.checked]
  /// (a radio, a check row), neither a button nor a link.
  control,
}

// How far a pressed face sinks: a little, eased, never a spring.
const double _pressedScale = 0.97;

/// The one press machine every Frosted control rides, built on the design
/// kit's `RawButton`: it takes the press and the long press, the
/// pointer's click cursor, keyboard focus with Enter and Space, a quiet
/// pressed read (the face easing to 97% of its size and back, its words at
/// full strength; no ink), the frost clearing ([FrostedFocusRing]) a little
/// under a pointer and in full while the keyboard holds focus,
/// and the semantics of the
/// control it makes (a button or a link, enabled or not, selected or
/// toggled). Plumbing of the components; a page places one only to make a
/// row or card it composed by hand one target. Under the components' hit
/// slop it spans the touch target round its face, its face drawn at its own
/// size in the middle.
///
/// A null [onPressed] makes it inert: the child is drawn as it is, the node
/// is announced as disabled, and nothing answers a press or a key. [semanticLabel] is
/// the spoken name and replaces what the child says when [excludeChild] is
/// true.
///
/// ```dart
/// FrostedPressable(
///   onPressed: open,
///   semanticLabel: 'Everyday account',
///   radius: 18,
///   child: card,
/// )
/// ```
class FrostedPressable extends StatelessWidget {
  /// Makes [child] one target.
  const FrostedPressable({
    required this.onPressed,
    this.child,
    this.builder,
    this.onLongPress,
    this.semanticLabel,
    this.value,
    this.role = FrostedPressRole.button,
    this.selected,
    this.toggled,
    this.checked,
    this.expanded,
    this.inMutuallyExclusiveGroup = false,
    this.radius = 0,
    this.shape,
    this.ringInsets = EdgeInsets.zero,
    this.ringInside = false,
    this.excludeChild = true,
    this.pressedOpacity = 1,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(
         child != null || builder != null,
         'A FrostedPressable needs a child or a builder.',
       );

  /// What a press does; null makes the control inert.
  final VoidCallback? onPressed;

  /// What a long press does.
  final VoidCallback? onLongPress;

  /// The face; [builder] draws it instead when given.
  final Widget? child;

  /// Draws the face from the control's states (pressed, hovered, focused,
  /// selected, disabled), as a styled part resolves its `style:` slots;
  /// [child] is handed through.
  final Widget Function(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  )?
  builder;

  /// The spoken name; null leaves the child's own semantics.
  final String? semanticLabel;

  /// The spoken value after the name (the month a switch shows).
  final String? value;

  /// A button or a link, to assistive technology.
  final FrostedPressRole role;

  /// Set for one option of a set (a tab, a chip): chosen or not.
  final bool? selected;

  /// Set for an on/off control (a heart): on or off.
  final bool? toggled;

  /// Set for a checked control (a radio, a check row): checked or not.
  final bool? checked;

  /// Set for what opens and shuts (a disclosure, a select): open or not.
  final bool? expanded;

  /// Whether it is one of a set of which one is checked (a radio).
  final bool inMutuallyExclusiveGroup;

  /// The corner radius of the focus ring round the child.
  final double radius;

  /// The face's outline, which the focus ring follows; wins over [radius].
  final OutlinedBorder? shape;

  /// How far inside the child's box the ringed face stands; negative where
  /// the face bleeds past it (a chosen row's plate).
  final EdgeInsetsGeometry ringInsets;

  /// Whether the focus light glows inward from the face's edge, kept within
  /// it (a row in a list, a row in a menu), rather than out round it.
  final bool ringInside;

  /// Whether the child's own semantics are replaced by [semanticLabel].
  final bool excludeChild;

  /// The opacity of the face while a finger is down: full by default, the
  /// press read being the face sinking a little.
  final double pressedOpacity;

  /// The caller's focus node; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    // A control stands at the platform's touch target round its face (the
    // floor, 40), live or not, as Material pads
    // its targets: its node, its reach and its layout are that square, and
    // going inert never moves what stands round it.
    return _pressable();
  }

  Widget _pressable() => RawButton(
    onPressed: onPressed,
    onLongPress: onLongPress,
    focusNode: focusNode,
    autofocus: autofocus,
    selected: selected ?? toggled ?? checked ?? false,
    semanticLabel: semanticLabel,
    semanticValue: value,
    button: role == FrostedPressRole.button,
    link: role == FrostedPressRole.link,
    tab: role == FrostedPressRole.tab,
    semanticSelected: selected,
    toggled: toggled,
    checked: checked,
    expanded: expanded,
    inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
    excludeSemantics: excludeChild && semanticLabel != null,
    builder: (context, states, child) => frostedPressableFace(
      context,
      states,
      builder?.call(context, states, child) ?? child!,
      radius: radius,
      shape: shape,
      ringInsets: ringInsets,
      ringInside: ringInside,
      pressedOpacity: pressedOpacity,
    ),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(ObjectFlagProperty<VoidCallback>.has('onLongPress', onLongPress))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(StringProperty('value', value, defaultValue: null))
      ..add(
        EnumProperty<FrostedPressRole>(
          'role',
          role,
          defaultValue: FrostedPressRole.button,
        ),
      )
      ..add(DiagnosticsProperty<bool>('selected', selected, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('toggled', toggled, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('checked', checked, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('expanded', expanded, defaultValue: null))
      ..add(
        FlagProperty(
          'inMutuallyExclusiveGroup',
          value: inMutuallyExclusiveGroup,
          ifTrue: 'inMutuallyExclusiveGroup',
        ),
      )
      ..add(DoubleProperty('radius', radius, defaultValue: 0))
      ..add(
        DiagnosticsProperty<OutlinedBorder>('shape', shape, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'ringInsets',
          ringInsets,
          defaultValue: EdgeInsets.zero,
        ),
      )
      ..add(FlagProperty('ringInside', value: ringInside, ifTrue: 'ringInside'))
      ..add(
        FlagProperty(
          'excludeChild',
          value: excludeChild,
          ifFalse: 'excludeChild: false',
        ),
      )
      ..add(DoubleProperty('pressedOpacity', pressedOpacity, defaultValue: 1))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

/// Builds its child knowing whether a pointer rests on it, anywhere in its
/// box: a face drawn from a [RawRadio]'s states, which shows a hover only
/// while Flutter's highlight mode is traditional, shows one as a
/// [FrostedPressable] does.
class FrostedPointerHover extends StatefulWidget {
  /// Builds [builder]'s child, told whether a pointer rests on it.
  const FrostedPointerHover({required this.builder, super.key});

  /// Builds the child from whether a pointer rests on it.
  final Widget Function(BuildContext context, bool hovered) builder;

  @override
  State<FrostedPointerHover> createState() => _FrostedPointerHoverState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<Widget Function(BuildContext, bool)>.has(
        'builder',
        builder,
      ),
    );
  }
}

class _FrostedPointerHoverState extends State<FrostedPointerHover> {
  bool _hovered = false;

  void _hover(bool hovered) {
    if (hovered != _hovered) setState(() => _hovered = hovered);
  }

  // Opaque, so the region counts as hit and the radio's own detector above it
  // takes the press.
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => _hover(true),
    onExit: (_) => _hover(false),
    child: widget.builder(context, _hovered),
  );
}

/// [face] as a [FrostedPressable] draws it in [states]: sinking a little while
/// pressed, faded to [pressedOpacity], its frost cleared under a pointer and
/// in full while focused ([FrostedFocusRing], by [radius] or [shape], standing
/// [ringInsets] inside it, glowing inward with [ringInside]), and spanning
/// the touch target round it. A control whose press and focus come from
/// elsewhere (a radio's `RawRadio`) draws its face through it as well.
Widget frostedPressableFace(
  BuildContext context,
  Set<WidgetState> states,
  Widget face, {
  double radius = 0,
  OutlinedBorder? shape,
  EdgeInsetsGeometry ringInsets = EdgeInsets.zero,
  bool ringInside = false,
  double pressedOpacity = 1,
}) {
  // All three always stand round the face, so a press or a focus coming
  // and going eases (from where it is, when it turns mid-way) and the
  // face's own state is kept. A press sinks the glass a little, its
  // words at full strength: a face fading to 0.7 read as a disabled
  // one and took its words under 4.5:1.
  final pressed = states.contains(WidgetState.pressed);
  final motion = FrostedMotion.of(context);
  face = AnimatedScale(
    scale: pressed ? _pressedScale : 1,
    duration: motion.fast,
    curve: motion.curve,
    child: face,
  );
  face = FrostedFade(opacity: pressed ? pressedOpacity : 1, child: face);
  face = FrostedFocusRing(
    shown: states.contains(WidgetState.focused),
    hovered: states.contains(WidgetState.hovered),
    radius: radius,
    shape: shape,
    insets: ringInsets,
    inside: ringInside,
    child: face,
  );
  // The control spans the target round its face.
  return FrostedHitSlop(child: face);
}

/// The keyboard's focus, said in glass: the frost clears and the rim
/// catches the light. The part's frost wipes partway clear, so more of the
/// colour behind comes through (less blur and less milk on its own glass
/// face), and its own thin rim brightens to white: the rim it already has,
/// no wider, or a hairline just inside its outline where it has none. No
/// colour of its own and nothing outside the part. A pointer over the part
/// ([hovered]) only clears it, less, with no rim light.
///
/// The frost under the part's [radius] (or [shape], which wins), standing
/// [insets] inside [child]'s box, clears there; the outermost face of
/// [child] clears too ([FrostedClearing]). With [inside], for a row in a
/// list or a cell in a bank, only what is behind the row clears, never the
/// faces it holds. It eases in and out (a cut under Reduce Motion), and the
/// words on a cleared part read as they do at rest.
///
/// ```dart
/// FrostedFocusRing(shown: focused, radius: 12, child: face)
/// ```
class FrostedFocusRing extends StatelessWidget {
  /// Clears [child]'s frost while [shown].
  const FrostedFocusRing({
    required this.child,
    this.shown = true,
    this.hovered = false,
    this.radius = 0,
    this.shape,
    this.insets = EdgeInsets.zero,
    this.inside = false,
    super.key,
  });

  /// The face.
  final Widget child;

  /// Whether the keyboard holds the part: the frost clears in full and the
  /// rim lights.
  final bool shown;

  /// Whether a pointer is over the part: the frost clears a little.
  final bool hovered;

  /// The face's corner radius.
  final double radius;

  /// The face's outline; the clearing follows it.
  final OutlinedBorder? shape;

  /// How far inside [child]'s box the cleared face stands.
  final EdgeInsetsGeometry insets;

  /// Whether only what is behind the part clears (a row, a cell), not the
  /// faces it holds.
  final bool inside;

  @override
  Widget build(BuildContext context) {
    // A row that draws its own clearing holds it.
    if (FrostedClearingHeld.of(context)) return child;
    final level = shown
        ? 1.0
        : hovered
        ? FrostedClearing.hover
        : 0.0;
    return FrostedCleared(
      level: level,
      lit: shown ? 1 : 0,
      outline: _outline(radius, shape),
      insets: insets,
      inside: inside,
      child: child,
    );
  }

  // The face's outline, without its stroke.
  static OutlinedBorder _outline(double radius, OutlinedBorder? shape) =>
      shape?.copyWith(side: BorderSide.none) ??
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(math.max(0, radius)),
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('shown', value: shown, ifFalse: 'shown: false'))
      ..add(FlagProperty('hovered', value: hovered, ifTrue: 'hovered'))
      ..add(DoubleProperty('radius', radius, defaultValue: 0))
      ..add(
        DiagnosticsProperty<OutlinedBorder>('shape', shape, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'insets',
          insets,
          defaultValue: EdgeInsets.zero,
        ),
      )
      ..add(FlagProperty('inside', value: inside, ifTrue: 'inside'));
  }
}
