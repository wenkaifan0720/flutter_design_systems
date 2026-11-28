/// A split button in Ledger's hand: a main act and the menu of the others
/// beside it, over ui_core's [RawSplitButton].
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/cap_center.dart';
import '../../internal/corners.dart';
import '../../internal/face.dart';
import '../../internal/option_paper.dart';
import '../../internal/presence.dart';
import '../../internal/side_inset.dart';
import '../../internal/state_face.dart';
import '../../theme.dart';

/// One of a [LedgerSplitButton]'s other acts: its [RawSplitAction.label]
/// and what it runs (null disables it).
typedef LedgerSplitAction = RawSplitAction;

/// A main act with the menu of its siblings beside it (Export, and as CSV
/// or as PDF): the two halves in one ring, parted by a rule, the
/// chevron's half opening a slip of paper under it with each act on its
/// own line. [filled] sets it as the page's one green act. A press stamps
/// a half (its fill takes the impression), the keyboard's focus rules the
/// double rule under the half it holds, Down opens the menu and the arrows
/// walk it; the chevron turns while it is open. The menu marks one act at
/// a time, as the select's list does, under its words: the pointer's
/// underline or the keyboard's double rule, whichever moved last (the
/// pointer moving the keys' place with it). Opened by a click it marks
/// none until the pointer or the keys move; opened by the keys, its first.
/// Beside the desktop's side bar it keeps to the room between the bar and
/// its end, its words wrapping. Each half stands at least the tap floor,
/// so the whole of it answers a tap. [onPressed] null disables the main
/// half; an act with no `onPressed` stands in pencil.
///
/// ```dart
/// LedgerSplitButton('Export', onPressed: () {}, actions: [LedgerSplitAction(label: 'As CSV', onPressed: () {}), LedgerSplitAction(label: 'As PDF', onPressed: () {})])
/// ```
class LedgerSplitButton extends StatelessWidget {
  /// The act [label]led, with [actions] in its menu.
  const LedgerSplitButton(
    this.label, {
    required this.onPressed,
    required this.actions,
    this.filled = false,
    this.menuLabel,
    super.key,
  });

  /// The main act's words.
  final String label;

  /// The main act; null disables it.
  final VoidCallback? onPressed;

  /// The menu's acts, in order.
  final List<LedgerSplitAction> actions;

  /// Whether it is the page's green act.
  final bool filled;

