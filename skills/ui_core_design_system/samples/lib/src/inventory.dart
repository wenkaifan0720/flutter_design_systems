import 'package:ui_core/inventory.dart';

import 'button.dart';
import 'controls.dart';
import 'field.dart';
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
    const DesignInventoryEntry.absent(
      'FloatingActionButton',
      'A floating action button is Material vocabulary; the page puts its '
          'main action in its top bar.',
    ),
  ],
);
