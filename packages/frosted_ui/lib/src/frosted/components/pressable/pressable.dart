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
/// kit's `DesignPressable`: it takes the press and the long press, the
/// pointer's click cursor, keyboard focus with Enter and Space, a quiet
/// pressed read (the face easing to 97% of its size and back, its words at
/// full strength; no hover wash, no ink), the focus ring fading in while the
/// keyboard holds focus,
/// and the semantics of the
/// control it makes (a button or a link, enabled or not, selected or
/// toggled). Plumbing of the components; a page places one only to make a
/// row or card it composed by hand one target. Under the components' hit
/// slop it spans the touch target round its face, its face drawn at its own
/// size in the middle.
///
/// A null [onPressed] makes it inert: the child is drawn as it is, the node
/// is announced as disabled, and nothing answers a press or a key. [label] is
/// the spoken name and replaces what the child says when [excludeChild] is
/// true.
///
/// ```dart
/// FrostedPressable(
///   onPressed: open,
///   label: 'Everyday account',
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
    this.label,
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
  final String? label;

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

  /// Whether the child's own semantics are replaced by [label].
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
    // A control stands at the platform's touch target round its face (48
    // under a finger, 44 under a pointer), live or not, as Material pads
    // its targets: its node, its reach and its layout are that square, and
    // going inert never moves what stands round it.
    return _pressable();
  }

  Widget _pressable() => DesignPressable(
    onPressed: onPressed,
    onLongPress: onLongPress,
    focusNode: focusNode,
    autofocus: autofocus,
    selected: selected ?? toggled ?? checked ?? false,
    semanticLabel: label,
    semanticValue: value,
    button: role == FrostedPressRole.button,
    link: role == FrostedPressRole.link,
    tab: role == FrostedPressRole.tab,
    semanticSelected: selected,
    toggled: toggled,
    checked: checked,
    expanded: expanded,
    inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
    excludeSemantics: excludeChild && label != null,
    builder: (context, states, child) {
      var face = builder?.call(context, states, child) ?? child!;
      // All three always stand round the face, so a press or a focus coming
      // and going eases (from where it is, when it turns mid-way) and the
      // face's own state is kept. A press sinks the glass a little, its
      // words at full strength: a face fading to 0.7 read as a disabled
      // one and took its words under 4.5:1 (self-review round 1).
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
        radius: radius,
        shape: shape,
        insets: ringInsets,
        inside: ringInside,
        child: face,
      );
      // The control spans the target round its face.
      return FrostedHitSlop(child: face);
    },
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(ObjectFlagProperty<VoidCallback>.has('onLongPress', onLongPress))
      ..add(StringProperty('label', label, defaultValue: null))
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

/// The keyboard's focus, said in glass: the glass lights up. Its rim goes
/// bright (white by day, the pale ink by night) and a soft glow of light
/// stands round it, in the focus light (the focus ink made luminous: by day a
/// clear tone of its hue, by night a pale one), strongest at the face's edge
/// and fading out. Never a dark or opaque line (the user, 11-17 and 11-18).
/// The glow runs round a face whose corner is [radius] (or [shape], which
/// wins); with [inside], for a row in a list or a cell in a bank, it glows
/// inward from the face's edge instead, so it stays within the row and never
/// crosses its neighbours or its panel's edge. Drawn while the keyboard holds
/// focus: with [shown] it fades in, and out when focus leaves (a cut under
/// Reduce Motion). It never covers the face's words.
///
/// ```dart
/// FrostedFocusRing(shown: focused, radius: 12, child: face)
/// ```
class FrostedFocusRing extends StatelessWidget {
  /// Lights [child]'s focus.
  const FrostedFocusRing({
    required this.child,
    this.shown = true,
    this.radius = 0,
    this.shape,
    this.insets = EdgeInsets.zero,
    this.inside = false,
    super.key,
  });

  /// The face.
  final Widget child;

  /// Whether the light is on; it eases between on and off.
  final bool shown;

  /// The face's corner radius.
  final double radius;

  /// The face's outline; the glow follows it.
  final OutlinedBorder? shape;

  /// How far inside [child]'s box the lit face stands.
  final EdgeInsetsGeometry insets;

  /// Whether the glow runs inward from the face's edge (a row, a cell) rather
  /// than out round it.
  final bool inside;

  @override
  Widget build(BuildContext context) {
    final at = insets.resolve(Directionality.maybeOf(context));
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        // The frost brightens: a wash of light under the face, which glass
        // blurs into its frost (an opaque face hides it). Under, so it never
        // dims the face's words.
        Positioned(
          left: at.left,
          top: at.top,
          right: at.right,
          bottom: at.bottom,
          child: IgnorePointer(
            child: FrostedFade(
              opacity: shown ? 1 : 0,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: frostedFocusWash(context.frostedTheme),
                  shape: _outline(radius, shape),
                ),
              ),
            ),
          ),
        ),
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: FrostedFade(
              opacity: shown ? 1 : 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: layers(
                  context,
                  radius: radius,
                  shape: shape,
                  insets: insets,
                  inside: inside,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // The face's outline, without its stroke.
  static OutlinedBorder _outline(double radius, OutlinedBorder? shape) =>
      shape?.copyWith(side: BorderSide.none) ??
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(math.max(0, radius)),
      );

  /// The focus light's layers, for a [Stack] over a face whose corner is
  /// [radius] (or [shape], which wins) standing [insets] inside the stack: the
  /// glow round the face (or, [inside], within it) and the bright rim on its
  /// edge.
  static List<Widget> layers(
    BuildContext context, {
    double radius = 0,
    OutlinedBorder? shape,
    EdgeInsetsGeometry insets = EdgeInsets.zero,
    bool inside = false,
  }) {
    final inset = insets.resolve(Directionality.maybeOf(context));
    final t = context.frostedTheme;
    final outline = _outline(radius, shape);
    return [
      Positioned(
        left: inset.left,
        top: inset.top,
        right: inset.right,
        bottom: inset.bottom,
        child: CustomPaint(
          painter: FrostedFocusLight(
            outline,
            light: frostedFocusLight(t),
            rim: t.isDark
                ? t.colorScheme.textPrimary.withValues(alpha: .9)
                : const Color(0xF2FFFFFF),
            inside: inside,
          ),
        ),
      ),
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('shown', value: shown, ifFalse: 'shown: false'))
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
