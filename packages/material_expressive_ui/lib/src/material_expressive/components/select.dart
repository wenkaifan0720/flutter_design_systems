/// Select: the exposed dropdown menu, read-only ([ExpressiveSelect]) and
/// editable and filtered ([ExpressiveCombobox]) (CONTRACT §4.1 `select`,
/// `combobox`). Owner: w3-select, with `test/select_test.dart` and the
/// gallery's select demo.
///
/// A port of Compose material3 1.5.0-alpha29's `ExposedDropdownMenuBox`
/// (`ExposedDropdownMenu.kt`; wave decision F1):
///
/// - The anchor is a text field from the text-fields family, filled or
///   outlined (`ExposedDropdownMenuDefaults.textFieldColors()` are
///   `FilledAutocompleteTokens`, the same roles as the plain field's), with
///   `ExposedDropdownMenuDefaults.TrailingIcon`: `arrow_drop_down`, turned
///   half a turn while the menu is open (Compose's `rotate(180f)`, no
///   animation).
/// - A select's field is `menuAnchor(PrimaryNotEditable)`: read-only, a
///   tap anywhere on it toggles the menu, Enter or Space toggles it from
///   the keyboard (`expandable`'s `isClick`), and the menu is a focusable
///   popup whose items take the arrow keys.
/// - A combobox's field is `menuAnchor(PrimaryEditable)`: typing opens the
///   menu over the options that match (the `EditableExposedDropdownMenu`
///   sample's filter), the popup is not focusable so typing goes on
///   (`popupPropertiesForAnchorType`), Enter toggles it, and Down, Up or
///   Tab hand the keyboard to the items. Its trailing icon is
///   `menuAnchor(SecondaryEditable)`: a button toggling the menu without
///   focusing the field.
/// - The menu is as wide as its anchor (`exposedDropdownSize(matchAnchorWidth
///   = true)`), opens below it and keeps inside the window's margins.
///
/// Deviation: Compose's `ExposedDropdownMenu` draws its items in the
/// baseline `DropdownMenuContent` surface (`MenuDefaults.shape`,
/// `surfaceContainer`). Expressive's select draws them in the menus
/// family's expressive `DropdownMenuGroup` — the one menu the system
/// offers, with `SelectableDropdownMenuItem`s marking the chosen option —
/// so a select's menu looks like every other menu in the app.
library;

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../icons.dart';
import '../internal/choice_width.dart';
import '../internal/tokens/behavior.g.dart';
import '../states.dart';
import '../strings.dart';
import '../theme.dart';
import 'menus.dart';
import 'text_fields.dart';

/// One choice of an [ExpressiveSelect] or an [ExpressiveCombobox]: the
/// [value] the app keeps and the [label] the field and the menu show.
@immutable
class ExpressiveSelectOption<T> {
  /// An option standing for [value], labelled [label].
  const ExpressiveSelectOption(
    this.value,
    this.label, {
    this.icon,
    this.supportingText,
    this.enabled = true,
  });

  /// What choosing the option reports.
  final T value;

  /// What the menu shows, and the field once chosen.
  final String label;

  /// A leading glyph in the menu.
  final IconData? icon;

  /// A second line under the label in the menu.
  final String? supportingText;

  /// Whether the option can be chosen.
  final bool enabled;
}

/// `ExposedDropdownMenuDefaults.TrailingIcon`: `arrow_drop_down`, pointing
/// up while [expanded]. Size and colour come from the field's icon slot.
class ExpressiveSelectTrailingIcon extends StatelessWidget {
  /// A trailing icon, pointing up while [expanded].
  const ExpressiveSelectTrailingIcon({required this.expanded, super.key});

  /// Whether the menu is open.
  final bool expanded;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: expanded ? math.pi : 0,
    child: const Icon(ExpressiveSymbols.arrowDropDown),
  );
}

// ---------------------------------------------------------------------------
// Select.

