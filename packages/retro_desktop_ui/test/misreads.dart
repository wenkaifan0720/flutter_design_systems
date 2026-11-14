// What ui_core's shared checks (DesignRowCheck, DesignWidthCheck, checkList, DesignLabelCheck) misread on this look's
// screens, by kind, each with its reason: the screen is right and the check reads it wrongly. A test takes a check's
// findings through [withoutMisreads] and expects what is left empty, so a real fault still fails it, and every excused
// finding is printed (MISREAD) with its kind. Each kind went to ui_core's owner (11-12) where the check itself should
// learn it.

/// One kind of misread: its [kind], why the screen is right ([reason]), and the findings it covers ([pattern], matched
/// against `<screen>: <finding>`).
class Misread {
  /// Creates a [Misread].
  Misread(this.kind, this.reason, String pattern) : pattern = RegExp(pattern);

  /// A short name for the kind.
  final String kind;

  /// Why the finding is a misread.
  final String reason;

  /// The findings of this kind.
  final RegExp pattern;
}

/// [found] less the findings a kind in [kinds] covers. Each one excused is printed as `MISREAD <check> <kind>: <finding>`,
/// and each kind's count as `MISREADS <check> <kind>: <n>`.
List<String> withoutMisreads(
  String check,
  Iterable<String> found,
  List<Misread> kinds,
) {
  final left = <String>[];
  final counts = {for (final k in kinds) k.kind: 0};
  for (final line in found) {
    final kind = kinds.where((k) => k.pattern.hasMatch(line)).firstOrNull;
    if (kind == null) {
      left.add(line);
      continue;
    }
    counts[kind.kind] = counts[kind.kind]! + 1;
    // ignore: avoid_print
    print('MISREAD $check ${kind.kind}: $line');
  }
  for (final MapEntry(:key, :value) in counts.entries) {
    // ignore: avoid_print
    if (value > 0) print('MISREADS $check $key: $value');
  }
  return left;
}

// A face that is not one colour: Platinum's buttons, segments, the menu bar and a chosen day fill with a gradient. The
// check takes a face's ground from one sample and then reads the words on it as the test font's solid boxes, or the
// gradient's bands as ink (capitals as tall as the face). The look's fonts are loaded before every check (setUpAll
// loads each FontManifest family), so no control draws the test font.
final _gradientFace = Misread(
  'gradient face',
  'a face filled with a gradient reads as solid boxes or as ink as tall as '
      'the face; the look\'s fonts are loaded before the check',
  r"draws? (its|their) text in the test's own font|"
      r"are drawn \d+(\.\d+)? device px high; its DesignCapCenter's "
      r'capHeightFactor gives',
);

// An icon tile (a desk icon, a folder or a file in an icon view) stands its name under its picture: the words are not on
// the tile's middle, by design, and the check reads them as a centred label.
final _iconTile = Misread(
  'icon tile',
  'an icon tile stands its name (and a file its kind tab) under its picture, '
      'not on its middle',
  r'(All components|Lists and tables|lists): a button "(Desktop|Mail|Trash|'
      r'the-numbers\.csv|first-sheet\.pdf|a-drawing\.svg|First kind|'
      r'Second kind|Third kind)"( beside [^:]*)?: (the capitals of|its icon is)',
);

// A bottom bar's destination stands its glyph over its label.
final _navBar = Misread(
  'nav bar destination',
  'a bottom bar\'s destination stands its glyph over its label, the label '
      'under the middle',
  r'Navigation: a button "(You|Today|Places)" beside a button '
      r'"(You|Today|Places)": the capitals of',
);

// The password field's reveal button stands inside its well, at its end: part of the field, not a button beside it.
// A chosen folder tab stands taller than the others, joined to its page (by design); the tab role sits on the bar above
// them (as Material's TabBar puts it), so the check reads them as buttons in a row, and, from 600 up, as one wide
// segmented control.
final _tabs = Misread(
  'folder tabs',
  'a chosen tab stands taller, joined to its page; the tab role is on the bar '
      'above the tabs, so they read as buttons or a segmented control',
  r'(Navigation: a button "(Today|Soon)" beside a button "(Today|Soon|Later)"|'
      r'Workspace: a (button "Recent" beside a button "Shared"|'
      r'segmented control "Recent")|'
      r'All components: a button "(General|Sharing)" beside a button '
      r'"(General|Sharing)"|'
      // The label check: the chosen tab's words stay on the row of tabs' line,
      // not on the middle of its taller face.
      r'(controls|everyday|tabs): a button "(Today|Recent)": the capitals of '
      r'"(Today|Recent|\d+)" are drawn \d+(\.\d+)? device px below)',
);

// A held toggle sinks its words a pixel down and right inside its turned-in bevel, as the period's pressed toggles did
// (the segment keeps its size; law 4); the check reads them a pixel under the row's line. Both appearances since
// self-review round 2 (Platinum's held segment had only darkened).
final _heldSinks = Misread(
  'held toggle',
  'a held toggle sinks its words a pixel down and right, as the period\'s '
      'pressed toggles did',
  r'a switch "Bold"( beside a switch "(Italic|Underline)")?: the capitals of '
      r'"Bold" are',
);

