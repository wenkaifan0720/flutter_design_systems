import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/well.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../list/check_indicator.dart';
import '../pressable/pressable.dart';

/// How a [Fluent2Card] stands on the page, Fluent's `appearance`: [filled]
/// the surface (`neutralBackground1`) raised by `shadow4` (the default),
/// [filledAlternative] the second neutral layer raised the same, [outline]
/// no fill inside a `neutralStroke1` hairline, [subtle] no fill and no
/// edge until the pointer is over it.
enum Fluent2CardAppearance {
  /// Fluent's filled card: the card surface with a shadow.
  filled,

  /// The alternative filled card, on the alternative surface.
  filledAlternative,

  /// An outlined card, no shadow.
  outline,

  /// A subtle card: no fill, edge or shadow until it is hovered.
  subtle,
}

/// A card's size, Fluent's `size`: the room round and between its parts
/// and its corner. [small] 8 at the small corner (2), [medium] 12 at 4,
/// [large] 16 at 6.
enum Fluent2CardSize {
  /// The small size.
  small,

  /// The medium size.
  medium,

  /// The large size.
  large,
}

/// Which way a [Fluent2Card] lays its parts, Fluent's `orientation`: a
/// [vertical] column (a preview over its header) or a [horizontal] row (a
/// thumbnail beside it).
enum Fluent2CardOrientation {
  /// Its parts one under another.
  vertical,

  /// Its parts side by side.
  horizontal,
}