/// An exposed dropdown menu (Compose's `ExposedDropdownMenuBox` around a
/// read-only field): shows the chosen option's label, opens a menu of
/// [options] below itself on a tap, Enter or Space, and reports the choice
/// through [onChanged]. Disabled when [onChanged] is null or [enabled] is
/// false.
///
/// A choice, not an entry: in a window [wideFrom] or wider it is at most
/// [wideMaxWidth] wide, at its column's start, however wide the column (a
/// form's grid cell narrower than that bounds it as before); on a phone it
/// takes its column's width.
class ExpressiveSelect<T> extends StatefulWidget {
  /// A select of [options] with [value] chosen, reporting a choice through [onChanged].
  const ExpressiveSelect({
    required this.options,
    required this.value,
    required this.onChanged,
    this.kind = ExpressiveTextFieldKind.filled,
    this.style,
    this.rounded = false,
    this.tonal = false,
    this.label,
    this.hintText,
    this.leading,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.focusNode,
    this.controller,
    this.menuMaxHeight,
    this.semanticLabel,
    super.key,
  });

  /// The choices, in menu order.
  final List<ExpressiveSelectOption<T>> options;

  /// The chosen option's value; null shows [hintText] (or the bare
  /// label).
  final T? value;

  /// Told the value of the option chosen; the select is disabled when
  /// null.
  final ValueChanged<T>? onChanged;

  /// The field's container: filled or outlined.
  final ExpressiveTextFieldKind kind;

  /// Stateful visual overrides before the component theme.
  final ExpressiveComponentThemeData? style;

  /// Expressive's rounded field shape.
  final bool rounded;

  /// Expressive's tonal field colours.
  final bool tonal;

  /// The field's label.
  final String? label;

  /// Shown in the field while nothing is chosen.
  final String? hintText;

  /// A leading icon in the field.
  final Widget? leading;

  /// A line under the field.
  final String? helperText;

  /// An error line under the field, in the error colours.
  final String? errorText;

  /// Whether the select can be used (a null [onChanged] disables it too).
  final bool enabled;

  /// The field's focus.
  final FocusNode? focusNode;

  /// Opens and closes the menu from the app.
  final ExpressiveMenuController? controller;

  /// The tallest the menu grows before it scrolls; the window bounds it
  /// otherwise.
  final double? menuMaxHeight;

  /// What the select is called to assistive technology ([label] when
  /// null).
  final String? semanticLabel;

  /// The window width from which a select stops taking its column's width.
  static const double wideFrom = 600;

  /// A select's widest in a window [wideFrom] or wider.
  static const double wideMaxWidth = 320;

  @override
  State<ExpressiveSelect<T>> createState() => _ExpressiveSelectState<T>();
}

