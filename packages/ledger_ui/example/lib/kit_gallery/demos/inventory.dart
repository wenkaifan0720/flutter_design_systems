/// The inventory group's demo: every row of ui_core's shared inventory,
/// group by group, each Ledger's part built live or the reason a ledger
/// leaves it out.
library;

import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

/// The inventory group's demo, in [brightness]: the page scrolls the list
/// itself, so only the rows in view are built.
Widget kitInventoryDemo(Brightness brightness) => kitSurface(
  brightness: brightness,
  child: LedgerScreen(
    topBar: LedgerTopBar(
      title: 'Inventory',
      meta:
          '${ledgerInventory.presentCount} parts · '
          '${ledgerInventory.absentCount} left out',
    ),
    scrollable: false,
    // The list runs through the page's gutter, so a specimen's drop at the
    // column's edge falls whole; its rows keep to the column.
    body: Builder(
      builder: (context) {
        final gutter =
            (LedgerLayout.isWide(context)
                    ? LedgerInsets.screenWide
                    : LedgerInsets.screen)
                .left;
        return KitBleed(
          by: gutter,
          child: LedgerInventoryGallery(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, LedgerSpacing.s40),
          ),
        );
      },
    ),
  ),
);
