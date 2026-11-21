import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/link_face.dart';
import '../../internal/link_target.dart';
import '../../internal/option.dart';
import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// A card: the page's white face on the app's cool ground, a card's
/// corners (8) and no stroke, holding one thing (a permit, a service, a
/// figure) under its [title].
///
/// With [onPressed] the whole card is one link to its page: its title is
/// drawn as a link and a press anywhere on the card follows it. Give it
/// the page's [url] and a screen reader hears a link to it (on the web an
/// anchor with that address); without one it is read as a button. A pointer
/// over it greys the face a little and thickens the title's line; a press
/// deepens both; a keyboard focus lays the title on the yellow plate over
/// the ink bar, as a link's (a card with no title takes an ink edge inside
/// and the yellow ring round it). A screen reader hears one link, worded by
/// [title] (or [semanticLabel]), with the card's words after it. Keep
/// other controls out of a card that is a link: one card, one place to go.
///
/// Reads [CivicStyle]'s fill (the face, by state), padding and textStyle
/// (the title): its `style:`, then [CivicThemeData.cardStyle].
///
/// ```dart
/// CivicCard(
///   title: 'Resident permit, Zone B',
///   url: Uri.parse('/permits/BRM-4821-K'),
///   onPressed: () {},
///   child: Text('Runs out on 3 November 2027.'),
/// )
/// ```
class CivicCard extends StatelessWidget {
  /// A card holding [child] under [title].
  const CivicCard({
    super.key,
    required this.child,
    this.title,
    this.onPressed,
    this.url,
    this.semanticLabel,
    this.focusNode,
    this.statesController,
    this.style,
  }) : assert(
         onPressed == null || title != null || semanticLabel != null,
         'A card that is a link needs words for it: a title or a '
         'semanticLabel.',
       );

  /// What the card is about, as a heading (and the link's words when the
  /// card is a link).
  final String? title;

  /// What the card holds under its title.
  final Widget child;

  /// Follows the card's link; null: the card is not a link.
  final VoidCallback? onPressed;

  /// The address of the card's page ([CivicLink.url]): with one the card
  /// is read as a link to it; without one, as a button.
  final Uri? url;

  /// What a screen reader calls the link; null: [title].
  final String? semanticLabel;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.statesController}
  final WidgetStatesController? statesController;

  /// Overrides for this card's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final go = onPressed;
    final address = url;
    if (go == null && address == null) return _face(context, const {});
    Widget card(VoidCallback? press, {required bool link}) => RawButton(
      onPressed: press,
      focusNode: focusNode,
      statesController: statesController,
      button: !link,
      link: link,
      semanticLabel: semanticLabel ?? title,
      mouseCursor: SystemMouseCursors.click,
      builder: (context, states, _) => _face(context, states),
    );
    if (address == null) return card(go, link: false);
    return CivicLinkTarget(
      url: address,
      onPressed: go,
      builder: (context, press) => card(press, link: true),
    );
  }

  Widget _face(BuildContext context, Set<WidgetState> states) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf([style, t.cardStyle], states);
    final link = onPressed != null;
    final wash = !link
        ? 0.0
        : states.contains(WidgetState.pressed)
        ? 1.0
        : states.contains(WidgetState.hovered)
        ? 0.5
        : 0.0;
    final head = title;
    final words = head == null
        ? null
        : link
        ? CivicLinkFace(
            states: states,
            textStyle: text.headingS.merge(so.textStyle),
            child: Text(head),
          )
        : Semantics(
            header: true,
            child: Text(
              head,
              style: text.headingS
                  .copyWith(color: t.textPrimary)
                  .merge(so.textStyle),
            ),
          );
    final face = CivicSpringValue(
      value: wash,
      spring: CivicMotion.press,
      effects: true,
      builder: (context, w, _) => DecoratedBox(
        decoration: BoxDecoration(
          // A pointer greys the face toward the ground it stands on.
          color: Color.lerp(so.fill ?? t.background, t.surface, 0.6 * w),
          borderRadius: BorderRadius.circular(CivicMetrics.cardCorner),
        ),
        child: CivicCardScope(
          child: Padding(
            padding:
                so.padding(Directionality.of(context)) ??
                const EdgeInsets.all(CivicSpacing.s16),
            child: DefaultTextStyle.merge(
              style: text.body.copyWith(color: t.textPrimary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: CivicSpacing.s8,
                children: [?words, child],
              ),
            ),
          ),
        ),
      ),
    );
    if (!link || head != null) return face;
    // No title to lay on the plate: the focus rings the card, an ink edge
    // inside and the yellow ring outside it.
    final corner = BorderRadius.circular(CivicMetrics.cardCorner);
    return CivicSpringValue(
      value: states.contains(WidgetState.focused) ? 1 : 0,
      spring: CivicMotion.focus,
      effects: true,
      child: face,
      builder: (context, focus, face) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: corner,
          border: Border.all(
            color: t.focus.withValues(alpha: focus.clamp(0.0, 1.0)),
            width: CivicMetrics.focusRing,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: corner,
            border: Border.all(
              color: t.onFocus.withValues(alpha: focus.clamp(0.0, 1.0)),
              width: CivicMetrics.edge,
            ),
          ),
          child: face,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(DiagnosticsProperty<Uri>('url', url, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