/// Fluent 2's Card: a bounded surface summarising one item (a file, a
/// meeting, a person), its [children] laid in a column (or a row with
/// [orientation]) at the size's room, a [Fluent2CardPreview] reaching its
/// edges, in the [appearance]'s face. With [onTap] the whole card is one
/// press, stepping to its hover face (`shadow8` for a filled card) and its
/// pressed fill. With [selected] set it is selectable: its check at the top
/// end corner and, while selected, its selected fill inside the selected
/// stroke; a press asks [onSelectedChanged] for the other state (null
/// draws it disabled). Read as its words, or as [label] when given.
///
/// [style] restyles it over `Fluent2ThemeData.cardTheme`, in its states
/// (hovered, pressed, selected, disabled): `fill`, `overlay`, `edge`,
/// `side` and `shape` (else the size's corner).
///
/// ```dart
/// Fluent2Card(onPressed: open, children: [Fluent2CardHeader(header: 'Q3 plan.docx', description: 'Kai Tanaka edited 2h ago')])
/// ```
class Fluent2Card extends StatelessWidget {
  /// A card of [children].
  const Fluent2Card({
    required this.children,
    this.appearance = Fluent2CardAppearance.filled,
    this.size = Fluent2CardSize.medium,
    this.orientation = Fluent2CardOrientation.vertical,
    this.onPressed,
    this.selected,
    this.onSelected,
    this.label,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// This card's own look, slot by slot, over the card theme.
  final Fluent2Style? style;

  /// The parts: [Fluent2CardPreview], [Fluent2CardHeader], words, a
  /// [Fluent2CardFooter].
  final List<Widget> children;

  /// Fluent's `appearance`: filled, alternative, outline or subtle.
  final Fluent2CardAppearance appearance;

  /// Fluent's `size`: the room round and between its parts.
  final Fluent2CardSize size;

  /// Fluent's `orientation`: its parts under one another or side by side.
  final Fluent2CardOrientation orientation;

  /// What a press on the card does (open the file); null is a still card.
  final VoidCallback? onPressed;

  /// Set to make the card selectable: chosen or not.
  final bool? selected;

  /// Asked for the other state when a selectable card is pressed; null
  /// draws a selectable card disabled.
  final ValueChanged<bool>? onSelected;

  /// What a screen reader says; null reads the card's own words.
  final String? label;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  /// The room round and between the parts at [size] (8, 12, 16).
  static double paddingOf(Fluent2CardSize size) => switch (size) {
    Fluent2CardSize.small => Fluent2Spacing.s,
    Fluent2CardSize.medium => Fluent2Spacing.m,
    Fluent2CardSize.large => Fluent2Spacing.l,
  };

  /// The corner at [size] (Fluent's `borderRadiusSmall`, `Medium`,
  /// `Large`: 2, 4, 6).
  static double radiusOf(Fluent2CardSize size) => switch (size) {
    Fluent2CardSize.small => Fluent2Radius.small,
    Fluent2CardSize.medium => Fluent2Radius.medium,
    Fluent2CardSize.large => Fluent2Radius.large,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final selectable = selected != null;
    final change = onSelected;
    final VoidCallback? press = selectable
        ? (change == null ? null : () => change(!selected!))
        : onPressed;
    final interactive = press != null;
    final disabled = selectable && press == null;
    final radius = radiusOf(size);
    final corner = BorderRadius.circular(radius);
    final content = _layout(paddingOf(size));
    final preview = children.any((c) => c is Fluent2CardPreview);
    final on = selected ?? false;
    final layers = [style, t.cardTheme];
    OutlinedBorder? outline(Set<WidgetState> states) =>
        Fluent2Style.first(layers, (s) => s.shape, states);

    Widget face(Set<WidgetState> states) {
      final s = {
        ...states,
        if (disabled) WidgetState.disabled,
        if (on) WidgetState.selected,
      };
      return Fluent2Eased<_CardFace>(
        value: _face(t, s.press, on),
        lerp: _CardFace.lerp,
        same: _CardFace.same,
        duration: Fluent2Motion.fast,
        builder: (context, f) {
          final look = Fluent2StyleOf(layers, s);
          final wash = Fluent2Style.first(layers, (x) => x.overlay, s);
          final fill = look.fill ?? f.fill;
          final rim = fluent2Rim(t, look, f.stroke);
          final shape = outline(s);
          final Widget clipped = !preview
              ? content
              : shape == null
              ? ClipRRect(borderRadius: corner, child: content)
              : ClipPath(
                  clipper: ShapeBorderClipper(
                    shape: shape,
                    textDirection: Directionality.of(context),
                  ),
                  child: content,
                );
          Widget box = Container(
            decoration: shape == null
                ? BoxDecoration(
                    color: wash == null ? fill : Color.alphaBlend(wash, fill),
                    borderRadius: corner,
                    boxShadow: f.shadow,
                  )
                : ShapeDecoration(
                    color: wash == null ? fill : Color.alphaBlend(wash, fill),
                    shape: shape,
                    shadows: f.shadow,
                  ),
            foregroundDecoration: shape == null
                ? BoxDecoration(
                    borderRadius: corner,
                    border: Border.all(color: rim.color, width: rim.width),
                  )
                : ShapeDecoration(shape: shape.copyWith(side: rim)),
            // Its parts share the card's keylines (the keyline check).
            child: DesignKeylineRegion(label: label ?? 'Card', child: clipped),
          );
          if (selectable) {
            box = Stack(
              children: [
                box,
                PositionedDirectional(
                  top: Fluent2Spacing.m,
                  end: Fluent2Spacing.m,
                  child: Fluent2CheckIndicator(
                    checked: selected,
                    press: s.press,
                  ),
                ),
              ],
            );
          }
          return box;
        },
      );
    }

    if (!interactive && !disabled) {
      // A card that is no press keeps its parts' own nodes (a heading, a
      // card's buttons), unless a label speaks for the whole.
      return Semantics(
        container: true,
        explicitChildNodes: label == null,
        label: label,
        excludeSemantics: label != null,
        child: face(const {}),
      );
    }
    return Semantics(
      container: true,
      checked: selectable ? selected : null,
      child: Fluent2Pressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: press,
        label: label,
        radius: radius,
        shape: WidgetStateProperty.resolveWith(outline),
        builder: (context, states) => face(states),
      ),
    );
  }

  Widget _layout(double p) {
    final parts = <Widget>[];
    final vertical = orientation == Fluent2CardOrientation.vertical;
    for (final (i, child) in children.indexed) {
      if (i > 0) {
        parts.add(SizedBox(width: vertical ? 0 : p, height: vertical ? p : 0));
      }
      final preview = child is Fluent2CardPreview;
      if (vertical) {
        parts.add(
          preview
              ? child
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: p),
                  child: child,
                ),
        );
      } else {
        final grows = child is Fluent2CardHeader || child is Fluent2CardFooter;
        final padded = preview
            ? child
            : Padding(
                padding: EdgeInsets.symmetric(vertical: p),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: grows ? null : 1,
                  child: child,
                ),
              );
        parts.add(grows ? Expanded(child: padded) : padded);
      }
    }
    final first = children.isNotEmpty && children.first is Fluent2CardPreview;
    final last = children.isNotEmpty && children.last is Fluent2CardPreview;
    if (vertical) {
      return Padding(
        padding: EdgeInsets.only(top: first ? 0 : p, bottom: last ? 0 : p),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: parts,
        ),
      );
    }
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: first ? 0 : p,
        end: last ? 0 : p,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: parts,
        ),
      ),
    );
  }

  _CardFace _face(Fluent2ThemeData t, Fluent2Press press, bool on) {
    final c = t.colors;
    final lifted = press == Fluent2Press.hover || press == Fluent2Press.pressed;
    if (press == Fluent2Press.disabled) {
      final outline = appearance == Fluent2CardAppearance.outline;
      return _CardFace(
        outline ? c.transparentBackground : fluent2WellDisabled(t),
        fluent2Step(t, c.neutralStrokeDisabled),
        outline ? const [] : t.shadows.shadow2,
      );
    }
    // Selected: Fluent's selected fill inside its selected stroke.
    final edge = on ? c.neutralStroke1Selected : null;
    return switch (appearance) {
      Fluent2CardAppearance.filled => _CardFace(
        on
            ? c.neutralBackground1Selected
            : press.pick(
                c.neutralBackground1,
                c.neutralBackground1Hover,
                c.neutralBackground1Pressed,
              ),
        edge ?? c.transparentStroke,
        lifted && !on ? t.shadows.shadow8 : t.shadows.shadow4,
      ),
      Fluent2CardAppearance.filledAlternative => _CardFace(
        on
            ? c.neutralBackground2Selected
            : press.pick(
                c.neutralBackground2,
                c.neutralBackground2Hover,
                c.neutralBackground2Pressed,
              ),
        edge ?? c.transparentStroke,
        lifted && !on ? t.shadows.shadow8 : t.shadows.shadow4,
      ),
      Fluent2CardAppearance.outline => _CardFace(
        on
            ? c.transparentBackgroundSelected
            : press.pick(
                c.transparentBackground,
                c.transparentBackgroundHover,
                c.transparentBackgroundPressed,
              ),
        edge ??
            press.pick(
              c.neutralStroke1,
              c.neutralStroke1Hover,
              c.neutralStroke1Pressed,
            ),
        const [],
      ),
      Fluent2CardAppearance.subtle => _CardFace(
        on
            ? c.subtleBackgroundSelected
            : press.pick(
                c.subtleBackground,
                c.subtleBackgroundHover,
                c.subtleBackgroundPressed,
              ),
        edge ?? c.transparentStroke,
        const [],
      ),
    };
  }
}

