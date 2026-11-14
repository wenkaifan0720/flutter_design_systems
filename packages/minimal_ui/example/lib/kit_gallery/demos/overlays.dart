/// A sheet from either side, a popover under its button and a card shown
/// while a pointer rests on a name, live; and the side sheet's panel
/// composed in place.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget _details(BuildContext context) {
  final t = context.minimalTheme;
  // A name in the sans, a figure (a date, a count, an amount) in the mono.
  Widget line(String k, String v, {bool figure = true}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s8),
    child: Row(
      children: [
        Expanded(child: Text(k, style: t.bodySmall.c(t.mutedForeground))),
        Text(v, style: (figure ? t.mono : t.bodySmall).c(t.foreground)),
      ],
    ),
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      line('Customer', 'Ana Souza', figure: false),
      line('Placed', '12 Mar 2026'),
      line('Items', '3'),
      line('Total', '\$129.00'),
    ],
  );
}

/// The filters sheet's one setting, as a settings list sets it: its words in
/// the ink, the switch at the row's end (the labelled switch is a footer's
/// quiet register).
class _OpenOnly extends StatefulWidget {
  const _OpenOnly();

  @override
  State<_OpenOnly> createState() => _OpenOnlyState();
}

class _OpenOnlyState extends State<_OpenOnly> {
  bool _on = true;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: t.rowHeight),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Open only',
              style: t.body.c(t.foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const MinimalGap(MinimalSpacing.s12),
          MinimalSwitch(
            value: _on,
            label: 'Open only',
            onChanged: (on) => setState(() => _on = on),
          ),
        ],
      ),
    );
  }
}

Widget _person(BuildContext context) {
  final t = context.minimalTheme;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const MinimalAvatar('Ana Souza', size: 36),
      const MinimalGap(MinimalSpacing.s12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ana Souza', style: t.body.medium.c(t.foreground)),
            Text('Design lead · Lisbon', style: t.caption.c(t.mutedForeground)),
            const MinimalGap(MinimalSpacing.s8),
            Text(
              'Owns the calendar and the onboarding flow.',
              style: t.bodySmall.c(t.foreground),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget kitOverlaysDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Side sheet, popover, hover card',
  sections: [
    kitSection(
      'Side sheet',
      children: [
        Builder(
          builder: (context) => kitRow([
            MinimalButton(
              'Order details',
              variant: MinimalButtonVariant.secondary,
              onPressed: () => showMinimalSheet<void>(
                context,
                title: 'ORD-1042',
                subtitle: 'Orders',
                builder: _details,
                leading: const MinimalSheetAction('Close'),
                trailing: MinimalSheetAction(
                  'Refund',
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            // The pair's other trigger, so the same kind: each only opens
            // its sheet.
            MinimalButton(
              'From the start',
              variant: MinimalButtonVariant.secondary,
              onPressed: () => showMinimalSheet<void>(
                context,
                title: 'Filters',
                side: MinimalSide.start,
                width: 300,
                builder: (context) => const _OpenOnly(),
              ),
            ),
          ]),
        ),
        kitNote('Esc, a tap on the scrim or a drag toward its edge closes it.'),
      ],
    ),
    kitSection('Panel', children: const [_PanelOverPage()]),
    kitSection(
      'Popover',
      children: [
        // In a row, so the trigger hugs its label as the others do.
        kitRow([
          MinimalPopover(
            label: 'Share',
            anchor: (context, toggle, open) => MinimalButton(
              'Share',
              icon: LucideIcons.share2,
              variant: MinimalButtonVariant.secondary,
              onPressed: toggle,
            ),
            content: (context, close) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MinimalTextField(
                  label: 'Link',
                  hint: 'ritual.app/s/8f2k',
                ),
                const MinimalGap(MinimalSpacing.s12),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: MinimalButton('Copy link', onPressed: close),
                ),
              ],
            ),
          ),
        ]),
        kitNote('Focus moves into it and back to the button when it closes.'),
      ],
    ),
    kitSection(
      'Hover card',
      children: [
        // The card hugs the handle at the line's start; the handle is a
        // code, so it reads left to right in every language.
        Builder(
          builder: (context) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: MinimalHoverCard(
              card: _person(context),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: MinimalLink('@ana', onPressed: () {}),
              ),
            ),
          ),
        ),
        kitNote('Rest a pointer on the name, or tab to it.'),
      ],
    ),
  ],
);

