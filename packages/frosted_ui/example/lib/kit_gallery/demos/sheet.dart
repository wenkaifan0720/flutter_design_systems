/// Frosted's sheets: [FrostedSheet.show] raising a sheet over the whole app
/// (off the bottom edge on a phone, a centred dialog from 1024 wide) and
/// completing with the choice, and the same card drawn in place
/// ([FrostedSheetShell]: its head, its body and its foot of acts), and a
/// side sheet ([FrostedSheet.showSide], and its panel in place).
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The source's eight categories, in its order (their hues follow it), in
/// the shown language.
List<String> get _categories => [
  kitSay('Rent & home'),
  kitSay('Groceries'),
  kitSay('Dining out'),
  kitSay('Shopping'),
  kitSay('Fun'),
  kitSay('Transport'),
  kitSay('Health'),
  kitSay('Subscriptions'),
];

Widget kitSheetDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  measured: true,
  title: kitSay('Sheet'),
  sections: [_Raise()],
);

class _Raise extends StatefulWidget {
  @override
  State<_Raise> createState() => _RaiseState();
}

class _RaiseState extends State<_Raise> {
  String _category = kitSay('Dining out');

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      kitSection(
        kitSay('Raised'),
        children: [
          kitRow([
            FrostedButton.glass(
              '${kitSay('Category')} · ${kitSay(_category)}',
              onPressed: () async {
                final picked = await FrostedSheet.show<String>(
                  context,
                  title: kitSay('Category'),
                  builder: (sheet) => _options(
                    sheet,
                    _category,
                    (name) => Navigator.of(sheet).pop(name),
                  ),
                );
                if (picked != null) setState(() => _category = picked);
              },
            ),
            FrostedButton.glass(
              kitSay('Freeze card'),
              icon: LucideIcons.snowflake,
              onPressed: () => FrostedSheet.show<void>(
                context,
                title: kitSay('Freeze your card?'),
                close: false,
                builder: (sheet) => const [_FreezePoints()],
                foot: (sheet) => [
                  FrostedButton.glass(
                    kitSay('Cancel'),
                    onPressed: () => Navigator.of(sheet).pop(),
                  ),
                  FrostedButton(
                    kitSay('Freeze'),
                    icon: LucideIcons.snowflake,
                    onPressed: () => Navigator.of(sheet).pop(),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
      kitSection(
        kitSay('Side sheet'),
        children: [
          kitRow([
            FrostedButton.glass(
              kitSay('Filters'),
              onPressed: () => FrostedSheet.showSide<void>(
                context,
                title: kitSay('Filters'),
                builder: (sheet) => [
                  KitHeld<bool>(
                    true,
                    (on, set) => FrostedSwitchRow(
                      label: kitSay('Only unread'),
                      value: on,
                      onChanged: set,
                    ),
                  ),
                  FrostedTextField(label: kitSay('From')),
                ],
                foot: (sheet) => [
                  FrostedButton(
                    kitSay('Apply'),
                    onPressed: () => Navigator.of(sheet).pop(),
                  ),
                ],
              ),
            ),
          ]),
          // As it stands on a screen: flush with the screen's end over the
          // page dimmed under it, the window's round corner taking its
          // square edge (on its own mid-page it read as cut off).
          Builder(
            builder: (context) => ClipRRect(
              borderRadius: BorderRadius.circular(FrostedCorners.r18),
              child: ColoredBox(
                color: context.frostedTheme.colorScheme.overlay,
                child: SizedBox(
                  height: 320,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: SizedBox(
                      width: 300,
                      child: FrostedSheet(
                        title: kitSay('Filters'),
                        onClose: () {},
                        foot: [
                          FrostedButton(kitSay('Apply'), onPressed: () {}),
                        ],
                        children: [FrostedTextField(label: kitSay('From'))],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      kitSection('In place', children: [kitSpecimenSheetCategory()]),
      kitSection(
        kitSay('A dialog closed by its own acts'),
        children: [kitSpecimenSheetFreeze()],
      ),
    ],
  );
}

List<Widget> _options(
  BuildContext context,
  String checked,
  ValueChanged<String> onPick,
) {
  final t = context.frostedTheme;
  return [
    for (final (i, name) in _categories.indexed)
      FrostedOption(
        label: name,
        hue: t.hue(i).a,
        selected: name == checked,
        onPressed: () => onPick(name),
      ),
  ];
}

/// The freeze dialog's three points, each a small round of glass wearing
/// its glyph by its words (16 on 20, in the second ink), as the Cards page
/// lists them.
class _FreezePoints extends StatelessWidget {
  const _FreezePoints();

  static List<(IconData, String)> get _points => [
    (
      LucideIcons.ban,
      kitSay('New purchases and cash withdrawals are declined.'),
    ),
    (
      LucideIcons.repeat,
      kitSay('Autopay, refunds and payments still go through.'),
    ),
    (LucideIcons.sun, kitSay('Unfreeze any time; it takes effect at once.')),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = t.textTheme.bodyLarge.line(20).c(t.colorScheme.textSecondary);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostedSpacing.s16,
      children: [
        for (final (icon, point) in _points)
          Row(
            spacing: FrostedSpacing.s14,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: t.glass.fillHigh,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.glass.edge),
                ),
                child: SizedBox(
                  width: FrostedChromeMetrics.markSmall,
                  height: FrostedChromeMetrics.markSmall,
                  child: Icon(
                    icon,
                    size: FrostedIconSize.i16,
                    color: t.colorScheme.textPrimary,
                  ),
                ),
              ),
              Expanded(child: Text(point, style: words)),
            ],
          ),
      ],
    );
  }
}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

Widget kitSpecimenSheetCategory() => Builder(
  builder: (context) => FrostedSheetShell(
    title: kitSay('Category'),
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _options(context, kitSay('Dining out'), (_) {}),
      ),
    ],
  ),
);

Widget kitSpecimenSheetFreeze() => FrostedSheetShell(
  title: kitSay('Freeze your card?'),
  close: false,
  foot: [
    FrostedButton.glass(kitSay('Cancel'), onPressed: () {}),
    FrostedButton(
      kitSay('Freeze'),
      icon: LucideIcons.snowflake,
      onPressed: () {},
    ),
  ],
  children: const [_FreezePoints()],
);
