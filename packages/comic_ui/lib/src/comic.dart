/// Comic: the comic page. Inked panels in tiers, narration captions, speech balloons, one burst a screen, Ben-Day dots. See SKILL.md.
library;

export 'comic/balloons.dart'
    hide comicBalloonPath, ComicBurstFit, ComicBurstLedger;
export 'comic/chrome.dart';
export 'comic/controls.dart';
export 'comic/frames.dart'
    hide
        ComicCompactScope,
        comicCompactHere,
        comicSlantInset,
        comicToneInks,
        comicPanelInset;
export 'comic/heads.dart';
export 'comic/layout.dart'
    hide comicWidestWord, RenderComicBeside, comicOwnSize, ComicFill;
export 'comic/people.dart';
export 'comic/press.dart'
    hide ComicStateDecoration, ComicStateLerp, comicStateCurve;
export 'comic/print.dart'
    hide ComicScreenGrid, ComicDotFade, RenderComicLettering;
export 'comic/rows.dart';
export 'comic/signatures/charts.dart';
export 'comic/signatures/cover.dart';
export 'comic/signatures/empty.dart';
export 'comic/signatures/panels.dart';
export 'comic/theme.dart'
    hide
        ComicDarkPage,
        ComicDarkTheme,
        comicLightTones,
        comicDarkTones,
        comicMaterialWords,
        comicFieldTrouble,
        comicFieldInError;

export 'comic/localizations.dart';
export 'comic/raised.dart'
    hide
        ComicRaisedFrame,
        ComicMenuRowFace,
        comicMenuRowShape,
        comicCarryTo,
        comicFieldListWords,
        comicRaisedPlate;

export 'comic/editing.dart';

export 'comic/entries.dart';

export 'comic/holds.dart';
export 'comic/moves.dart';

export 'comic/tones.dart';
export 'comic/tell.dart';
export 'comic/shows.dart';

export 'comic/pickers.dart';

export 'comic/slider.dart';
export 'comic/actions.dart';

export 'comic/glyphs.dart';

export 'comic/format.dart';

export 'comic/chart.dart';

export 'comic/inventory/action_rows.dart' hide comicRaisedSurface;
export 'comic/inventory/inputs.dart' hide ComicBareEditor;
export 'comic/inventory/overlays.dart';
export 'comic/inventory/reading.dart';
export 'comic/inventory/structure.dart';

// The design kit's value types a Comic row takes or gives.
export 'package:ui_core/ui_core.dart'
    show DesignOverlayAlign, DesignOverlayAnchor, DesignOverlaySide;
export 'package:ui_core/ui_core.dart'
    show DesignCalendarController, DesignCalendarMode, DesignDateRange;
export 'package:ui_core/ui_core.dart' show DesignColorController;
export 'package:ui_core/ui_core.dart' show DesignCommand;
export 'package:ui_core/ui_core.dart'
    show
        DesignSelection,
        DesignSortDirection,
        DesignTableColumn,
        DesignTableController;
export 'package:ui_core/ui_core.dart' show DesignMenuEntry;
export 'package:ui_core/ui_core.dart' show DesignRangeValues;
export 'package:ui_core/ui_core.dart' show DesignScrollbarVisibility;
export 'package:ui_core/ui_core.dart' show DesignSheetEdge;
export 'package:ui_core/ui_core.dart' show DesignSwipeAction;
export 'package:ui_core/ui_core.dart' show DesignTreeController;

export 'comic/component_themes.dart' hide comicStates;
export 'comic/styled.dart'
    hide
        comicCappedShape,
        comicCornerInset,
        comicInsetShape,
        comicOutsetShape,
        comicRim;
export 'comic/shapes.dart';
export 'comic/knobs.dart';
export 'comic/fonts.dart';
