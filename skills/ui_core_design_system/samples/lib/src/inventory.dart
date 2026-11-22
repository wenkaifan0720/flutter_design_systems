import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:ui_core/inventory.dart';
import 'package:ui_core/ui_core.dart' show RawMenuEntry, RawToast;

import 'button.dart';
import 'controls.dart';
import 'dates.dart';
import 'field.dart';
import 'lists.dart';
import 'overlays.dart';
import 'tabs.dart';

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
      'ButtonGroup',
      (context) => LookToolbar(
        toggles: [
          LookToolbarToggle(
            icon: Icons.format_bold,
            semanticLabel: 'Bold',
            isSelected: true,
            onPressed: () {},
          ),
          LookToolbarToggle(
            icon: Icons.format_italic,
            semanticLabel: 'Italic',
            isSelected: false,
            onPressed: () {},
          ),
        ],
      ),
    ),
    DesignInventoryEntry.present(
      'Checkbox',
      (context) =>
          LookCheckbox(value: true, onChanged: (_) {}, label: 'Email me'),
    ),
    DesignInventoryEntry.present(
      'TextField',
      (context) => const LookTextField(labelText: 'Name'),
    ),
    DesignInventoryEntry.present(
      'FormField',
      (context) => const LookTextField(
        labelText: 'Email',
        helperText: 'For receipts only',
        required: true,
      ),
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
        labelText: 'Plan',
        options: const ['Day', 'Week', 'Month'],
        value: 'Week',
        onChanged: (_) {},
      ),
    ),
    DesignInventoryEntry.present(
      'Combobox',
      (context) => const LookCombobox<String>(
        labelText: 'Owner',
        options: ['Ada', 'Grace', 'Katherine'],
      ),
    ),
    DesignInventoryEntry.present(
      'DatePicker',
      (context) => LookDateField(
        labelText: 'Due',
        value: DateTime(2026, 3, 18),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        onChanged: (_) {},
      ),
    ),
    DesignInventoryEntry.present(
      'TabBar',
      (context) => LookTabs<String>(
        value: 'all',
        onChanged: (_) {},
        tabs: const [
          LookTab(value: 'all', label: 'All'),
          LookTab(value: 'open', label: 'Open'),
          LookTab(value: 'done', label: 'Done'),
        ],
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
    DesignInventoryEntry.present(
      'BottomSheet',
      (context) => LookButton(
        'Share',
        variant: LookButtonVariant.outlined,
        onPressed: () => showLookSheet<void>(
          context,
          title: 'Share the list',
          actions: (context) => [
            LookButton(
              'Cancel',
              variant: LookButtonVariant.outlined,
              onPressed: () => Navigator.pop(context),
            ),
            LookButton('Copy link', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    ),
    DesignInventoryEntry.present(
      'SnackBar',
      (context) => LookButton(
        'Save draft',
        variant: LookButtonVariant.outlined,
        onPressed: () =>
            LookToaster.of(context)
                .show(const RawToast(message: 'Draft saved')),
      ),
    ),
    const DesignInventoryEntry.absent(
      'FloatingActionButton',
      'A floating action button is Material vocabulary; the page puts its '
          'main action in its top bar.',
    ),
  ],
);
