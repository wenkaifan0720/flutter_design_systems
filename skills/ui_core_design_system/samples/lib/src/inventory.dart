import 'package:flutter/widgets.dart';
import 'package:ui_core/inventory.dart';
import 'package:ui_core/ui_core.dart' show RawMenuEntry;

import 'button.dart';
import 'controls.dart';
import 'field.dart';
import 'lists.dart';
import 'overlays.dart';

/// The look's answers to ui_core's component checklist: a live specimen for
/// each row it carries, a reason for each it leaves out. A complete look
/// answers every row; this one answers a few, and its test reads the rest as
/// missing.
final DesignInventory lookInventory = DesignInventory(
  look: 'Look',
  entries: [
    DesignInventoryEntry.present(
      'Button',
      (context) => LookButton('Save', onPressed: () {}),
    ),
    DesignInventoryEntry.present(
      'Checkbox',
      (context) =>
          LookCheckbox(value: true, onChanged: (_) {}, label: 'Email me'),
    ),
    DesignInventoryEntry.present(
      'TextField',
      (context) => const LookTextField(label: 'Name'),
    ),
    DesignInventoryEntry.present(
      'Tooltip',
      (context) => LookTooltip(
        message: 'Archive',
        child: LookButton('Archive', onPressed: () {}),
      ),
    ),
    DesignInventoryEntry.present(
      'Select',
      (context) => LookSelect<String>(
        label: 'Plan',
        options: const ['Day', 'Week', 'Month'],
        value: 'Week',
        onChanged: (_) {},
      ),
    ),
    DesignInventoryEntry.present(
      'Combobox',
      (context) => const SizedBox(
        width: 240,
        child: LookCombobox<String>(
          label: 'Owner',
          options: ['Ada', 'Grace', 'Katherine'],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'Menu',
      (context) => LookMenu(
        entries: [
          RawMenuEntry(label: 'Rename', onPressed: () {}),
          RawMenuEntry(
            label: 'Delete',
            isDestructiveAction: true,
            onPressed: () {},
          ),
        ],
        // The region a menu opens over is a target a screen reader acts
        // on ("Show menu"): it reaches the floor, as a row does.
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text('Draft'),
        ),
      ),
    ),
    const DesignInventoryEntry.absent(
      'FloatingActionButton',
      'A floating action button is Material vocabulary; the page puts its '
          'main action in its top bar.',
    ),
  ],
);
