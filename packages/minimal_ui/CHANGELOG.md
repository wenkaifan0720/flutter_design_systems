## 0.1.0

First release of Minimal as a package.

- **The theme.** `MinimalTheme(data:)`, the one install widget, with `of`/`maybeOf`, and `AnimatedMinimalTheme`.
  `MinimalThemeData` is shaped like `ThemeData` (`copyWith`, `lerp`, equality, diagnostics), with three presets
  (standard, graphite, ember), each designed in light and dark, and `MinimalThemeData.from(primary:, neutral:)` for an
  app's own colours, which keeps every role's contrast whatever colours it is given. The colour roles take shadcn's
  names: `background`, `foreground`, `card`, `muted`, `mutedForeground`, `primary`, `primaryForeground`,
  `destructive`, `border`, `input`, `ring`, with subtle fills and text inks beside the status colours.
- **The knobs.** `MinimalShapes` (one radius and the corner scale derived from it, `pill` for capsule roles),
  `MinimalDensity` (the platform's own unless set) and `MinimalTypeface`; per-part `MinimalStyle`s in
  `MinimalComponentThemes`, and a `style:` on each part that takes one. A part inside another is its frame's outline
  moved in (`MinimalShapes.inset`), and a press wash or focus ring takes the part's exact outline.
- **The parts**, by the names Material gives them: buttons (`MinimalButton` with `primary`, `secondary`, `ghost` and
  `destructive` variants in `small`, `medium` and `large`, `MinimalIconButton`, `MinimalButtonGroup`,
  `MinimalSplitButton`, `MinimalToggleGroup`, `MinimalSegmentedButton`, `MinimalLink`); fields (`MinimalTextField`,
  `MinimalTextArea`, `MinimalPasswordField`, `MinimalInputOtp`, `MinimalInputGroup`, `MinimalSelect`,
  `MinimalCombobox`, `MinimalMultiSelect`, `MinimalSearchField`, `MinimalFormField`, `MinimalForm`,
  `MinimalFileUpload`); choices (`MinimalCheckbox`, `MinimalSwitch`, `MinimalRadioGroup`, `MinimalSlider`,
  `MinimalRangeSlider`, `MinimalRating`); dates and times (`MinimalCalendar`, `MinimalDatePicker`,
  `MinimalDateRangePicker`, `MinimalTimePicker`, which takes a `DateTime`'s clock); lists and data (`MinimalListTile`,
  `MinimalListSection`, `MinimalDataTable`, `MinimalTreeView`, `MinimalReorderableListView`,
  `MinimalRefreshIndicator`, `MinimalStat` and `MinimalStatRow`, line, area and donut charts); navigation
  (`MinimalAppBar`, `MinimalNavigationBar`, `MinimalNavigationRail`, `MinimalNavigationDrawer`, `MinimalTabBar`,
  `MinimalBreadcrumb`, `MinimalMenuBar`, `MinimalPagination`, `MinimalPageDots`, `MinimalStepProgress`); overlays
  (`MinimalDialog`, `MinimalBottomSheet`, the side `MinimalSheet`, `MinimalActionSheet`, `MinimalPopover`,
  `MinimalHoverCard`, `MinimalMenu`, `MinimalTooltip`, the command palette, `MinimalSnackBar` under a
  `MinimalToaster`); and feedback (`MinimalBanner`, `MinimalCircularProgressIndicator`, `MinimalSkeleton`,
  `MinimalMeter`, `MinimalBadge`, `MinimalStatusView`). Every public member is documented, with an example.
- **Behaviour from ui_core.** State, keys, focus, semantics, right to left, Reduce Motion and 44 px targets are
  ui_core's; every pixel is Minimal's. Values the behaviours share are ui_core's types (`DesignRangeValues`,
  `DesignDateRange`), so an app's own `flutter/material.dart` import never clashes with them.
- **Every size of screen.** From 960 px wide a sheet page stands as a card centred over the dimmed page, not one rising
  from the bottom edge; the example's apps put their list beside the open record.
- **States at idle size.** Pressed, disabled and wrong each read on the control at its idle size, and none moves the
  layout. A hovering pointer changes nothing unless the app sets an `overlay` for `WidgetState.hovered`.
- **Text entry built one way.** The look draws the box and the editable inside is bare, one line centred in it, so
  neither a desktop's density nor an app's own `InputDecorationTheme` moves a field's line.
- **Sign-in buttons.** `MinimalSignInButton` and `MinimalSignInStack`, with the Apple, Google and GitHub marks bundled;
  an app's own `assets/logos/<slug>_mark.png` adds a provider or replaces a mark.
- **Words.** The words every look shares (Back, Close, Search, Today, the months and weekdays) come from ui_core's
  `DesignLocalizations`, English unless an app registers a `DefaultDesignLocalizations` subclass for its language;
  `MinimalLocalizations.of(context)` reads them with Minimal's own words (English in 0.1.0). `MinimalFormat` prints
  dates, times, money and counts.
- **The host library.** `minimal_host.dart` carries what an app builder's host draws pages under (`MinimalHost`,
  `MinimalPreview`, the route pages, the chrome metrics, `minimalInventory`); the main library leaves it out.
- Geist and Geist Mono bundled (SIL OFL 1.1), loaded by `minimalLoadFonts()`; icons from Lucide (ISC). No router.
