/// Neumorphism: one porcelain material, cast and pressed, and one mineral pigment that means live. See SKILL.md.
///
/// Components, pressable and surface primitives are public for app and kit composition.
/// Raw painting and pigment-gradient helpers remain on the package's parts library.
library;

export 'neumorphism/chrome.dart';
export 'neumorphism/chrome_items.dart';
export 'neumorphism/controls.dart' hide NeumorphicTapFace;
export 'neumorphism/frames.dart'
    hide
        neumorphicPaintRaised,
        neumorphicPaintPressed,
        neumorphicPaintCast,
        NeumorphicThrow,
        neumorphicHolder,
        NeumorphicDraw,
        NeumorphicSeat;
export 'neumorphism/heads.dart';
export 'neumorphism/layout.dart'
    hide
        neumorphicWidestWord,
        RenderNeumorphicBeside,
        neumorphicOwnSize,
        NeumorphicFill;
export 'neumorphism/ornaments.dart'
    hide
        neumorphicPaint,
        neumorphicPaintLed,
        neumorphicPaintDimple,
        neumorphicPaintDome,
        neumorphicPaintEngraved,
        NeumorphicEngraved,
        NeumorphicMark;
export 'neumorphism/rows.dart';
export 'neumorphism/signatures/charts.dart';
export 'neumorphism/signatures/day.dart';
export 'neumorphism/signatures/dial.dart';
export 'neumorphism/signatures/relief.dart';
export 'neumorphism/theme.dart'
    hide NeumorphicPigment, neumorphicRuleWidth, neumorphicEdgeWidth;

export 'neumorphism/editing.dart';
export 'neumorphism/localizations.dart';

export 'neumorphism/glyphs.dart';

export 'neumorphism/raised.dart';

export 'neumorphism/entries.dart';

export 'neumorphism/pickers.dart';

export 'neumorphism/moves.dart';

export 'neumorphism/holds.dart';

export 'neumorphism/tell.dart';

export 'neumorphism/shows.dart';

export 'neumorphism/chart.dart' hide NeumorphicChart, NeumorphicChartKind;
export 'neumorphism/chart_kinds.dart';
export 'neumorphism/actions.dart';
export 'neumorphism/records.dart';
export 'neumorphism/sheets.dart';
export 'neumorphism/wheel_picker.dart';
export 'neumorphism/fields.dart';
export 'neumorphism/collections.dart';
export 'neumorphism/calendar.dart';
export 'neumorphism/overlays.dart';

// The ui_core vocabulary the parts above take, so a page needs only this import.
export 'package:ui_core/ui_core.dart'
    show DesignOverlaySide, DesignOverlayAlign;
export 'package:ui_core/ui_core.dart'
    show DesignCalendarController, DesignCalendarMode, DesignDateRange;
export 'package:ui_core/ui_core.dart' show DesignColorController;
export 'package:ui_core/ui_core.dart' show DesignCommand, DesignCommandShortcut;
export 'package:ui_core/ui_core.dart'
    show DesignTableController, DesignTableColumn, DesignSortDirection;
export 'package:ui_core/ui_core.dart' show DesignForm, DesignFormField;
export 'package:ui_core/inventory.dart'
    show DesignInventory, DesignInventoryEntry, DesignInventoryRow;
export 'package:ui_core/ui_core.dart'
    show DesignLocalizations, DefaultDesignLocalizations;
export 'package:ui_core/ui_core.dart' show DesignMenuEntry;
export 'package:ui_core/ui_core.dart' show DesignRangeValues;
export 'package:ui_core/ui_core.dart' show DesignSheetEdge;
export 'package:ui_core/ui_core.dart' show DesignSwipeAction;
export 'package:ui_core/ui_core.dart' show DesignToastHandle;
export 'package:ui_core/ui_core.dart' show DesignTreeController;

export 'neumorphism/format.dart';
export 'neumorphism/component_themes.dart';
export 'neumorphism/knobs.dart';
export 'neumorphism/shapes.dart';
export 'neumorphism/styled.dart';

export 'neumorphism/fonts.dart';
