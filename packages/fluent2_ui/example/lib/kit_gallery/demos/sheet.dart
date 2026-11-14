/// Fluent 2's sheets: [Fluent2Sheet.show] raising a sheet over the whole app
/// (Fluent 2's bottom sheet on a phone, its dialog surface from 1024 wide)
/// and completing with the choice, and the same card drawn in place
/// ([Fluent2SheetShell]: the handle, the head with its dismiss, the body
/// and the foot of acts).
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

const _folders = ['Launch', 'Research', 'Design reviews', 'Archive'];

Widget kitSheetDemo(Brightness brightness) =>
    kitScreen(brightness: brightness, title: 'Sheet', sections: [_Raise()]);

class _Raise extends StatefulWidget {
  @override
  State<_Raise> createState() => _RaiseState();
}

class _RaiseState extends State<_Raise> {
  String _folder = 'Launch';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      kitSection(
        'Raised',
        children: [
          kitRow([
            Fluent2Button(
              'Move to · $_folder',
              icon: Fluent2Icons.folder,
              onPressed: () async {
                final picked = await Fluent2Sheet.show<String>(
                  context,
                  title: 'Move to',
                  builder: (sheet) => _options(
                    sheet,
                    _folder,
                    (name) => Navigator.of(sheet).pop(name),
                  ),
                );
                if (picked != null) setState(() => _folder = picked);
              },
            ),
            Fluent2Button(
              'Share',
              icon: Fluent2Icons.share,
              onPressed: () => Fluent2Sheet.show<void>(
                context,
                title: 'Share Launch plan',
                builder: (sheet) => const [_ShareBody()],
                foot: (sheet) => [
                  Fluent2Button(
                    'Cancel',
                    onPressed: () => Navigator.of(sheet).pop(),
                  ),
                  Fluent2Button(
                    'Send',
                    appearance: Fluent2ButtonAppearance.primary,
                    onPressed: () => Navigator.of(sheet).pop(),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
      kitSection('In place', children: [kitSpecimenSheetMove()]),
      kitSection('With its acts', children: [kitSpecimenSheetShare()]),
    ],
  );
}

List<Widget> _options(
  BuildContext context,
  String current,
  ValueChanged<String> onPick,
) {
  final t = context.fluent2Theme;
  return [
    for (final name in _folders)
      Fluent2Pressable(
        onPressed: () => onPick(name),
        label: name,
        selected: name == current,
        radius: Fluent2Radius.medium,
        builder: (context, states) => ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: Fluent2Layout.minHitTarget,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: states.press.pick(
                const Color(0x00000000),
                t.colors.subtleBackgroundHover,
                t.colors.subtleBackgroundPressed,
              ),
              borderRadius: BorderRadius.circular(Fluent2Radius.medium),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Fluent2Spacing.s),
              child: Row(
                spacing: Fluent2Spacing.m,
                children: [
                  Icon(
                    Fluent2Icons.folder,
                    size: Fluent2IconSize.i20,
                    color: t.textSecondary,
                  ),
                  Expanded(child: Text(name, style: t.body1)),
                  if (name == current)
                    Icon(
                      Fluent2Icons.checkmark,
                      size: Fluent2IconSize.i20,
                      color: t.accentText,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
  ];
}

class _ShareBody extends StatelessWidget {
  const _ShareBody();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Fluent2Spacing.m,
      children: [
        Text(
          'People in Northwind with the link can view.',
          style: t.body1.c(t.textSecondary),
        ),
        for (final person in kitPeople.skip(1).take(3))
          Fluent2Persona(name: person.name, secondary: 'Can edit', size: 32),
      ],
    );
  }
}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

/// Move to, the four folders with Launch chosen, drawn in place.
Widget kitSpecimenSheetMove() => Builder(
  builder: (context) => Fluent2SheetShell(
    title: 'Move to',
    onClose: () {},
    children: _options(context, 'Launch', (_) {}),
  ),
);

/// Share, its people and Cancel beside Send in the brand at the foot.
Widget kitSpecimenSheetShare() => Fluent2SheetShell(
  title: 'Share Launch plan',
  onClose: () {},
  foot: [
    Fluent2Button('Cancel', onPressed: () {}),
    Fluent2Button(
      'Send',
      appearance: Fluent2ButtonAppearance.primary,
      onPressed: () {},
    ),
  ],
  children: const [_ShareBody()],
);