  /// What a screen reader calls the chevron; null: the shared words' "More
  /// options".
  final String? menuLabel;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(IterableProperty<LedgerSplitAction>('actions', actions))
      ..add(FlagProperty('filled', value: filled, ifTrue: 'filled'))
      ..add(StringProperty('menuLabel', menuLabel, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final floor = RawTapTargets.of(context).floorOn();
    final height = t.density.height(_height, floor: floor.height);
    final fill = filled ? t.accent : t.surface;
    final ink = filled ? t.onAccent : t.textPrimary;
    final ring = filled ? t.accent : t.borderStrong;
    final words = t.button
        .colored(ink)
        .copyWith(leadingDistribution: TextLeadingDistribution.even);
    // The halves' corners sit inside the ring's, one rule in.
    final inner = ledgerInset(
      ledgerStep(t, RawCorner.full),
      _rule,
      Directionality.of(context),
    ).topLeft;
    return RawSplitButton(
      label: label,
      onPressed: onPressed,
      actions: actions,
      menuLabel: menuLabel,
      minimumSize: Size(floor.width, height),
      layoutBuilder: (context, main, toggle) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: ledgerStep(t, RawCorner.full),
          border: Border.all(color: ring, width: _rule),
          boxShadow: filled && onPressed != null ? t.primaryShadow : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(_rule),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                main,
                SizedBox(
                  width: _rule,
                  child: ColoredBox(
                    color: filled
                        ? t.onAccent.withValues(alpha: _parting)
                        : t.border,
                  ),
                ),
                toggle,
              ],
            ),
          ),
        ),
      ),
      buttonBuilder: (context, part, states, open) {
        final held = states.contains(WidgetState.pressed);
        final off = states.contains(WidgetState.disabled);
        final main = part == RawSplitPart.main;
        final corners = main
            ? BorderRadiusDirectional.horizontal(start: inner)
            : BorderRadiusDirectional.horizontal(end: inner);
        final face = LedgerFace(
          style: LedgerFaceStyle(
            ink: off ? (filled ? ink : t.textTertiary) : ink,
            ground: BoxDecoration(
              color: held ? Color.lerp(fill, t.textPrimary, _impression) : fill,
              borderRadius: corners.resolve(Directionality.of(context)),
            ),
          ),
          builder: (context, s, _) => DecoratedBox(
            decoration: s.ground,
            child: SizedBox(
              height: height - 2 * _rule,
              width: main ? null : floor.width,
              child: main
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _pad),
                      child: Center(
                        widthFactor: 1,
                        child: ledgerCapCenter(
                          words,
                          Text(
                            label,
                            maxLines: 1,
                            softWrap: false,
                            style: words.colored(s.ink),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: LedgerEase(
                        value: open ? .5 : 0,
                        builder: (context, turns, glyph) => RotationTransition(
                          turns: AlwaysStoppedAnimation(turns),
                          child: glyph,
                        ),
                        child: Icon(
                          LucideIcons.chevronDown,
                          size: _glyph,
                          color: s.ink,
                        ),
                      ),
                    ),
            ),
          ),
        );
        return LedgerStateFace(
          states: states,
          borderRadius: corners,
          sinks: false,
          child: off && filled ? Opacity(opacity: _off, child: face) : face,
        );
      },
      itemBuilder: (context, action, states) {
        final type = t.rowTitle.copyWith(
          leadingDistribution: TextLeadingDistribution.even,
        );
        // One current act (ui_core's highlightFollowsPointer: hovered when
        // the pointer moved last, focused when the keys did), marked under
        // its words as the select's options are, inside the slip's 16:
        // never a rule to the paper's edge.
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: t.density.height(_row, floor: floor.height),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _itemPad),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              child: LedgerOptionWords(
                action.label,
                states: states,
                style: type.colored(
                  action.enabled ? t.textPrimary : t.textTertiary,
                ),
                maxLines: null,
              ),
            ),
          ),
        );
      },
      surfaceBuilder: (context, info, items) {
        // Beside the desktop's side bar ui_core keeps the slip clear of the
        // bar; the slip keeps its end at the button's end, its words wrapping
        // in the room back to the bar, rather than slide past the button.
        final room = _endRoom(context, info) ?? info.maxSize.width;
        return FadeTransition(
          opacity: info.animation.drive(ledgerPresence),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: info.maxSize.height,
              minWidth: math.min(_menuWidth, room),
              maxWidth: room,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: ledgerStep(t, RawCorner.small),
                border: Border.all(color: t.border),
                boxShadow: t.menuShadow,
              ),
              child: ClipRRect(
                borderRadius: ledgerStep(t, RawCorner.small),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: _menuPad),
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, item) in items.indexed) ...[
                          if (i > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: _itemPad,
                              ),
                              child: SizedBox(
                                height: _rule,
                                child: ColoredBox(color: t.hairline),
                              ),
                            ),
                          item,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // The large act's 48 and its 22 at the main half's ends; the menu a slip
  // of 48 lines, 16 in, at least 200 wide, 4 above and below its lines.
  static const double _height = 48;
  static const double _pad = 22;
  static const double _glyph = 18;
  static const double _rule = 1;
  static const double _parting = .4;
  static const double _impression = .12;
  static const double _off = .45;
  static const double _row = 48;
  static const double _itemPad = LedgerSpacing.s16;
  static const double _menuPad = LedgerSpacing.s4;
  static const double _menuWidth = 200;

  /// The room from the button's end back to where ui_core keeps the slip
  /// (its margin past the side bar and the window's padding), beside a side
  /// bar and under or over the button; null elsewhere, or with less room
  /// than a menu's words need (the slip then keeps its width and moves).
  static double? _endRoom(BuildContext context, RawPopoverInfo info) {
    if (!LedgerSideInset.besideOf(context) || !info.side.isVertical) {
      return null;
    }
    const margin = RawPopoverPlacement();
    final dir = Directionality.of(context);
    final pad = MediaQuery.paddingOf(context);
    final clear = RawPopoverPadding.of(context);
    final start = pad.left + clear.left + margin.margin;
    final anchor = info.anchorRect;
    final room = switch (dir) {
      TextDirection.ltr => anchor.right - start,
      TextDirection.rtl => start + info.maxSize.width - anchor.left,
    };
    return room < _leastRoom ? null : room;
  }

  // A menu's words at their least: two 16s and a short word or two.
  static const double _leastRoom = 120;
}