@immutable
final class _CardFace {
  const _CardFace(this.fill, this.stroke, this.shadow);

  final Color fill;
  final Color stroke;
  final List<BoxShadow> shadow;

  static _CardFace lerp(_CardFace a, _CardFace b, double t) => _CardFace(
    Color.lerp(a.fill, b.fill, t)!,
    Color.lerp(a.stroke, b.stroke, t)!,
    BoxShadow.lerpList(a.shadow, b.shadow, t) ?? b.shadow,
  );

  static bool same(_CardFace a, _CardFace b) {
    if (a.fill != b.fill ||
        a.stroke != b.stroke ||
        a.shadow.length != b.shadow.length) {
      return false;
    }
    for (var i = 0; i < a.shadow.length; i++) {
      if (a.shadow[i] != b.shadow[i]) return false;
    }
    return true;
  }
}

/// Fluent 2's CardHeader: an [image] (an avatar, a file's glyph tile, an
/// app's logo) 12 before the [header] in body1Strong over its
/// [description] in caption1 and the third ink, an [action] (a subtle
/// icon button) 12 after them at the end. A [Fluent2Card]'s part.
///
/// ```dart
/// Fluent2CardHeader(image: const Fluent2Avatar(name: 'Mara Okafor', color: Fluent2AvatarColor.colorful), header: 'Mara Okafor mentioned you', description: 'Brand guidelines.pdf · 5m ago')
/// ```
class Fluent2CardHeader extends StatelessWidget {
  /// A card's header.
  const Fluent2CardHeader({
    required this.header,
    this.description,
    this.image,
    this.action,
    super.key,
  });

