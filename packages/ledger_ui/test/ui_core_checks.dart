// What Ledger declares for ui_core's checks, each with its reason: read by the checks a sweep runs over the package's
// gallery (`const uiCoreChecks = (listWordsIndent: (px, 'why'),)`).
//
// listWordsIndent: a list a field opens (a select's options, a combobox's or a tag field's suggestions) stands its
// options' words 16 px in from the field's words. A Ledger field is written on a rule: its words start on the rule's
// own start, with no padding. The list is a slip of raised paper laid on the field's edge, and its rows hold their
// words 16 in from the paper's edge, the inset of every row Ledger draws (a ruled row's, a menu item's), so the words
// stand on the paper, clear of its rounded corner, and the rules between options start under them. An option with a
// glyph of its own stands its words a further 30 in (glyph 18 + gap 12), 46 in all.
const uiCoreChecks = (
  listWordsIndent: (
    16.0,
    'a Ledger field is written on its rule with no padding, while its list is a '
        "slip of raised paper whose rows hold their words 16 in from the paper's "
        "edge, the inset of every Ledger row, so they stand clear of the slip's "
        'rounded corner and over the rules between options',
  ),
);
