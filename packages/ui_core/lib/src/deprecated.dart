// The names ui_core renamed or reshaped, kept one release with what to use. `dart fix` makes each rename
// (lib/fix_data.yaml); a reshaped name's message says what to write instead.
import 'anchored_overlay.dart';
import 'bottom_sheet.dart';
import 'calendar.dart';
import 'carousel.dart';
import 'color_picker.dart';
import 'combobox.dart';
import 'command_palette.dart';
import 'context_menu.dart';
import 'data_table.dart';
import 'date_field.dart';
import 'dialog.dart';
import 'form_field.dart';
import 'input_group.dart';
import 'localizations.dart';
import 'menubar.dart';
import 'number_field.dart';
import 'otp.dart';
import 'page_transitions.dart';
import 'pressable.dart';
import 'pull_to_refresh.dart';
import 'range_slider.dart';
import 'rating.dart';
import 'reorderable_list.dart';
import 'scroll_area.dart';
import 'side_sheet.dart';
import 'split_button.dart';
import 'split_view.dart';
import 'swipe_actions.dart';
import 'tabs.dart';
import 'tag_input.dart';
import 'tap_target.dart';
import 'toast.dart';
import 'toggle_group.dart';
import 'wheel_picker.dart';

// The renames: generated from the 0.4.0 rename table. Do not edit by hand.
/// Renamed [DefaultRawWidgetsLocalizations] in ui_core 0.4.0.
@Deprecated(
  'Use DefaultRawWidgetsLocalizations. This feature was deprecated after ui_core 0.4.0.',
)
typedef DefaultDesignLocalizations = DefaultRawWidgetsLocalizations;

/// Renamed [RawPopover] in ui_core 0.4.0.
@Deprecated('Use RawPopover. This feature was deprecated after ui_core 0.4.0.')
typedef DesignAnchoredOverlay = RawPopover;

/// Renamed [RawBottomSheetBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawBottomSheetBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignBottomSheetBuilder = RawBottomSheetBuilder;

