// What Terminal declares for ui_core's checks, each with its reason: read by
// the checks a sweep runs over the package's gallery (`const uiCoreChecks =
// (listWordsIndent: (px, 'why'),)`) and by list_check_test.dart.
//
// listWordsIndent: how far a list's words stand in from its field's words.
//
// paperListMisreads: lists ui_core 0.2.0's checkList misreads on paper, set
// aside there (and only there: night checks every list) until ui_core's
// 0.3.0 queue takes it. Each list is laid out on its field's edges, and its
// frame line runs down the middle of its first and last cells, as the
// field's does; the check reads it 2.5 px in on each side, 5 px narrower
// than the field. The cause: DesignAnchoredOverlay puts the list in a
// RepaintBoundary of the list's own size, so the check's groundAround finds
// no ground outside the list and falls back to the list's own; on paper the
// frame line's edge is then not lit against it, and the band out to the
// list's edge is not counted. By night the line's light edge is, so the
// same lists read flush. The probe that shows it (prints the boundary, the
// ground, the outline and the band, by night and on paper):
// packs/terminal/probes/list_ground_probe_test.dart in the looks scratch.
const uiCoreChecks = (
  listWordsIndent: (
    9.0,
    "one cell (9 px on Terminal's 15 px grid): a field's list has a cell "
        "inside its frame each side, as a menu does, so the keys' block and "
        'the chosen bar stand as far from the frame as from its top and '
        "bottom lines; its words start a cell in from the field's",
  ),
  paperListMisreads: (
    // '<screen or page> <width>[ rtl] <opener>': the field, as the reader
    // sees it. An opener is the field's place among those on the screen
    // that open (0, 1…), or t0, t1… among those typing opens.
    lists: {
      'everyday-runs 1440 0': 'branch',
      'everyday-deploy 1440 0': 'project',
      'everyday-deploy 1440 1': 'environment',
      'everyday-search 1440 0': 'branch',
      'runs 1440 0': 'branch',
      'deploy 1440 0': 'project',
      'deploy 1440 1': 'environment',
      'fields 1440 0': 'environment',
      // At 390 too since a framed field takes the whole width it is given
      // and its list lays out on its edges (round 3): the same misread, the
      // same lists flush by night.
      'everyday-runs 390 0': 'branch',
      'everyday-runs 390 rtl 0': 'branch',
      'everyday-deploy 390 0': 'project',
      'everyday-deploy 390 1': 'environment',
      'everyday-deploy 390 rtl 0': 'project',
      'everyday-deploy 390 rtl 1': 'environment',
      'everyday-search 390 0': 'branch',
      'everyday-search 390 rtl 0': 'branch',
      'runs 390 0': 'branch',
      'runs 390 rtl 0': 'branch',
      'deploy 390 0': 'project',
      'deploy 390 1': 'environment',
      'deploy 390 rtl 0': 'project',
      'deploy 390 rtl 1': 'environment',
      'fields 390 0': 'environment',
      'fields 390 rtl 0': 'environment',
      'inputs 390 t0': 'the combobox, typed into',
      'inputs 390 t1': 'the tag input, typed into',
      'inputs 390 rtl t0': 'the combobox, typed into',
      'inputs 390 rtl t1': 'the tag input, typed into',
      'inputs 1440 t0': 'the combobox, typed into',
      'inputs 1440 t1': 'the tag input, typed into',
    },
    why:
        "ui_core misread, 0.3.0 queue: DesignAnchoredOverlay's RepaintBoundary "
        "is the list's size, so groundAround falls back to the list's own "
        'ground and the paper frame line reads 2.5 px in on each side',
    probe: 'packs/terminal/probes/list_ground_probe_test.dart',
  ),
);