/// The side sheet as it stands when raised: the orders list under the
/// scrim, framed like the dialog's page, and the panel the frame's full
/// height on its end edge, the outer corners on the frame's edge and the
/// inner ones rounded.
///
/// The frame is as tall as the panel needs at the text's size (its six
/// lines grow with it), rounded up to whole rows of the page, so no row is
/// cut at its foot and the footer never closes over the details. Each row
/// leads with its customer's face: on a phone the strip beside the panel
/// shows the faces whole, and from a wider frame the names and ids too,
/// never a word cut at the panel's edge.
class _PanelOverPage extends StatelessWidget {
  const _PanelOverPage();

  static const List<(String, String, String)> _orders = [
    ('ORD-1042', 'Ana Souza', '\$129.00'),
    ('ORD-1041', 'Ben Okafor', '\$64.00'),
    ('ORD-1040', 'Hanna Berg', '\$212.50'),
    ('ORD-1039', 'Oskar Lind', '\$38.00'),
    ('ORD-1038', 'Ana Souza', '\$91.20'),
    ('ORD-1037', 'Ben Okafor', '\$17.00'),
    ('ORD-1036', 'Ines Duarte', '\$54.00'),
    ('ORD-1035', 'Hanna Berg', '\$76.40'),
    ('ORD-1034', 'Oskar Lind', '\$22.00'),
    ('ORD-1033', 'Ana Souza', '\$140.00'),
  ];

  /// A row's face.
  static const double _face = 24;

  /// The panel's height at the text's own size.
  static const double _panel = 264;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // What the text scale adds to the panel's six lines: its title, four
    // details and its button's words.
    final grown =
        _panel + 6 * (MediaQuery.textScalerOf(context).scale(16) - 16);
    final rows = (grown / t.rowHeight).ceil();
    // The strip a phone's frame leaves beside the panel: the gutter, a face
    // and the air after it.
    const faces = MinimalChromeMetrics.gutter + _face + MinimalSpacing.s12;
    return Container(
      height: rows * t.rowHeight + 2 * t.hairline,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(color: t.background, shape: t.shapes.medium),
      // The frame stands for the screen's edge: the sheet runs to it, and
      // the frame's hairline paints over it, so the sheet's own rim on its
      // outer edges is the frame's (one line, the frame's corners).
      foregroundDecoration: ShapeDecoration(
        shape: t.shapes.medium.copyWith(
          side: BorderSide(color: t.border, width: t.hairline),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            // The page under it, cut by the frame rather than overflowing
            // at a larger density.
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, (id, who, total))
                        in _orders.take(rows).indexed)
                      Container(
                        height: t.rowHeight,
                        padding: MinimalInsets.gutter,
                        // The frame's edge closes the last row.
                        decoration: BoxDecoration(
                          border: i == rows - 1 ? null : Border(bottom: t.rule),
                        ),
                        child: Row(
                          children: [
                            MinimalAvatar(who, size: _face),
                            const MinimalGap(MinimalSpacing.s12),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      who,
                                      style: t.body.medium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const MinimalGap(MinimalSpacing.s8),
                                  Text(id, style: t.mono.c(t.mutedForeground)),
                                ],
                              ),
                            ),
                            const MinimalGap(MinimalSpacing.s12),
                            Text(total, style: t.mono.c(t.foreground)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned.fill(child: ColoredBox(color: t.overlay)),
            // At most 300 wide. Where that would leave a strip too narrow
            // for a name and its id, the panel stops on the faces' strip.
            PositionedDirectional(
              top: 0,
              bottom: 0,
              end: 0,
              width: box.maxWidth - 300 < faces + 200
                  ? box.maxWidth - faces
                  : 300.0,
              child: MinimalSheet(
                title: 'ORD-1042',
                onClose: () {},
                trailing: MinimalSheetAction(
                  'Refund',
                  isDefaultAction: true,
                  onPressed: () {},
                ),
                child: _details(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- catalog specimens -------------------------------------------------------

/// The side sheet's panel at its edge, a record's details in it.
Widget kitSpecimenSideSheet() => Builder(
  builder: (context) => Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: context.minimalTheme.overlay),
      PositionedDirectional(
        top: 0,
        bottom: 0,
        end: 0,
        width: 300,
        child: MinimalSheet(
          title: 'ORD-1042',
          subtitle: 'Orders',
          onClose: () {},
          trailing: const MinimalSheetAction('Refund', isDefaultAction: true),
          child: _details(context),
        ),
      ),
    ],
  ),
);
