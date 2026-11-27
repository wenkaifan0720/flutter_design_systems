/// Where a page stands in the book, in Ledger's hand.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/face.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// One step of a [LedgerBreadcrumb]: its [label] and where a tap goes
/// ([onTap]; null on the page itself).
@immutable
class LedgerCrumb {
  /// A step worded [label].
  const LedgerCrumb(this.label, {this.onTap});

  /// Its words.
  final String label;

  /// Goes there; null for the page itself.
  final VoidCallback? onTap;
}

/// Where a page stands (Accounts / Everyday / October): each step in the
/// mono capitals, the ways back in the second ink and the page itself in
/// the ink, a slash between them in the faint ink. A way back underlines
/// under a pointer and takes the double rule with focus; each is laid out
/// at the tap floor. A long trail wraps rather than cuts a word, and a
/// screen reader hears it as one navigation, the last step as the current
/// page.
///
/// ```dart
/// LedgerBreadcrumb([LedgerCrumb('Accounts', onTap: () {}), LedgerCrumb('Everyday', onTap: () {}), LedgerCrumb('October')])
/// ```
class LedgerBreadcrumb extends StatelessWidget {
  /// A trail of [crumbs], the page itself last.
  const LedgerBreadcrumb(this.crumbs, {super.key}) : assert(crumbs.length > 0);

  /// The steps, the page itself last.
  final List<LedgerCrumb> crumbs;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<LedgerCrumb>('crumbs', crumbs));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Breadcrumb',
      // The steps and slashes stand face to face, a way back's target
      // reaching into the room between (ui_core's RawChipGroup).
      child: RawChipGroup(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (i, c) in crumbs.indexed) ...[
            if (i > 0)
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LedgerSpacing.s4,
                  ),
                  child: Text('/', style: t.meta.colored(t.textFaint)),
                ),
              ),
            if (i == crumbs.length - 1 || c.onTap == null)
              Semantics(
                label: c.label,
                value: i == crumbs.length - 1 ? 'Current page' : null,
                excludeSemantics: true,
                child: Text(
                  c.label.toUpperCase(),
                  style: t.meta.medium.colored(t.textPrimary),
                ),
              )
            else
              TapTargetPadding(
                alignment: i == 0
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.center,
                child: LedgerPressable(
                  onTap: c.onTap,
                  role: LedgerPressRole.link,
                  semanticLabel: c.label,
                  child: Builder(
                    builder: (context) {
                      final hot = LedgerPressStates.isHot(context);
                      return LedgerFace(
                        style: LedgerFaceStyle(
                          ink: hot ? t.textPrimary : t.textSecondary,
                        ),
                        builder: (context, s, _) => Text(
                          c.label.toUpperCase(),
                          style: t.meta
                              .colored(s.ink)
                              .copyWith(
                                decoration: hot
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                                decorationColor: s.ink,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
