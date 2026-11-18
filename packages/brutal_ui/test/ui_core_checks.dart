// What Brutal declares to ui_core's checks, and the misreads of the checks
// (ui_core 0.2.0's, ui_core_test 0.1.0's) on Brutal it knows of, each with
// the probe that shows it.

/// What Brutal declares to ui_core's checks, each with its reason.
const uiCoreChecks = (
  listWordsIndent: (
    0.0,
    "An open list's rows take the field's own inset, so its words stand on "
        "the field's words.",
  ),
);

/// The checks misreading Brutal. ui_core_test 0.1.0 reads an open list
/// against the page under it, but still reads the field from its own
/// repaint boundary (the first), and reads a list's rule as ground where the
/// page under it has a rule in the same column (the second). list_check_test
/// sets aside exactly these readings ([misreadSelects]) and still checks
/// every other list.
const uiCoreMisreads = [
  (
    check: 'DesignWidthCheck.checkList',
    reads:
        'a list opened from a select ("City" on the fields page): its '
        "leading edge is on the field's as laid out, 2 px out past as drawn",
    cause:
        "The field is a padded ListView's child, so it stands in a repaint "
        "boundary exactly its own width, with no page ground round it in the "
        'image: the check reads its 2 px rule as ground and its outline as '
        "the rule's inner edge (18..372 on a 16..374 field). Both rules are "
        'drawn on x = 16..17; the same select in a padded column reads clean.',
  ),
  (
    check: 'DesignWidthCheck.checkList',
    reads:
        'a list opened from a select ("When" on the fields page at 1440): '
        '320 px wide as laid out, 316 as drawn, and its leading edge 2 px in '
        "from the field's as drawn",
    cause:
        'At 1440 the list opens upward over the "City" select, whose rules '
        "stand in the same columns (x = 360..361 and 678..679) as the list's. "
        'Read against the page under it, the list changes nothing in those '
        "columns over City's rows, and the check takes its rules for ground. "
        'Drawn, both lists rule x = 360..361 and 678..679, as the field does.',
  ),
];

/// The readings [uiCoreMisreads] names, each as its select and the words
/// the reading ends with.
const misreadSelects = {
  ('City', '2 px out past as drawn'),
  ('When', '316 as drawn, narrower than the field (320, 320 as drawn)'),
  ('When', '2 px in from as drawn'),
};
