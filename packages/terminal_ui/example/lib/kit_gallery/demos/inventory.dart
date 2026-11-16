/// The inventory: every component an app expects of a design system,
/// Terminal's part for it, live, or why the look leaves it out.
library;

import 'package:flutter/material.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../kit.dart';

Widget kitInventoryDemo(Brightness brightness) =>
    kitApp(brightness: brightness, home: const _Inventory());

class _Inventory extends StatelessWidget {
  const _Inventory();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TermTopBar(
          leading: kitOnBack == null
              ? null
              : TermIconButton(
                  glyph: Directionality.of(context) == TextDirection.rtl
                      ? '→'
                      : '←',
                  semanticLabel: 'back to the overview',
                  onPressed: kitOnBack,
                ),
          title: 'terminal_ui',
          subtitle:
              'inventory · ${termInventory.presentCount} of '
              '${termInventory.entries.length} live',
        ),
        const Expanded(child: TermInventoryGallery()),
      ],
    ),
  );
}