/// Renamed [RawBottomSheetController] in ui_core 0.4.0.
@Deprecated(
  'Use RawBottomSheetController. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignBottomSheetController = RawBottomSheetController;

/// Renamed [RawBottomSheetDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawBottomSheetDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignBottomSheetDetails = RawBottomSheetDetails;

/// Renamed [RawBottomSheetDragHandle] in ui_core 0.4.0.
@Deprecated(
  'Use RawBottomSheetDragHandle. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignBottomSheetDragHandle = RawBottomSheetDragHandle;

/// Renamed [RawBottomSheetRoute] in ui_core 0.4.0.
@Deprecated(
  'Use RawBottomSheetRoute. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignBottomSheetRoute<T> = RawBottomSheetRoute<T>;

/// Renamed [RawCalendarDatePicker] in ui_core 0.4.0.
@Deprecated(
  'Use RawCalendarDatePicker. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignCalendar = RawCalendarDatePicker;

/// Renamed [RawCalendarController] in ui_core 0.4.0.
@Deprecated(
  'Use RawCalendarController. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignCalendarController = RawCalendarController;

/// Renamed [RawCalendarDayDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawCalendarDayDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignCalendarDay = RawCalendarDayDetails;

/// Renamed [RawCalendarDayBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawCalendarDayBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignCalendarDayBuilder = RawCalendarDayBuilder;

/// Renamed [RawCalendarHeaderDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawCalendarHeaderDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignCalendarHeader = RawCalendarHeaderDetails;

/// Renamed [RawCalendarMode] in ui_core 0.4.0.
@Deprecated(
  'Use RawCalendarMode. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignCalendarMode = RawCalendarMode;

/// Renamed [RawCarousel] in ui_core 0.4.0.
@Deprecated('Use RawCarousel. This feature was deprecated after ui_core 0.4.0.')
typedef DesignCarousel = RawCarousel;

/// Renamed [RawCarouselDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawCarouselDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignCarouselControls = RawCarouselDetails;

/// Renamed [RawColorArea] in ui_core 0.4.0.
@Deprecated(
  'Use RawColorArea. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignColorArea = RawColorArea;

/// Renamed [RawColorAreaDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawColorAreaDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignColorAreaDetails = RawColorAreaDetails;

/// Renamed [RawColorChannel] in ui_core 0.4.0.
@Deprecated(
  'Use RawColorChannel. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignColorChannel = RawColorChannel;

/// Renamed [RawColorController] in ui_core 0.4.0.
@Deprecated(
  'Use RawColorController. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignColorController = RawColorController;

/// Renamed [RawColorPicker] in ui_core 0.4.0.
@Deprecated(
  'Use RawColorPicker. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignColorPicker = RawColorPicker;

/// Renamed [RawColorSlider] in ui_core 0.4.0.
@Deprecated(
  'Use RawColorSlider. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignColorSlider = RawColorSlider;

/// Renamed [RawCombobox] in ui_core 0.4.0.
@Deprecated('Use RawCombobox. This feature was deprecated after ui_core 0.4.0.')
typedef DesignCombobox<T extends Object> = RawCombobox<T>;

/// Renamed [RawCommand] in ui_core 0.4.0.
@Deprecated('Use RawCommand. This feature was deprecated after ui_core 0.4.0.')
typedef DesignCommand = RawCommand;

/// Renamed [RawCommandPalette] in ui_core 0.4.0.
@Deprecated(
  'Use RawCommandPalette. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignCommandPalette = RawCommandPalette;

/// Renamed [RawCommandShortcut] in ui_core 0.4.0.
@Deprecated(
  'Use RawCommandShortcut. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignCommandShortcut = RawCommandShortcut;

/// Renamed [RawContextMenu] in ui_core 0.4.0.
@Deprecated(
  'Use RawContextMenu. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignContextMenu = RawContextMenu;

/// Renamed [RawDataTable] in ui_core 0.4.0.
@Deprecated(
  'Use RawDataTable. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDataTable<R> = RawDataTable<R>;

/// Renamed [RawDateField] in ui_core 0.4.0.
@Deprecated(
  'Use RawDateField. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDateField = RawDateField;

/// Renamed [RawDateFieldFrameBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawDateFieldFrameBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDateFieldFrameBuilder = RawDateFieldFrameBuilder;

/// Renamed [RawDateLiteralBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawDateLiteralBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDateLiteralBuilder = RawDateLiteralBuilder;

/// Renamed [RawDateRange] in ui_core 0.4.0.
@Deprecated(
  'Use RawDateRange. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDateRange = RawDateRange;

/// Renamed [RawDateSegmentBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawDateSegmentBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDateSegmentBuilder = RawDateSegmentBuilder;

/// Renamed [RawDateSegmentDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawDateSegmentDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDateSegmentDetails = RawDateSegmentDetails;

/// Renamed [RawDateSegmentType] in ui_core 0.4.0.
@Deprecated(
  'Use RawDateSegmentType. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDateSegmentType = RawDateSegmentType;

/// Renamed [RawAlertDialog] in ui_core 0.4.0.
@Deprecated(
  'Use RawAlertDialog. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDialog = RawAlertDialog;

/// Renamed [RawDialogAction] in ui_core 0.4.0.
@Deprecated(
  'Use RawDialogAction. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDialogAction = RawDialogAction;

/// Renamed [RawDialogActionBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawDialogActionBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDialogActionBuilder = RawDialogActionBuilder;

/// Renamed [RawDialogActionDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawDialogActionDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDialogActionDetails = RawDialogActionDetails;

/// Renamed [RawAlertDialogFrameDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawAlertDialogFrameDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDialogFrameDetails = RawAlertDialogFrameDetails;

/// Renamed [RawAlertDialogPartBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawAlertDialogPartBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDialogPartBuilder = RawAlertDialogPartBuilder;

/// Renamed [RawDividerBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawDividerBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignDividerBuilder = RawDividerBuilder;

/// Renamed [RawInputDecorator] in ui_core 0.4.0.
@Deprecated(
  'Use RawInputDecorator. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignField = RawInputDecorator;

/// Renamed [RawInputDecoratorBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawInputDecoratorBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignFieldBuilder = RawInputDecoratorBuilder;

/// Renamed [RawInputDecoratorDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawInputDecoratorDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignFieldParts = RawInputDecoratorDetails;

/// Renamed [RawOptionsSurfaceBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawOptionsSurfaceBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignListSurfaceBuilder = RawOptionsSurfaceBuilder;

/// Renamed [RawWidgetsLocalizations] in ui_core 0.4.0.
@Deprecated(
  'Use RawWidgetsLocalizations. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignLocalizations = RawWidgetsLocalizations;

/// Renamed [RawMenuBar] in ui_core 0.4.0.
@Deprecated('Use RawMenuBar. This feature was deprecated after ui_core 0.4.0.')
typedef DesignMenuBar = RawMenuBar;

/// Renamed [RawMenuEntry] in ui_core 0.4.0.
@Deprecated(
  'Use RawMenuEntry. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignMenuEntry = RawMenuEntry;

/// Renamed [RawMenuItemBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawMenuItemBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignMenuItemBuilder = RawMenuItemBuilder;

/// Renamed [RawMenuLevel] in ui_core 0.4.0.
@Deprecated(
  'Use RawMenuLevel. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignMenuLevel = RawMenuLevel;

/// Renamed [RawMenuBarOverlayBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawMenuBarOverlayBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignMenuSurfaceBuilder = RawMenuBarOverlayBuilder;

/// Renamed [RawNumberField] in ui_core 0.4.0.
@Deprecated(
  'Use RawNumberField. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignNumberField = RawNumberField;

/// Renamed [RawNumberFieldBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawNumberFieldBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignNumberFieldBuilder = RawNumberFieldBuilder;

/// Renamed [RawNumberFieldButtonBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawNumberFieldButtonBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignNumberFieldButtonBuilder = RawNumberFieldButtonBuilder;

/// Renamed [RawNumberFieldButtonDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawNumberFieldButtonDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignNumberFieldButtonDetails = RawNumberFieldButtonDetails;

/// Renamed [RawNumberFieldDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawNumberFieldDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignNumberFieldDetails = RawNumberFieldDetails;

/// Renamed [RawNumberFieldLayoutBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawNumberFieldLayoutBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignNumberFieldLayoutBuilder = RawNumberFieldLayoutBuilder;

/// Renamed [RawOptionBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawOptionBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignOptionBuilder<T> = RawOptionBuilder<T>;

/// Renamed [RawOtpContextMenuBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawOtpContextMenuBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignOtpContextMenuBuilder = RawOtpContextMenuBuilder;

/// Renamed [RawOtpController] in ui_core 0.4.0.
@Deprecated(
  'Use RawOtpController. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignOtpController = RawOtpController;

/// Renamed [RawOtpField] in ui_core 0.4.0.
@Deprecated('Use RawOtpField. This feature was deprecated after ui_core 0.4.0.')
typedef DesignOtpField = RawOtpField;

/// Renamed [RawOtpLayoutBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawOtpLayoutBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignOtpLayoutBuilder = RawOtpLayoutBuilder;

/// Renamed [RawOtpSlot] in ui_core 0.4.0.
@Deprecated('Use RawOtpSlot. This feature was deprecated after ui_core 0.4.0.')
typedef DesignOtpSlot = RawOtpSlot;

/// Renamed [RawOtpSlotBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawOtpSlotBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignOtpSlotBuilder = RawOtpSlotBuilder;

/// Renamed [RawPopoverAlign] in ui_core 0.4.0.
@Deprecated(
  'Use RawPopoverAlign. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignOverlayAlign = RawPopoverAlign;

/// Renamed [RawPopoverInfo] in ui_core 0.4.0.
@Deprecated(
  'Use RawPopoverInfo. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignOverlayInfo = RawPopoverInfo;

/// Renamed [RawPopoverPadding] in ui_core 0.4.0.
@Deprecated(
  'Use RawPopoverPadding. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignOverlayPadding = RawPopoverPadding;

/// Renamed [RawPopoverPlacement] in ui_core 0.4.0.
@Deprecated(
  'Use RawPopoverPlacement. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignOverlayPlacement = RawPopoverPlacement;

/// Renamed [RawPopoverSide] in ui_core 0.4.0.
@Deprecated(
  'Use RawPopoverSide. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignOverlaySide = RawPopoverSide;

/// Renamed [RawPopoverOverlayBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawPopoverOverlayBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignOverlaySurfaceBuilder = RawPopoverOverlayBuilder;

/// Renamed [RawPopoverTrigger] in ui_core 0.4.0.
@Deprecated(
  'Use RawPopoverTrigger. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignOverlayTrigger = RawPopoverTrigger;

/// Renamed [RawPaletteLayoutBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawPaletteLayoutBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignPaletteLayoutBuilder = RawPaletteLayoutBuilder;

/// Renamed [RawPasswordController] in ui_core 0.4.0.
@Deprecated(
  'Use RawPasswordController. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignPasswordController = RawPasswordController;

/// Renamed [RawPasswordDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawPasswordDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignPasswordDetails = RawPasswordDetails;

/// Renamed [RawPasswordReveal] in ui_core 0.4.0.
@Deprecated(
  'Use RawPasswordReveal. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignPasswordReveal = RawPasswordReveal;

/// Renamed [RawButton] in ui_core 0.4.0.
@Deprecated('Use RawButton. This feature was deprecated after ui_core 0.4.0.')
typedef DesignPressable = RawButton;

/// Renamed [RawButtonBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawButtonBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignPressableBuilder = RawButtonBuilder;

/// Renamed [RawButtonState] in ui_core 0.4.0.
@Deprecated(
  'Use RawButtonState. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignPressableState = RawButtonState;

/// Renamed [RawRefreshIndicator] in ui_core 0.4.0.
@Deprecated(
  'Use RawRefreshIndicator. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignPullToRefresh = RawRefreshIndicator;

/// Renamed [RawRefreshIndicatorState] in ui_core 0.4.0.
@Deprecated(
  'Use RawRefreshIndicatorState. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignPullToRefreshState = RawRefreshIndicatorState;

/// Renamed [RawRangeSlider] in ui_core 0.4.0.
@Deprecated(
  'Use RawRangeSlider. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignRangeSlider = RawRangeSlider;

/// Renamed [RawRangeSliderTrackDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawRangeSliderTrackDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignRangeTrack = RawRangeSliderTrackDetails;

/// Renamed [RawRangeValues] in ui_core 0.4.0.
@Deprecated(
  'Use RawRangeValues. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignRangeValues = RawRangeValues;

/// Renamed [RawRating] in ui_core 0.4.0.
@Deprecated('Use RawRating. This feature was deprecated after ui_core 0.4.0.')
typedef DesignRating = RawRating;

/// Renamed [RawRatingItemBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawRatingItemBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignRatingItemBuilder = RawRatingItemBuilder;

/// Renamed [RawRatingItemDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawRatingItemDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignRatingItemDetails = RawRatingItemDetails;

/// Renamed [RawRatingLayoutBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawRatingLayoutBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignRatingLayoutBuilder = RawRatingLayoutBuilder;

/// Renamed [RawRefreshIndicatorDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawRefreshIndicatorDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignRefreshDetails = RawRefreshIndicatorDetails;

/// Renamed [RawRefreshIndicatorMode] in ui_core 0.4.0.
@Deprecated(
  'Use RawRefreshIndicatorMode. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignRefreshMode = RawRefreshIndicatorMode;

/// Renamed [RawReorderItemDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawReorderItemDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignReorderItem = RawReorderItemDetails;

/// Renamed [RawReorderableList] in ui_core 0.4.0.
@Deprecated(
  'Use RawReorderableList. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignReorderableList<T extends Object> = RawReorderableList<T>;

/// Renamed [RawScrollArea] in ui_core 0.4.0.
@Deprecated(
  'Use RawScrollArea. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignScrollArea = RawScrollArea;

/// Renamed [RawScrollbarThumbDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawScrollbarThumbDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignScrollThumb = RawScrollbarThumbDetails;

/// Renamed [RawScrollbarThumbBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawScrollbarThumbBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignScrollbarBuilder = RawScrollbarThumbBuilder;

/// Renamed [RawSearchError] in ui_core 0.4.0.
@Deprecated(
  'Use RawSearchError. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSearchError = RawSearchError;

/// Renamed [RawSearchErrorBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawSearchErrorBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSearchErrorBuilder = RawSearchErrorBuilder;

/// Renamed [RawDataTableSelection] in ui_core 0.4.0.
@Deprecated(
  'Use RawDataTableSelection. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSelection = RawDataTableSelection;

/// Renamed [RawSheetEdge] in ui_core 0.4.0.
@Deprecated(
  'Use RawSheetEdge. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSheetEdge = RawSheetEdge;

/// Renamed [RawSideSheetDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawSideSheetDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSheetInfo = RawSideSheetDetails;

/// Renamed [RawSheetRoute] in ui_core 0.4.0.
@Deprecated(
  'Use RawSheetRoute. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSheetPageRoute<T> = RawSheetRoute<T>;

/// Renamed [RawSideSheetRoute] in ui_core 0.4.0.
@Deprecated(
  'Use RawSideSheetRoute. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSideSheetRoute<T> = RawSideSheetRoute<T>;

/// Renamed [RawSortDirection] in ui_core 0.4.0.
@Deprecated(
  'Use RawSortDirection. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSortDirection = RawSortDirection;

/// Renamed [RawSplitAction] in ui_core 0.4.0.
@Deprecated(
  'Use RawSplitAction. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSplitAction = RawSplitAction;

/// Renamed [RawSplitButton] in ui_core 0.4.0.
@Deprecated(
  'Use RawSplitButton. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSplitButton = RawSplitButton;

/// Renamed [RawSplitPart] in ui_core 0.4.0.
@Deprecated(
  'Use RawSplitPart. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSplitPart = RawSplitPart;

/// Renamed [RawSplitView] in ui_core 0.4.0.
@Deprecated(
  'Use RawSplitView. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSplitView = RawSplitView;

/// Renamed [RawSwipeAction] in ui_core 0.4.0.
@Deprecated(
  'Use RawSwipeAction. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSwipeAction = RawSwipeAction;

/// Renamed [RawSwipeActionBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawSwipeActionBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSwipeActionBuilder = RawSwipeActionBuilder;

/// Renamed [RawSwipeActionDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawSwipeActionDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSwipeActionDetails = RawSwipeActionDetails;

/// Renamed [RawSwipeActions] in ui_core 0.4.0.
@Deprecated(
  'Use RawSwipeActions. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSwipeActions = RawSwipeActions;

/// Renamed [RawSwipeActionsController] in ui_core 0.4.0.
@Deprecated(
  'Use RawSwipeActionsController. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSwipeActionsController = RawSwipeActionsController;

/// Renamed [SwipeBackPageTransitionsBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use SwipeBackPageTransitionsBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignSwipeBackPageTransitionsBuilder = SwipeBackPageTransitionsBuilder;

/// Renamed [RawTab] in ui_core 0.4.0.
@Deprecated('Use RawTab. This feature was deprecated after ui_core 0.4.0.')
typedef DesignTab = RawTab;

/// Renamed [RawTabBar] in ui_core 0.4.0.
@Deprecated('Use RawTabBar. This feature was deprecated after ui_core 0.4.0.')
typedef DesignTabBar = RawTabBar;

/// Renamed [RawTabBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawTabBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTabBuilder = RawTabBuilder;

/// Renamed [RawTabController] in ui_core 0.4.0.
@Deprecated(
  'Use RawTabController. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTabController = RawTabController;

/// Renamed [RawTabDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawTabDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTabDetails = RawTabDetails;

/// Renamed [RawTabIndicatorBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawTabIndicatorBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTabIndicatorBuilder = RawTabIndicatorBuilder;

/// Renamed [RawTabIndicatorDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawTabIndicatorDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTabIndicatorDetails = RawTabIndicatorDetails;

/// Renamed [RawTabBarView] in ui_core 0.4.0.
@Deprecated(
  'Use RawTabBarView. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTabView = RawTabBarView;

/// Renamed [RawDataColumn] in ui_core 0.4.0.
@Deprecated(
  'Use RawDataColumn. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTableColumn<R> = RawDataColumn<R>;

/// Renamed [RawDataTableController] in ui_core 0.4.0.
@Deprecated(
  'Use RawDataTableController. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTableController<R> = RawDataTableController<R>;

/// Renamed [RawDataTableHeaderBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawDataTableHeaderBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTableHeaderBuilder<R> = RawDataTableHeaderBuilder<R>;

/// Renamed [RawDataRowDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawDataRowDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTableRow<R> = RawDataRowDetails<R>;

/// Renamed [RawTagBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawTagBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTagBuilder<T> = RawTagBuilder<T>;

/// Renamed [RawTagDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawTagDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTagDetails = RawTagDetails;

/// Renamed [RawTagInput] in ui_core 0.4.0.
@Deprecated('Use RawTagInput. This feature was deprecated after ui_core 0.4.0.')
typedef DesignTagInput<T extends Object> = RawTagInput<T>;

/// Renamed [RawTagLayoutBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawTagLayoutBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTagLayoutBuilder = RawTagLayoutBuilder;

/// Renamed [TapTargetPadding] in ui_core 0.4.0.
@Deprecated(
  'Use TapTargetPadding. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTapTarget = TapTargetPadding;

/// Renamed [RawTimeField] in ui_core 0.4.0.
@Deprecated(
  'Use RawTimeField. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTimeField = RawTimeField;

/// Renamed [RawTimeOfDay] in ui_core 0.4.0.
@Deprecated(
  'Use RawTimeOfDay. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignTimeOfDay = RawTimeOfDay;

/// Renamed [RawToast] in ui_core 0.4.0.
@Deprecated('Use RawToast. This feature was deprecated after ui_core 0.4.0.')
typedef DesignToast = RawToast;

/// Renamed [RawToastBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawToastBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignToastBuilder = RawToastBuilder;

/// Renamed [RawToastClosedReason] in ui_core 0.4.0.
@Deprecated(
  'Use RawToastClosedReason. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignToastClosedReason = RawToastClosedReason;

/// Renamed [RawToastDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawToastDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignToastDetails = RawToastDetails;

/// Renamed [RawToastController] in ui_core 0.4.0.
@Deprecated(
  'Use RawToastController. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignToastHandle = RawToastController;

/// Renamed [RawToastStackBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawToastStackBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignToastStackBuilder = RawToastStackBuilder;

/// Renamed [RawToaster] in ui_core 0.4.0.
@Deprecated('Use RawToaster. This feature was deprecated after ui_core 0.4.0.')
typedef DesignToaster = RawToaster;

/// Renamed [RawToasterState] in ui_core 0.4.0.
@Deprecated(
  'Use RawToasterState. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignToasterState = RawToasterState;

/// Renamed [RawSegmentedButton] in ui_core 0.4.0.
@Deprecated(
  'Use RawSegmentedButton. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignToggleGroup<T> = RawSegmentedButton<T>;

/// Renamed [RawSegmentBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawSegmentBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignToggleItemBuilder<T> = RawSegmentBuilder<T>;

/// Renamed [RawPickerColumn] in ui_core 0.4.0.
@Deprecated(
  'Use RawPickerColumn. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignWheelColumn = RawPickerColumn;

/// Renamed [RawPickerColumnBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawPickerColumnBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignWheelColumnBuilder = RawPickerColumnBuilder;

/// Renamed [RawPickerColumnDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawPickerColumnDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignWheelColumnDetails = RawPickerColumnDetails;

/// Renamed [RawPickerItemBuilder] in ui_core 0.4.0.
@Deprecated(
  'Use RawPickerItemBuilder. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignWheelItemBuilder = RawPickerItemBuilder;

/// Renamed [RawPickerItemDetails] in ui_core 0.4.0.
@Deprecated(
  'Use RawPickerItemDetails. This feature was deprecated after ui_core 0.4.0.',
)
typedef DesignWheelItemDetails = RawPickerItemDetails;

/// Renamed [RawPicker] in ui_core 0.4.0.
@Deprecated('Use RawPicker. This feature was deprecated after ui_core 0.4.0.')
typedef DesignWheelPicker = RawPicker;

/// Renamed [RenderTapTargetPadding] in ui_core 0.4.0.
@Deprecated(
  'Use RenderTapTargetPadding. This feature was deprecated after ui_core 0.4.0.',
)
typedef RenderDesignTapTarget = RenderTapTargetPadding;
