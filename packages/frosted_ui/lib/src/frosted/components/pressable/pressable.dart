import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/dim.dart';
import '../../internal/hit_slop.dart';
import '../../internal/styled.dart';
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
    final pressable = _pressable();
    // A live control's node and reach span the platform's touch target
    // round its face (48 under a finger, 44 under a pointer), as Material
    // pads its targets; nothing round it moves.
    return onPressed == null && onLongPress == null
        ? pressable
        : FrostedHitSlop(child: pressable);
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
        child: face,
      );
      // Under a FrostedHitSlop the control spans the target round its face.
      return FrostedSlopFace(child: face);
    },
    child: child,
  );
}

/// The keyboard's focus, the source's ring round its act on every part: round
/// a face whose corner is [radius] (or [shape], which wins), a band
/// [FrostedChromeMetrics.focusRingGap] wide (white by day, the page's ground
/// by night) and beyond it a line [FrostedChromeMetrics.focusRingWidth] wide
/// in the ring ink, so focus reads on a pale backdrop and round the pale ink
/// pill by night. The layers run concentric. Drawn while the keyboard holds
/// focus: with [shown] it fades in, and out when focus leaves (a cut under
/// Reduce Motion).
///
/// ```dart
/// FrostedFocusRing(shown: focused, radius: 12, child: face)
/// ```
class FrostedFocusRing extends StatelessWidget {
  /// Rings [child].
  const FrostedFocusRing({
    required this.child,
    this.shown = true,
    this.radius = 0,
    this.shape,
    this.insets = EdgeInsets.zero,
    super.key,
  });

  /// The face.
  final Widget child;

  /// Whether the light is on; it eases between on and off.
  final bool shown;

  /// The face's corner radius.
  final double radius;

  /// The face's outline; the ring follows it at the gap.
  final OutlinedBorder? shape;

  /// How far inside [child]'s box the ringed face stands.
  final EdgeInsetsGeometry insets;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    clipBehavior: Clip.none,
    children: [
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
              ),
            ),
          ),
        ),
      ),
    ],
  );

  /// The ring's layers, for a [Stack] over a face whose corner is [radius]
  /// (or [shape], which wins) standing [insets] inside the stack: the band
  /// hugging the face and the line beyond it. Each is the face's outline
  /// moved out by its distance (every corner r + d round the same centre, a
  /// square corner square), so they run concentric. The band keeps the line
  /// apart from a face filled in the ring's own ink.
  static List<Widget> layers(
    BuildContext context, {
    double radius = 0,
    OutlinedBorder? shape,
    EdgeInsetsGeometry insets = EdgeInsets.zero,
  }) {
    final inset = insets.resolve(Directionality.maybeOf(context));
    final t = context.frostedTheme;
    const gap = FrostedChromeMetrics.focusRingGap;
    const width = FrostedChromeMetrics.focusRingWidth;
    // The source's ring round its act, on every focusable part: a band of
    // white, then a line of its ring ink (by day the ink at 70%, by night
    // the pale ink at 70%). A band of light alone read as the glass's own
    // rim on a pale backdrop, and merged with the pale ink pill by night,
    // so by night the band is the page's ground. Self-review round 1.
    final light = t.isDark ? t.colorScheme.background : t.colorScheme.ringInner;
    final line = t.colorScheme.ringOuter;
    OutlinedBorder outline(double out, [BorderSide side = BorderSide.none]) =>
        FrostedStyleLayers.around(shape, out)?.copyWith(side: side) ??
        RoundedRectangleBorder(
          side: side,
          borderRadius: BorderRadius.circular(radius > 0 ? radius + out : 0),
        );
    Widget at(double out, Widget child) => Positioned(
      left: inset.left - out,
      top: inset.top - out,
      right: inset.right - out,
      bottom: inset.bottom - out,
      child: IgnorePointer(child: child),
    );
    return [
      at(
        gap,
        DecoratedBox(
          decoration: ShapeDecoration(
            shape: outline(gap, BorderSide(color: light, width: gap)),
          ),
        ),
      ),
      at(
        gap + width,
        DecoratedBox(
          decoration: ShapeDecoration(
            shape: outline(gap + width, BorderSide(color: line, width: width)),
          ),
        ),
      ),
    ];
  }
}
