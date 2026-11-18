// What Terminal declares for ui_core's checks, each with its reason: read by
// the checks a sweep runs over the package's gallery (`const uiCoreChecks =
// (listWordsIndent: (px, 'why'),)`) and by list_check_test.dart.
//
// listWordsIndent: how far a list's words stand in from its field's words.
const uiCoreChecks = (
  listWordsIndent: (
    9.0,
    "one cell (9 px on Terminal's 15 px grid): a field's list has a cell "
        "inside its frame each side, as a menu does, so the keys' block and "
        'the chosen bar stand as far from the frame as from its top and '
        "bottom lines; its words start a cell in from the field's",
  ),
);