// A row that spans its container and presses as a whole (a table's column head, a sheet's or a palette's row, a
// selectable card, a chart's surface) is a list row, not a button: it spans by design. A table's sortable heads (a
// phone's Name and Changed) read as one group of choices since ui_core 0e25289dfd.
final _fullWidthRow = Misread(
  'full-width row',
  'a table head, a sheet or palette row, a selectable card or a chart\'s '
      'surface spans its container and presses whole; it is a row, not a button',
  r'(Overview|List|Lists and tables|All components): a (button|group of '
      r'choices) "(Name|Size)": '
      r'\d|Dialogs and sheets: a button "(Documents|Archive)": \d|'
      r'(Navigation|All components): a button "New document": \d|'
      r'Cards and media: a button "Open folder": \d|Charts: a button: \d',
);

// Chisel's list face draws through its own render box (a RetroDesktopPixelPaint), not a DecoratedBox; checkList finds a
// list by a DecoratedBox face, so it reports none open (the list stands on the field's width under it: dropdowns_test).
final _chiselList = Misread(
  'Chisel list face',
  'Chisel paints its list\'s face itself, not with a DecoratedBox, so the '
      'check finds no list (dropdowns_test holds the list to its field)',
  r'no list open from',
);

// A table row presses whole (named "Select row") and holds its cells; the check reads each cell's words against the
// row's face, whose rule under it is part of its box.
final _tableRow = Misread(
  'table row',
  'a table row presses whole; its cells\' words stand between its rules, and '
      'the check measures them against the box with its rule',
  r'a button "Select row": the capitals of',
);

// A check row whose title heads a note under it: the title stands at the top, not on the middle.
final _titledCheck = Misread(
  'check row with a note',
  'a check row\'s title heads the note under it',
  r'lists: a checkbox "(The step to take next|The last step)": the capitals',
);

// A choice tile with a note: its title heads the note.
final _choiceTile = Misread(
  'choice tile',
  'a choice tile\'s title heads the note under it',
  r'Selection: a button "(Every day|Every week|Never)" beside a button '
      r'"(Every day|Every week|Never)": the capitals of',
);

// A press around the caller's own content: RetroDesktopSurface's child (a selectable card's worth of content). The look
// does not place it; a one-line child reads as a label off its face's middle.
final _callerContent = Misread(
  'caller\'s content',
  'a surface holds the caller\'s own content, placed by the caller, not a '
      'label the look centres',
  r'a button "Open folder": the capitals of "A selectable surface"',
);

// A select under its label in Papers' details window (from 600 up, as wide as its widest option): its value's line
// stands on its face's middle as laid out (probe 11-12 at 1440 standard: face 474-516, line 484-506; compact 474-512,
// 482-504), and the check reads the drawn face lower than its box (13.5 device px at standard, 3.0 at compact).
final _labelledSelect = Misread(
  'select under its label',
  'a select under its label stands its value on its face\'s middle as laid '
      'out; the check reads its drawn face lower than its box',
  r'Papers details: a button "Save new documents to": the capitals of '
      r'"This computer" are drawn \d+(\.\d+)? device px above',
);

final _ruledRow = Misread(
  'a well\'s ruled last row',
  'a row under a rule, the last in a well, stands its words on its own box\'s '
      'middle as laid out (the rule is the top of that box); the check reads '
      'its drawn face from the rule to the well\'s inner edge, a device pixel '
      'or so lower',
  r'raised: a button "Archive": the capitals of "Archive" are drawn '
      r'1(\.\d+)? device px above',
);

/// The row check's misreads ([DesignRowCheck]).
final rowMisreads = [
  _gradientFace,
  _iconTile,
  _navBar,
  _tabs,
  _choiceTile,
  _callerContent,
  _heldSinks,
];

/// The row check's misreads in Chisel alone, after [rowMisreads].
final chiselRowMisreads = <Misread>[];

// Chisel's sunken box on the current check row's tint: its white fill and light lower bevel stand within the check's
// ink threshold of the pale tint, so the box is read by its dark upper bevel alone, a third of its height (drawn, its
// middle is on the capitals as on every other row: probe shot 2026-11-13).
final _tintedCheckBox = Misread(
  'sunken box on a tint',
  'a sunken box on the current row\'s pale tint is read by its dark upper bevel',
  r'lists: a checkbox "The step to take next": its painted mark',
);

/// The label check's misreads in Chisel alone, after [labelMisreads].
final chiselLabelMisreads = <Misread>[_tintedCheckBox];

/// The width check's misreads ([DesignWidthCheck]).
final widthMisreads = [_fullWidthRow, _tabs];

/// The list check's misreads ([DesignWidthCheck.checkList]) in Chisel; Platinum has none.
final chiselListMisreads = [_chiselList];

/// The label check's misreads ([DesignLabelCheck]).
final labelMisreads = [
  _gradientFace,
  _iconTile,
  _tabs,
  _tableRow,
  _titledCheck,
  _callerContent,
  _heldSinks,
  _labelledSelect,
  _ruledRow,
];
