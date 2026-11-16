// What Brutal declares to ui_core's checks, and the misreads of ui_core
// 0.2.0's checks on Brutal it knows of, each queued for 0.3.0 with a probe.

/// What Brutal declares to ui_core's checks, each with its reason.
const uiCoreChecks = (
  listWordsIndent: (
    0.0,
    "An open list's rows take the field's own inset, so its words stand on "
        "the field's words.",
  ),
);

/// ui_core 0.2.0's checks misreading Brutal, until 0.3.0.
const uiCoreMisreads = [
  (
    check: 'DesignWidthCheck.checkList',
    reads:
        'a list opened from a select ("City" on the fields page, "Density" '
        "on Settings): its leading edge is on the field's as laid out, 2 px "
        'out past as drawn',
    cause:
        "The field is a padded ListView's child, so it stands in a repaint "
        "boundary exactly its own width, with no page ground round it in the "
        'image: the check reads its 2 px rule as ground and its outline as '
        "the rule's inner edge (18..372 on a 16..374 field). Both rules are "
        'drawn on x = 16..17; the same select in a padded column reads clean.',
  ),
];
