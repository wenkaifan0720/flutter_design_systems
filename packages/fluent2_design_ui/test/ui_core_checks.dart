// What Fluent 2 declares for ui_core's checks, each with its reason: read by the checks a sweep runs over the
// package's gallery (`const uiCoreChecks = (listWordsIndent: (px, 'why'),)`).
//
// listWordsIndent: a list a field opens (a select's, a time picker's) stands its options' words 19 px in from the
// field's words. Fluent 2's listbox draws the chosen option with a check before its words and keeps that column on
// every option, so the words line up down the list: list padding 4 + option padding 8 + check 16 + gap 4 = 32,
// against the field's padding 12 and its 1 px stroke. An option with a glyph of its own stands its words a further
// 24 in (glyph 20 + gap 4), as Fluent's options with icons do ('Channel', 43).
const uiCoreChecks = (
  listWordsIndent: (
    19.0,
    "Fluent 2's listbox draws the chosen option with a leading check and "
        'keeps its column on every option (list 4 + option 8 + check 16 + '
        "gap 4 = 32, against the field's 12 + 1 px stroke)",
  ),
);
