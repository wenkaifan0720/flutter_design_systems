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

/// The source's eight categories, in its order (their hues follow it).
const _categories = [
  'Rent & home',
  'Groceries',
  'Dining out',
  'Shopping',
  'Fun',
  'Transport',
  'Health',
  'Subscriptions',
];

Widget kitSheetDemo(Brightness brightness) =>
    kitScreen(brightness: brightness, title: 'Sheet', sections: [_Raise()]);

class _Raise extends StatefulWidget {
  @override
  State<_Raise> createState() => _RaiseState();
}

class _RaiseState extends State<_Raise> {
  String _category = 'Dining out';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      kitSection(
        'Raised',
        children: [
          kitRow([
            FrostedButton.glass(
              'Category · $_category',
              onPressed: () async {
                final picked = await FrostedSheet.show<String>(
                  context,
                  title: 'Category',
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
              'Freeze card',
              icon: LucideIcons.snowflake,
              onPressed: () => FrostedSheet.show<void>(
                context,
                title: 'Freeze your card?',
                close: false,
                builder: (sheet) => const [_FreezePoints()],
                foot: (sheet) => [
                  FrostedButton.glass(
                    'Cancel',
                    onPressed: () => Navigator.of(sheet).pop(),
                  ),
                  FrostedButton(
                    'Freeze',
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
        'Side sheet',
        children: [
          kitRow([
            FrostedButton.glass(
              'Filters',
              onPressed: () => FrostedSheet.showSide<void>(
                context,
                title: 'Filters',
                builder: (sheet) => [
                  KitHeld<bool>(
                    true,
                    (on, set) => FrostedSwitchRow(
                      label: 'Only unread',
                      value: on,
                      onChanged: set,
                    ),
                  ),
                  const FrostedTextField(label: 'From'),
                ],
                foot: (sheet) => [
                  FrostedButton(
                    'Apply',
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
                        title: 'Filters',
                        onClose: () {},
                        foot: [FrostedButton('Apply', onPressed: () {})],
                        children: const [FrostedTextField(label: 'From')],
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
        'A dialog closed by its own acts',
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

  static const _points = [
    (LucideIcons.ban, 'New purchases and cash withdrawals are declined.'),
    (LucideIcons.repeat, 'Autopay, refunds and payments still go through.'),
    (LucideIcons.sun, 'Unfreeze any time; it takes effect at once.'),
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
    title: 'Category',
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _options(context, 'Dining out', (_) {}),
      ),
    ],
  ),
);

Widget kitSpecimenSheetFreeze() => FrostedSheetShell(
  title: 'Freeze your card?',
  close: false,
  foot: [
    FrostedButton.glass('Cancel', onPressed: () {}),
    FrostedButton('Freeze', icon: LucideIcons.snowflake, onPressed: () {}),
  ],
  children: const [_FreezePoints()],
);
