## 0.1.0

- The layout review leaves ui_core_test 0.2.0 for this package, in the repository alone (`publish_to: none`): the
  alignment matrix and its sheet (`DesignAlignmentMatrix`, `DesignAlignmentRow`, `DesignAlignmentEntry`,
  `DesignAlignmentBuilder`, `DesignInlineControl`, `DesignAlignmentSheet`), `DesignTextEntryCheck` and
  `DesignTextEntryBuilder`, `DesignKeylineCheck` and `DesignKeylineSheet`, `DesignRowCheck`, `DesignWidthCheck`,
  `DesignWidthLimit` and `DesignWidthKind`, `DesignSpacingCheck` and `DesignFieldPartsCheck`, unchanged. They encode a
  look's own grid and taste, not what is wrong in any design, so each look holds them to its own numbers.
- The library re-exports ui_core_test: a test that takes a review check imports
  `package:ui_core_review/ui_core_review.dart` in place of `package:ui_core_test/ui_core_test.dart`.
