## 0.1.1

- Filter chips (`FrostedFilterChipGroup`) no longer slide a chosen plate across the gaps between them: each chip
  carries its own chosen glass, which fades in where the chip stands while the chip left fades back. The segmented
  control, whose segments share one capsule, still slides.
- `FrostedSlider` shows the click cursor under a mouse, over its whole track and its thumb; while it is off, the
  cursor of what is under it.
- More parts show their cursor under a mouse: the click cursor on `FrostedNavigationBar`'s tabs, `FrostedNavAction`,
  `FrostedRangeSlider`'s track and `FrostedColorPicker`'s hue and opacity tracks (their thumbs keep the resize
  cursor); the open hand on `FrostedReorderableListView`'s grip, a `FrostedSwipeActions` row and a phone sheet's
  grabber.

## 0.1.0

- First release of Frosted as a package: light through frosted glass, by the names Material gives its components
  (`FrostedButton`, `FrostedTextField`, `FrostedSelect`, `FrostedAppBar`, `FrostedNavigationBar`,
  `FrostedNavigationDrawer`, `FrostedListTile`, `FrostedCheckbox`, `FrostedSwitch`, `FrostedSlider`,
  `FrostedSegmentedButton`, `FrostedTabBar`, `FrostedDialog`, `FrostedSnackBar`, ...), with `onPressed`,
  `value`/`onChanged` and `selectedIndex` throughout, from a phone to a desktop (menu bar, command palette, data
  table, tree view, resizable panes, hover card).
- `FrostedThemeData` shaped like Material's: `colorScheme`, `textTheme` (`displayLarge` to `labelSmall`, and the look's
  figures), `shadows`, and the look's own `glass`, `pearl`, `toast` and `hues`, each with `copyWith`; the theme has
  `copyWith`, `lerp` and value equality.
- `FrostedTheme` as an `InheritedTheme` and the whole install, in any app's `builder:` (Material, Cupertino or
  Widgets), with `darkData:` for the dark appearance; `AnimatedFrostedTheme`.
- Seven presets (opal, quartz, garnet, glacier, cobalt, jade, copper), each designed in light and dark, and
  `FrostedThemeData.from(accent:)` for a palette of your own that keeps 4.5:1 for words.
- `FrostedDensity` (standard, comfortable, compact), following the platform until set (compact on macOS, Windows and
  Linux); `FrostedTypeface` for your own faces; `components` for every part's theme; `style:` on the parts, a
  `FrostedStyle` with `ButtonStyle`'s slots.
- Tokens for your own parts: `FrostedCorners` (radii and the look's outlines), `FrostedSpacing`, `FrostedStrokes`,
  `FrostedMotion`.
- `FrostedGlyphs` (the glyphs the components draw, by meaning) and `FrostedLocalizations` (every word they say).
- Frosted's own text selection handles and context menu on every field; nothing of Material shows.
- Every control's target is 48 px under a finger and 44 px under a pointer; faces keep their size.
- `frostedLoadFonts`, to set the first frame in the bundled faces.
- No router: the package takes none.
- Bricolage Grotesque and DM Sans bundled (SIL OFL 1.1); icons from Lucide (ISC).
