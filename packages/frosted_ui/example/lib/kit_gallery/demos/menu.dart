/// The anchored menu: [FrostedMenu.show] dropping the month menu from the
/// control that opened it (8 under it, centred on it on a phone and with
/// its end on the control's end at desktop width, no scrim) and completing
/// with the choice; the same card drawn in place; and the options a menu
/// and a sheet share ([FrostedOption], its [FrostedHueDot] and quiet amount).
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The source's months and what was spent in each.
const _months = [
  ('May 2026', 2689.05),
  ('June 2026', 2598.70),
  ('July 2026', 2733.15),
  ('August 2026', 2512.40),
  ('September 2026', 2644.90),
  ('October 2026', 2486.12),
];

/// An amount at a row's end, set in the small amount type in the second
/// ink until the money parts land (Stage C).
Widget _quietAmount(double amount) => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return Text(
      FrostedFormat.money(amount),
      style: t.textTheme.amountSmall.c(t.colorScheme.textSecondary),
    );
  },
);

List<FrostedMenuItem<String>> _items(String checked) => [
  for (final (month, spent) in _months)
    FrostedMenuItem(
      month,
      month,
      trailing: _quietAmount(spent),
      checked: month == checked,
    ),
];

Widget kitMenuDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Menu',
  sections: [
    kitSection('Anchored to its control', children: [const _Month()]),
    kitSection('In place', children: [kitSpecimenMenuMonths()]),
    kitSection(
      'Options',
      children: [
        Builder(
          builder: (context) {
            final t = context.frostedTheme;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FrostedOption(
                  label: 'Groceries',
                  hue: t.hue(1).a,
                  trailing: _quietAmount(412.36),
                  onPressed: () {},
                ),
                FrostedOption(
                  label: 'Dining out',
                  hue: t.hue(2).a,
                  trailing: _quietAmount(286.40),
                  selected: true,
                  onPressed: () {},
                ),
                FrostedOption(
                  label: 'Everyday',
                  lead: FrostedHueDot(t.colorScheme.moneyIn),
                  onPressed: null,
                ),
              ],
            );
          },
        ),
      ],
    ),
  ],
);

class _Month extends StatefulWidget {
  const _Month();

  @override
  State<_Month> createState() => _MonthState();
}

class _MonthState extends State<_Month> {
  int _at = _months.length - 1;

  @override
  Widget build(BuildContext context) {
    final (month, _) = _months[_at];
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      // The months drop from the control itself: the Builder's context is
      // the button's box.
      child: Builder(
        builder: (anchor) => FrostedButton.glass(
          month,
          size: FrostedButtonSize.small,
          icon: LucideIcons.chevronDown,
          onPressed: () async {
            final picked = await FrostedMenu.show<String>(
              anchor,
              title: 'Spent by month',
              label: 'Months',
              items: _items(month),
            );
            if (picked != null) {
              setState(() => _at = _months.indexWhere((m) => m.$1 == picked));
            }
          },
        ),
      ),
    );
  }
}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

Widget kitSpecimenMenuMonths() => Align(
  alignment: AlignmentDirectional.centerEnd,
  child: FrostedMenu<String>(
    title: 'Spent by month',
    label: 'Months',
    items: _items('October 2026'),
    onSelected: (_) {},
  ),
);