  /// What the card is about.
  final String header;

  /// The quiet line under it (who, when, where).
  final String? description;

  /// What stands before the words.
  final Widget? image;

  /// What stands at the end (a "More options" icon button).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final description = this.description;
    final image = this.image;
    final action = this.action;
    return Row(
      spacing: Fluent2Spacing.m,
      children: [
        ?image,
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.body1Strong,
              ),
              if (description != null)
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.caption1.c(t.textTertiary),
                ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

/// Fluent 2's CardPreview: a picture reaching the card's edges (a file's
/// first page, a meeting's photo, a map), its [child] at [aspectRatio] (or
/// [height]) in a vertical card, [width] wide and the card's height in a
/// horizontal one, an optional [logo] 32 square at its bottom start, 12 in.
/// A [Fluent2Card]'s part.
///
/// ```dart
/// Fluent2CardPreview(aspectRatio: 16 / 9, child: Fluent2Image(image: cover, fit: Fluent2ImageFit.cover))
/// ```
class Fluent2CardPreview extends StatelessWidget {
  /// A card's preview: the picture at its top or start.
  const Fluent2CardPreview({
    required this.child,
    this.aspectRatio,
    this.height,
    this.width,
    this.logo,
    super.key,
  });

  /// The picture.
  final Widget child;

  /// Its width over its height in a vertical card.
  final double? aspectRatio;

  /// Its height in a vertical card, where no [aspectRatio] is given.
  final double? height;

  /// Its width in a horizontal card.
  final double? width;

  /// A mark over the picture's bottom start (an app's logo).
  final Widget? logo;

  @override
  Widget build(BuildContext context) {
    final ratio = aspectRatio;
    final logo = this.logo;
    Widget picture = SizedBox(
      width: width,
      height: ratio == null ? height : null,
      child: child,
    );
    if (ratio != null) {
      picture = AspectRatio(aspectRatio: ratio, child: picture);
    }
    if (logo == null) return picture;
    return Stack(
      children: [
        picture,
        PositionedDirectional(
          start: Fluent2Spacing.m,
          bottom: Fluent2Spacing.m,
          child: SizedBox.square(dimension: 32, child: logo),
        ),
      ],
    );
  }
}

/// Fluent 2's CardFooter: the card's acts in a row 12 apart (wrapping
/// rather than overflowing), an [action] pushed to the end. A
/// [Fluent2Card]'s part.
///
/// ```dart
/// Fluent2CardFooter(children: [Fluent2Button('Open', icon: Fluent2Icons.open, onPressed: open), Fluent2Button('Share', icon: Fluent2Icons.share, onPressed: share)])
/// ```
class Fluent2CardFooter extends StatelessWidget {
  /// A card's footer: its acts.
  const Fluent2CardFooter({
    this.children = const <Widget>[],
    this.action,
    super.key,
  });

  /// The acts at the start.
  final List<Widget> children;

  /// The act at the end.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return Row(
      spacing: Fluent2Spacing.m,
      children: [
        Expanded(
          child: Wrap(
            spacing: Fluent2Spacing.m,
            runSpacing: Fluent2Spacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
        ),
        ?action,
      ],
    );
  }
}