class _ExpressiveSelectState<T> extends State<ExpressiveSelect<T>>
    with ExpressiveValueStart<ExpressiveSelect<T>> {
  final TextEditingController _text = TextEditingController();
  ExpressiveMenuController? _ownMenu;

  /// The click key pressed down on the field, toggling on its release.
  LogicalKeyboardKey? _pressed;

  ExpressiveMenuController get _menu =>
      widget.controller ?? (_ownMenu ??= ExpressiveMenuController());

  bool get _enabled => widget.enabled && widget.onChanged != null;

  /// The chosen option's icon, for a select with none of its own whose
  /// options carry icons: its list's icons then sit under it.
  Widget? get _chosenIcon => switch (_chosen?.icon) {
    final IconData icon => Icon(icon),
    null => null,
  };

  ExpressiveSelectOption<T>? get _chosen {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _text.text = _chosen?.label ?? '';
    _menu.addListener(_menuChanged);
  }

  @override
  void didUpdateWidget(ExpressiveSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownMenu)?.removeListener(_menuChanged);
      _menu.addListener(_menuChanged);
    }
    final label = _chosen?.label ?? '';
    if (_text.text != label) _text.text = label;
    if (!_enabled && _menu.isOpen) _menu.close();
  }

  @override
  void dispose() {
    (widget.controller ?? _ownMenu)?.removeListener(_menuChanged);
    _ownMenu?.dispose();
    _text.dispose();
    super.dispose();
  }

  void _menuChanged() {
    if (mounted) setState(() {});
  }

  void _toggle() {
    if (_enabled) _menu.toggle();
  }

  /// `expandable`'s keys: Enter or Space (on key up) toggles the menu.
  /// Opened from the keyboard, the menu takes it on its first item.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_enabled || !_isClickKey(event.logicalKey, space: true)) {
      return KeyEventResult.ignored;
    }
    // Only a key pressed here: the up of an Enter that chose an item in
    // the menu arrives here once the menu has closed.
    if (event is KeyDownEvent) _pressed = event.logicalKey;
    if (event is KeyUpEvent && _pressed == event.logicalKey) {
      _pressed = null;
      final opening = !_menu.isOpen;
      _toggle();
      if (opening) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _menu.focusFirstItem(),
        );
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final open = _menu.isOpen;
    measureValueStart();
    return expressiveChoiceWidth(context, _select(context, open));
  }

  Widget _select(BuildContext context, bool open) {
    return ExpressiveMenu(
      controller: _menu,
      matchAnchorWidth: true,
      wordsStart: valueStart,
      maxHeight: widget.menuMaxHeight,
      label: widget.semanticLabel ?? widget.label,
      entries: <ExpressiveMenuEntry>[
        for (final option in widget.options)
          // The row's fill marks the choice; no check, so every option's
          // words start where the field's value does.
          ExpressiveMenuRadioItem(
            option.label,
            selected: option.value == widget.value,
            check: false,
            icon: option.icon,
            supportingText: option.supportingText,
            onSelected: option.enabled
                ? _enabled && option.enabled
                      ? () => widget.onChanged!(option.value)
                      : null
                : null,
          ),
      ],
      builder: (context, menu) => Semantics(
        container: true,
        expanded: open,
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: expressiveWidestOption(
            context,
            [for (final option in widget.options) option.label],
            ExpressiveTextField(
              key: valueFace,
              controller: _text,
              focusNode: widget.focusNode,
              kind: widget.kind,
              style: context.expressiveTheme.selectTheme.merge(widget.style),
              rounded: widget.rounded,
              tonal: widget.tonal,
              label: widget.label,
              hintText: widget.hintText,
              leading: widget.leading ?? _chosenIcon,
              trailing: ExpressiveSelectTrailingIcon(expanded: open),
              helperText: widget.helperText,
              errorText: widget.errorText,
              enabled: _enabled,
              readOnly: true,
              onTap: _toggle,
              semanticLabel: widget.semanticLabel,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Combobox.

/// Whether [option] matches what the user typed.
typedef ExpressiveComboboxFilter<T> = bool Function(
  ExpressiveSelectOption<T> option,
  String query,
);

/// An editable exposed dropdown menu (Compose's `ExposedDropdownMenuBox`
/// around an editable field, the `EditableExposedDropdownMenu` sample):
/// typing opens a menu of the [options] that match the text ([filter]; by
/// default, the label contains it, ignoring case) while focus and typing
/// stay in the field. Choosing one puts its label in the field, the caret
/// at its end, and reports it through [onSelected]. The trailing arrow
/// opens and closes the menu on its own.
class ExpressiveCombobox<T> extends StatefulWidget {
  /// A combobox of [options] that match the typed text.
  const ExpressiveCombobox({
    required this.options,
    this.onSelected,
    this.onChanged,
    this.onSubmitted,
    this.filter,
    this.controller,
    this.focusNode,
    this.menuController,
    this.kind = ExpressiveTextFieldKind.filled,
    this.style,
    this.rounded = false,
    this.tonal = false,
    this.label,
    this.hintText,
    this.leading,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.menuMaxHeight,
    this.semanticLabel,
    this.emptyBuilder,
    super.key,
  });

  /// Every choice, in menu order; the menu shows those [filter] keeps.
  final List<ExpressiveSelectOption<T>> options;

  /// Told the option chosen from the menu.
  final ValueChanged<ExpressiveSelectOption<T>>? onSelected;

  /// Told the text as the user types.
  final ValueChanged<String>? onChanged;

  /// Told the text when the user submits it.
  final ValueChanged<String>? onSubmitted;

  /// Which options the menu shows for the text typed; a case-insensitive
  /// "label contains the text" when null.
  final ExpressiveComboboxFilter<T>? filter;

  /// The field's text.
  final TextEditingController? controller;

  /// The field's focus.
  final FocusNode? focusNode;

  /// Opens and closes the menu from the app.
  final ExpressiveMenuController? menuController;

  /// The field's container: filled or outlined.
  final ExpressiveTextFieldKind kind;

  /// Stateful visual overrides before the component theme.
  final ExpressiveComponentThemeData? style;

  /// Expressive's rounded field shape.
  final bool rounded;

  /// Expressive's tonal field colours.
  final bool tonal;

  /// The field's label.
  final String? label;

  /// Shown in the field while it is empty.
  final String? hintText;

  /// A leading icon in the field.
  final Widget? leading;

  /// A line under the field.
  final String? helperText;

  /// An error line under the field, in the error colours.
  final String? errorText;

  /// Whether the combobox can be used.
  final bool enabled;

  /// Whether the field takes focus when it first appears.
  final bool autofocus;

  /// The keyboard the field asks for.
  final TextInputType? keyboardType;

  /// The keyboard's action button.
  final TextInputAction? textInputAction;

  /// How the keyboard capitalizes.
  final TextCapitalization textCapitalization;

  /// The tallest the menu grows before it scrolls; the window bounds it
  /// otherwise.
  final double? menuMaxHeight;

  /// What the combobox is called to assistive technology ([label] when
  /// null).
  final String? semanticLabel;

  /// What the menu says while the field holds words no option fits, in the
  /// menu's supporting type and ink; null says the look's
  /// [ExpressiveLocalizations.noResults]. (Compose's menu just goes, so a
  /// typed miss looked like a broken field.)
  final WidgetBuilder? emptyBuilder;

  /// The default [filter]: the label contains [query], ignoring case.
  static bool labelContains<T>(
    ExpressiveSelectOption<T> option,
    String query,
  ) => option.label.toLowerCase().contains(query.trim().toLowerCase());

  @override
  State<ExpressiveCombobox<T>> createState() => _ExpressiveComboboxState<T>();
}

class _ExpressiveComboboxState<T> extends State<ExpressiveCombobox<T>>
    with ExpressiveValueStart<ExpressiveCombobox<T>> {
  TextEditingController? _ownText;
  FocusNode? _ownFocus;
  ExpressiveMenuController? _ownMenu;

  /// Whether the user wants the menu: it shows while something matches.
  bool _expanded = false;

  /// The click key pressed down on the field, toggling on its release.
  LogicalKeyboardKey? _pressed;

  TextEditingController get _text =>
      widget.controller ?? (_ownText ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  ExpressiveMenuController get _menu =>
      widget.menuController ?? (_ownMenu ??= ExpressiveMenuController());

  List<ExpressiveSelectOption<T>> get _matches {
    final filter = widget.filter ?? ExpressiveCombobox.labelContains<T>;
    final query = _text.text;
    return <ExpressiveSelectOption<T>>[
      for (final option in widget.options)
        if (filter(option, query)) option,
    ];
  }

  @override
  void initState() {
    super.initState();
    _menu.addListener(_menuChanged);
  }

  @override
  void didUpdateWidget(ExpressiveCombobox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menuController != widget.menuController) {
      (oldWidget.menuController ?? _ownMenu)?.removeListener(_menuChanged);
      _menu.addListener(_menuChanged);
    }
    if (!widget.enabled) _expanded = false;
    _sync();
  }

  @override
  void dispose() {
    (widget.menuController ?? _ownMenu)?.removeListener(_menuChanged);
    _ownMenu?.dispose();
    _ownText?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  /// Whether the field holds words no option fits: the menu says so.
  bool _saysNoMatch(List<ExpressiveSelectOption<T>> matches) =>
      matches.isEmpty && _text.text.trim().isNotEmpty;

  /// Whether the menu has anything to show: a match, or the words that
  /// nothing matches.
  bool get _hasMenu {
    final matches = _matches;
    return matches.isNotEmpty || _saysNoMatch(matches);
  }

  /// The menu opened or closed itself (a choice, a tap outside, the app's
  /// controller): the user's wish follows it.
  void _menuChanged() {
    if (!mounted) return;
    final open = _menu.isOpen;
    if (open) {
      _expanded = true;
    } else if (_hasMenu) {
      _expanded = false;
    }
    setState(() {});
  }

  /// Shows the menu while the user wants it and it has something to show
  /// (Compose: `if (filteredOptions.isNotEmpty()) ExposedDropdownMenu(…)`;
  /// here typed words no option fits keep it, to say so), after the frame
  /// that rebuilt its entries.
  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final show = _expanded && widget.enabled && _hasMenu;
      if (show && !_menu.isOpen) _menu.open();
      if (!show && _menu.isOpen) _menu.close();
    });
  }

  void _setExpanded(bool value) {
    setState(() => _expanded = value);
    _sync();
  }

  void _toggle() {
    if (widget.enabled) _setExpanded(!_menu.isOpen);
  }

  void _typed(String text) {
    _setExpanded(true);
    widget.onChanged?.call(text);
  }

  void _choose(ExpressiveSelectOption<T> option) {
    _text.value = TextEditingValue(
      text: option.label,
      selection: TextSelection.collapsed(offset: option.label.length),
    );
    _expanded = false;
    widget.onSelected?.call(option);
    if (mounted) setState(() {});
  }

  /// `expandable`'s keys for `PrimaryEditable`: Enter toggles the menu;
  /// while it is open, Down, Up or Tab hand the keyboard to its items and
  /// Escape closes it. While it only says nothing matches, Down and Up stay
  /// in the field and Tab closes it and moves on.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (_isClickKey(key, space: false)) {
      if (event is KeyDownEvent) _pressed = key;
      if (event is KeyUpEvent && _pressed == key) {
        _pressed = null;
        _toggle();
      }
      return KeyEventResult.handled;
    }
    if (!_menu.isOpen || event is KeyUpEvent) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.tab) {
      if (_matches.isEmpty) {
        if (key != LogicalKeyboardKey.tab) return KeyEventResult.handled;
        _setExpanded(false);
        return KeyEventResult.ignored;
      }
      _menu.focusFirstItem();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _setExpanded(false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _noMatch(BuildContext context) =>
      Text(ExpressiveLocalizations.of(context).noResults);

  @override
  Widget build(BuildContext context) {
    final open = _menu.isOpen;
    final matches = _matches;
    measureValueStart();
    // A choice as a select is: from [ExpressiveSelect.wideFrom], at most
    // [ExpressiveSelect.wideMaxWidth] at its column's start.
    return expressiveChoiceWidth(
      context,
      ExpressiveMenu(
        controller: _menu,
        modal: false,
        matchAnchorWidth: true,
        wordsStart: valueStart,
        maxHeight: widget.menuMaxHeight,
        label: widget.semanticLabel ?? widget.label,
        entries: <ExpressiveMenuEntry>[
          for (final option in matches)
            ExpressiveMenuItem(
              option.label,
              icon: option.icon,
              supportingText: option.supportingText,
              onPressed: option.enabled ? () => _choose(option) : null,
            ),
          if (_saysNoMatch(matches))
            ExpressiveMenuNote(widget.emptyBuilder ?? _noMatch),
        ],
        builder: (context, menu) => Semantics(
          container: true,
          expanded: open,
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _onKey,
            child: ExpressiveTextField(
              key: valueFace,
              controller: _text,
              focusNode: _focus,
              kind: widget.kind,
              style: context.expressiveTheme.selectTheme.merge(widget.style),
              rounded: widget.rounded,
              tonal: widget.tonal,
              label: widget.label,
              hintText: widget.hintText,
              leading: widget.leading,
              trailing: _ComboboxToggle(
                expanded: open,
                enabled: widget.enabled,
                onToggle: _toggle,
              ),
              helperText: widget.helperText,
              errorText: widget.errorText,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              onChanged: _typed,
              onSubmitted: widget.onSubmitted,
              onTap: _toggle,
              semanticLabel: widget.semanticLabel,
            ),
          ),
        ),
      ),
    );
  }
}

/// A combobox's trailing arrow (`menuAnchor(SecondaryEditable)`): a
/// button, not focusable, that toggles the menu without focusing the
/// field; announced with its expanded state.
class _ComboboxToggle extends StatelessWidget {
  const _ComboboxToggle({
    required this.expanded,
    required this.enabled,
    required this.onToggle,
  });

  final bool expanded;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    expanded: expanded,
    label: expanded
        ? ExpressiveLocalizations.of(context).hideSuggestions
        : ExpressiveLocalizations.of(context).showSuggestions,
    onTap: enabled ? onToggle : null,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: enabled ? onToggle : null,
      // The whole of the field's 48dp icon slot is the toggle's, so its
      // node is the touch target's size, not the glyph's.
      child: ExpressiveMinimumInteractiveSize.enforcedAt(context)
          ? SizedBox.square(
              dimension: HostBehavior.minimumInteractiveComponentSize,
              child: Center(
                child: ExpressiveSelectTrailingIcon(expanded: expanded),
              ),
            )
          : ExpressiveSelectTrailingIcon(expanded: expanded),
    ),
  );
}

/// Compose's `isClick` keys: Enter, the numpad's Enter, the D-pad centre
/// and, when [space], the space bar.
bool _isClickKey(LogicalKeyboardKey key, {required bool space}) =>
    key == LogicalKeyboardKey.enter ||
    key == LogicalKeyboardKey.numpadEnter ||
    key == LogicalKeyboardKey.select ||
    (space && key == LogicalKeyboardKey.space);
