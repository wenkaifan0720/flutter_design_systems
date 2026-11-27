/// Neumorphism: one porcelain material, cast and pressed, and one mineral pigment that means live.
///
/// Components, pressable and surface primitives are public for app and kit composition.
/// Raw painting and pigment-gradient helpers remain on the package's parts library.
library;

export 'neumorphism/chrome.dart';
export 'neumorphism/chrome_items.dart';
export 'neumorphism/app_host.dart';
export 'neumorphism/controls.dart' hide NeumorphicTapFace;
export 'neumorphism/frames.dart'
    hide
        neumorphicPaintRaised,
        neumorphicPaintPressed,
        neumorphicPaintHollowFocus,
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
    hide
        NeumorphicPigment,
        NeumorphicLightPlacement,
        neumorphicRuleWidth,
        neumorphicEdgeWidth;

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
export 'neumorphism/form_fields.dart';
export 'neumorphism/collections.dart';
export 'neumorphism/calendar.dart';
export 'neumorphism/overlays.dart';

// The ui_core vocabulary the parts above take, so a page needs only this import.
export 'package:ui_core/ui_core.dart' show RawPopoverSide, RawPopoverAlign;
export 'package:ui_core/ui_core.dart'
    show RawCalendarController, RawCalendarMode, RawDateRange;
export 'package:ui_core/ui_core.dart' show RawColorController;
export 'package:ui_core/ui_core.dart' show RawCommand, RawCommandShortcut;
export 'package:ui_core/ui_core.dart'
    show RawDataTableController, RawDataColumn, RawSortDirection;
export 'package:ui_core/ui_core.dart' show RawForm, RawFormField;
export 'package:ui_core/inventory.dart'
    show RawInventory, RawInventoryEntry, RawInventoryRow;
export 'package:ui_core/ui_core.dart'
    show RawWidgetsLocalizations, DefaultRawWidgetsLocalizations;
export 'package:ui_core/ui_core.dart' show RawMenuEntry;
export 'package:ui_core/ui_core.dart' show RawRangeValues;
export 'package:ui_core/ui_core.dart' show RawSheetEdge;
export 'package:ui_core/ui_core.dart' show RawSwipeAction;
export 'package:ui_core/ui_core.dart' show RawToastController;
export 'package:ui_core/ui_core.dart' show RawTreeController;

export 'neumorphism/format.dart';
export 'neumorphism/chrome_metrics.dart';
export 'neumorphism/component_themes.dart';
export 'neumorphism/knobs.dart';
export 'neumorphism/shapes.dart';
export 'neumorphism/styled.dart';

export 'neumorphism/fonts.dart';
