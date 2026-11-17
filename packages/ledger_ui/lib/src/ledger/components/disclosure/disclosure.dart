/// Detail folded under a line until it is asked for, in Ledger's hand.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/cap_center.dart';
import '../../internal/face.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// Detail folded under a line (a fee's breakdown, the terms of a transfer):
/// the [title] in the medium on a line 48 tall with a hairline under it and
/// the chevron at its end, pointing down while open; a press opens or folds
/// it, the [child] unrolling under the line in Ledger's one motion (at once
/// with reduced motion). A pointer over the line darkens its words; the
/// keyboard's focus rules the double rule under it. A screen reader hears
/// the line as a button that is expanded or collapsed. [note] stands in the
/// mono at the line's end before the chevron (a sum, a count).
///
/// ```dart
/// LedgerDisclosure(title: 'Fees', note: r'$2.40', child: Text('Card fee'))
/// ```
class LedgerDisclosure extends StatefulWidget {
  /// A line titled [title] folding [child].
  const LedgerDisclosure({
    required this.title,
    required this.child,
    this.note,
    this.initiallyOpen = false,
    this.onChanged,
    super.key,
  });

  /// The line's words.
  final String title;

  /// What it folds.
  final Widget child;

  /// The mono note at the line's end.
  final String? note;

  /// Whether it stands open at first.
  final bool initiallyOpen;

  /// Called as it opens (true) or folds.
  final ValueChanged<bool>? onChanged;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('note', note, defaultValue: null))
      ..add(
        FlagProperty(
          'initiallyOpen',
          value: initiallyOpen,
          ifTrue: 'initiallyOpen',
        ),
      )
      ..add(ObjectFlagProperty<ValueChanged<bool>>.has('onChanged', onChanged));
  }

  @override
  State<LedgerDisclosure> createState() => _LedgerDisclosureState();
}

class _LedgerDisclosureState extends State<LedgerDisclosure> {
  late bool _open = widget.initiallyOpen;
  final GlobalKey _body = GlobalKey();

  void _flip() {
    setState(() => _open = !_open);
    widget.onChanged?.call(_open);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final motion = LedgerMotion.of(context, LedgerMotion.base);
    final body = KeyedSubtree(
      key: _body,
      child: _open
          ? Padding(
              padding: const EdgeInsets.only(
                top: LedgerSpacing.s12,
                bottom: LedgerSpacing.s16,
              ),
              child: widget.child,
            )
          : const SizedBox(width: double.infinity),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LedgerPressable(
          onTap: _flip,
          label: widget.title,
          value: widget.note,
          expanded: _open,
          // The ring stops above the row's hairline, never over it.
          ringInsets: const EdgeInsets.only(bottom: LedgerLayout.hairline),
          child: Builder(
            builder: (context) {
              final hot = LedgerPressStates.isHot(context);
              // The hairline drawn over the line's foot, not under it, so the
              // words and the chevron stand on the line's middle.
              return Container(
                constraints: BoxConstraints(minHeight: t.density.height(_line)),
                foregroundDecoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.hairline)),
                ),
                child: Row(
                  spacing: LedgerSpacing.s12,
                  children: [
                    Expanded(
                      child: LedgerFace(
                        style: LedgerFaceStyle(
                          ink: hot || _open ? t.textPrimary : t.textSecondary,
                        ),
                        builder: (context, s, _) => ledgerCapCenter(
                          t.rowTitle,
                          Text(widget.title, style: t.rowTitle.colored(s.ink)),
                        ),
                      ),
                    ),
                    if (widget.note case final n?)
                      ledgerCapCenter(
                        t.amount,
                        Text(n, style: t.amount.colored(t.textPrimary)),
                      ),
                    Icon(
                      _open
                          ? LucideIcons.chevronDown
                          : Directionality.of(context) == TextDirection.rtl
                          ? LucideIcons.chevronLeft
                          : LucideIcons.chevronRight,
                      size: _glyph,
                      color: t.textSecondary,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        ClipRect(
          // Under Reduce Motion the body lands at once, with no
          // AnimatedSize: at a zero duration it re-dirties its own layout
          // (an assertion in debug). The key keeps the body's state as the
          // setting flips.
          child: motion == Duration.zero
              ? body
              : AnimatedSize(
                  duration: motion,
                  curve: LedgerMotion.out,
                  alignment: AlignmentDirectional.topStart,
                  child: body,
                ),
        ),
      ],
    );
  }

  static const double _line = 48;
  static const double _glyph = 18;
}
