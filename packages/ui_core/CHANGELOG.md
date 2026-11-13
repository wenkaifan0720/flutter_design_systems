## 0.1.0

- First release: 24 headless behaviours (see the README), the press and the value handle they are built from,
  `DesignLocalizations` for the words they and a look say by themselves, and spring motion that respects Reduce Motion.
- `host.dart`: the scaffold contract the look packages share (tabs, the shell's action, how a route is presented,
  preview frames, the media slot, English formats). It leaves the package in a later minor version.
- `inventory.dart`: the component checklist a design system answers, and the gallery that lists its answers.
- `alignment.dart`: the checks a design system's tests and review pages run on its screens: that its controls line
  up where they share a line, on Android, iOS and macOS, from their drawn pixels (`DesignAlignmentMatrix`,
  `DesignRowCheck`), that each label sits on the middle of its face (`DesignLabelCheck`), that a card's or a
  gallery section's contents start and end on shared lines (`DesignKeylineCheck`), that controls keep to their
  content's width on a wide screen (`DesignWidthCheck`), that no word breaks across lines
  (`DesignWordBreakCheck`) and nothing is cut (`DesignClipCheck`), and the sheets that draw them for review.
  `DesignKeylineRegion`, in the main library, marks a card or a section for them.
- `DesignControlBox` and `DesignTextEntryBox`: the layout that keeps a control or a text entry on its line.
- `DesignCapCenter`: a one-line label drawn with its capitals on the middle of its box.
