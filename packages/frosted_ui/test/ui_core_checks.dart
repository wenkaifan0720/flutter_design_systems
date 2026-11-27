// What Frosted declares for ui_core's checks, with its reasons: ui_core's
// sweep reads this file.
//
// listWordsIndent: how far an open list's words stand in from its field's.
const uiCoreChecks = (
  listWordsIndent: (
    28.0,
    "Frosted's lists keep a check column before their words, as its menus "
        'do (16 wide, then a 10 gap), so a chosen row shows its check without '
        'its words moving: the words stand 28 in from the field\'s.',
  ),
);
