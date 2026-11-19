/// Brutal's other actions: [BrutalButtonGroup] (a toolbar, one raised strip
/// of cells on shared rules), [BrutalToggleGroup] (a flat strip of cells that
/// stay pressed), [BrutalLink] (underlined words) and [BrutalKbd] (keys as
/// small raised caps).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'surface.dart';
import 'theme.dart';

/// One cell of a [BrutalButtonGroup]: words, a glyph, or both.
@immutable
class BrutalButtonGroupItem {
  /// A cell that runs [onPressed]; null disables it.
  const BrutalButtonGroupItem({
    required this.onPressed,
    this.label,
    this.icon,
    this.tooltip,
  }) : assert(label != null || icon != null, 'Give the cell words or a glyph');

  /// What a press does; null disables the cell.
  final VoidCallback? onPressed;

  /// The words.
  final String? label;

  /// A glyph, before the words when there are any.
  final IconData? icon;

  /// What a screen reader calls a cell of a glyph alone.
  final String? tooltip;
}

/// A toolbar: cells butted on shared rules in one raised strip with its
/// hard shadow. A pressed cell goes ink with paper words; the keyboard's
/// cell gets the inset focus rule. Its words grow with the reader's text to
/// twice their size, as Material's time picker's figures do, and keep that
/// size beyond, so they stay whole in the strip's height.
///
/// ```dart
/// BrutalButtonGroup(semanticLabel: 'Ticket', items: [BrutalButtonGroupItem(label: 'Print', icon: LucideIcons.printer, onPressed: printTicket), BrutalButtonGroupItem(label: 'Share', icon: LucideIcons.share2, onPressed: share)])
/// ```
class BrutalButtonGroup extends StatelessWidget {
  /// A strip of [items].
  const BrutalButtonGroup({
    super.key,
    required this.items,
    this.semanticLabel,
    this.style,
  });

  /// The cells, start to end.
  final List<BrutalButtonGroupItem> items;

  /// What a screen reader calls the toolbar.
  final String? semanticLabel;

  /// Its style, over [BrutalThemeData.buttonGroupStyle]: `fill` and `edge`
  /// for the strip; `foreground`, `padding`, `minimumSize` (the strip's
  /// height), `textStyle` and `iconSize` for each cell in its states.
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.buttonGroupStyle];
    final strip = DesignStyleOf(layers, const {});
    final height = strip.minimumSize?.height ?? theme.controlHeight;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxTextScale,
      child: Semantics(
        container: true,
        label: semanticLabel,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: SizedBox(
            height: height,
            child: BrutalSurface(
              face: BrutalFace(
                fill: strip.fill ?? c.surface,
                border: strip.side?.color ?? strip.edge ?? c.ink,
                foreground: c.ink,
                shadow: c.ink,
              ),
              // Too wide for its room (at large text), the cells scroll inside
              // the frame.
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, item) in items.indexed) ...[
                      if (i > 0)
                        SizedBox(
                          width: theme.borderWidth,
                          child: ColoredBox(
                            color: strip.side?.color ?? strip.edge ?? c.ink,
                          ),
                        ),
                      _cell(theme, item, height, layers),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // How far its words grow with the reader's text.
  static const double _maxTextScale = 2;

  Widget _cell(
    BrutalThemeData theme,
    BrutalButtonGroupItem item,
    double h,
    List<BrutalStyle?> layers,
  ) {
    final c = theme.colors;
    return DesignTapTarget(
      child: DesignPressable(
        onPressed: item.onPressed,
        semanticLabel: item.label ?? item.tooltip,
        excludeSemantics: true,
        builder: (context, states, _) {
          final layered = DesignStyleOf(layers, states);
          final disabled = states.contains(WidgetState.disabled);
          final lit = states.contains(WidgetState.pressed);
          final words =
              layered.foreground ??
              (disabled
                  ? c.disabled
                  : lit
                  ? c.paper
                  : c.ink);
          return ConstrainedBox(
            constraints: BoxConstraints(minWidth: h - 2 * theme.borderWidth),
            child: AnimatedBrutalSurface(
              stiffness: BrutalMotion.colorStiffness,
              face: BrutalFace(
                fill: lit ? c.ink : c.ink.withValues(alpha: 0),
                border: c.ink.withValues(alpha: 0),
                foreground: words,
                borderWidth: 0,
              ),
              child: CustomPaint(
                foregroundPainter: states.contains(WidgetState.focused)
                    ? BrutalInsetFocusPainter(lit ? c.paper : c.ink)
                    : null,
                child: Padding(
                  padding:
                      layered.padding(Directionality.of(context)) ??
                      EdgeInsets.symmetric(
                        horizontal: item.label == null
                            ? 0
                            : BrutalSpacing.regular +
                                  theme.density.paddingDelta,
                      ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item.icon != null)
                        Icon(
                          item.icon,
                          size: layered.iconSize ?? 20,
                          color: words,
                        ),
                      if (item.icon != null && item.label != null)
                        const SizedBox(width: BrutalSpacing.small),
                      if (item.label != null)
                        DesignCapCenter(
                          capHeightFactor: BrutalTheme.of(context)
                              .capHeightFactor,
                          child: Text(
                            item.label!,
                            maxLines: 1,
                            style: layered.text(
                              theme.textTheme.label.copyWith(color: words),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('items', items.length));
  }
}

/// Toggles in a flat ruled strip: each cell stays ink, its glyph or words
/// paper, while it is on. Several may be on at once unless
/// [multiSelectionEnabled] is false; then it is one choice, read as a radio
/// group. Given [iconOf], each cell is a square glyph and [labelOf] names it
/// for a screen reader.
///
/// The arrows move along the strip, Space and Enter press. A null
/// [onSelectionChanged] disables it.
///
/// ```dart
/// BrutalToggleGroup<String>(options: const ['bold', 'italic', 'underline'], selected: styles, onSelectionChanged: (next) => setState(() => styles = next), labelOf: (s) => s, iconOf: (s) => icons[s]!)
/// ```
class BrutalToggleGroup<T> extends StatelessWidget {
  /// A strip of toggles over [options].
  const BrutalToggleGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelectionChanged,
    required this.labelOf,
    this.iconOf,
    this.multiSelectionEnabled = true,
    this.emptySelectionAllowed = true,
    this.semanticLabel,
    this.style,
  });

  /// The toggles, start to end.
  final List<T> options;

  /// Those on.
  final Set<T> selected;

  /// Called with the new set when a toggle is pressed; null disables it.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Each toggle's words (or, with [iconOf], its name).
  final String Function(T value) labelOf;

  /// Each toggle's glyph; the cells show glyphs alone when given.
  final IconData Function(T value)? iconOf;

  /// Whether more than one may be on.
  final bool multiSelectionEnabled;

  /// Whether every toggle may be off.
  final bool emptySelectionAllowed;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  /// Its style, over [BrutalThemeData.toggleGroupStyle]: `fill` and `edge`
  /// for the strip; `foreground`, `padding`, `minimumSize` (the strip's
  /// height), `textStyle` and `iconSize` for each cell in its states.
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final enabled = onSelectionChanged != null;
    final layers = [style, theme.toggleGroupStyle];
    final strip = DesignStyleOf(layers, {if (!enabled) WidgetState.disabled});
    final rule =
        strip.side?.color ?? strip.edge ?? (enabled ? c.ink : c.disabled);
    final height = strip.minimumSize?.height ?? theme.controlHeight;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        height: height,
        child: BrutalSurface(
          face: BrutalFace(
            fill: strip.fill ?? c.surface,
            border: rule,
            foreground: c.ink,
          ),
          child: DesignToggleGroup<T>(
            options: options,
            selected: selected,
            onSelectionChanged: onSelectionChanged,
            multiSelectionEnabled: multiSelectionEnabled,
            emptySelectionAllowed: emptySelectionAllowed,
            labelOf: labelOf,
            semanticLabel: semanticLabel,
            minimumSize: Size.zero,
            // Too wide for its room (at large text), the cells scroll inside
            // the frame.
            layoutBuilder: (context, items) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, item) in items.indexed) ...[
                    if (i > 0)
                      SizedBox(
                        width: theme.borderWidth,
                        child: ColoredBox(color: rule),
                      ),
                    item,
                  ],
                ],
              ),
            ),
            itemBuilder: (context, value, states) {
              final layered = DesignStyleOf(layers, states);
              final disabled = states.contains(WidgetState.disabled);
              final on = states.contains(WidgetState.selected);
              final lit = on || states.contains(WidgetState.pressed);
              final words =
                  layered.foreground ??
                  (disabled
                      ? (on ? c.surface : c.disabled)
                      : lit
                      ? c.paper
                      : c.ink);
              final icon = iconOf?.call(value);
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: height - 2 * theme.borderWidth,
                ),
                child: AnimatedBrutalSurface(
                  stiffness: BrutalMotion.colorStiffness,
                  face: BrutalFace(
                    fill: lit
                        ? (disabled ? c.disabled : c.ink)
                        : c.ink.withValues(alpha: 0),
                    border: c.ink.withValues(alpha: 0),
                    foreground: words,
                    borderWidth: 0,
                  ),
                  child: CustomPaint(
                    foregroundPainter: states.contains(WidgetState.focused)
                        ? BrutalInsetFocusPainter(lit ? c.paper : c.ink)
                        : null,
                    child: Center(
                      widthFactor: 1,
                      child: icon != null
                          ? Icon(
                              icon,
                              size: layered.iconSize ?? 20,
                              color: words,
                            )
                          : Padding(
                              padding:
                                  layered.padding(Directionality.of(context)) ??
                                  const EdgeInsets.symmetric(
                                    horizontal: BrutalSpacing.regular,
                                  ),
                              child: DesignCapCenter(
                                capHeightFactor: BrutalTheme.of(context)
                                    .capHeightFactor,
                                child: Text(
                                  labelOf(value),
                                  maxLines: 1,
                                  style: layered.text(
                                    theme.textTheme.label.copyWith(
                                      fontSize: 15,
                                      height: 20 / 15,
                                      color: words,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('selected', selected))
      ..add(
        FlagProperty(
          'multiSelectionEnabled',
          value: multiSelectionEnabled,
          ifTrue: 'multiple',
        ),
      )
      ..add(
        FlagProperty(
          'enabled',
          value: onSelectionChanged != null,
          ifFalse: 'disabled',
        ),
      );
  }
}

/// Words that go somewhere: ink, underlined on a 2 px rule. A press
/// inverts them (paper words on an ink bar); the keyboard's link gets the
/// focus rule round it. A null [onPressed] greys it.
///
/// Reads [style]'s `foreground` (the words and their rule, in its states)
/// and `textStyle`, then [BrutalThemeData.linkStyle]'s.
///
/// ```dart
/// BrutalLink('Terms of sale', onPressed: () => open(terms))
/// ```
class BrutalLink extends StatelessWidget {
  /// A link reading [text].
  const BrutalLink(
    this.text, {
    super.key,
    required this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// The words.
  final String text;

  /// Where it goes; null disables it.
  final VoidCallback? onPressed;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Its style, over [BrutalThemeData.linkStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    return DesignTapTarget(
      child: DesignPressable(
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        link: true,
        button: false,
        semanticLabel: text,
        excludeSemantics: true,
        builder: (context, states, _) {
          final layered = DesignStyleOf([style, theme.linkStyle], states);
          final disabled = states.contains(WidgetState.disabled);
          final pressed = states.contains(WidgetState.pressed);
          final words =
              layered.foreground ??
              (disabled
                  ? c.disabled
                  : pressed
                  ? c.paper
                  : c.ink);
          return BrutalSurface(
            face: BrutalFace(
              fill: pressed ? c.ink : c.ink.withValues(alpha: 0),
              border: c.ink.withValues(alpha: 0),
              foreground: words,
              borderWidth: 0,
              focus: states.contains(WidgetState.focused)
                  ? c.ink
                  : c.ink.withValues(alpha: 0),
            ),
            child: Text(
              text,
              style: layered.text(
                theme.textTheme.body.copyWith(
                  color: words,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: words,
                  decorationThickness: theme.borderWidth,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('text', text))
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      );
  }
}

/// Keys to press together, each a small raised cap in the rule over its
/// hard shadow. [BrutalKbd.shortcut] prints a keyboard shortcut's keys in
/// the platform's order and the reader's words (ui_core's
/// [designShortcutKeys]: `⇧ ⌘ N` on a Mac, `Ctrl Shift N` elsewhere); the
/// plain constructor prints the [keys] it is given. A screen reader hears
/// [semanticLabel], or the shortcut in words, or the keys one after another.
///
/// Reads [style]'s `fill`, `foreground`, `edge`, `padding`, `minimumSize`
/// and `textStyle` for each cap, then [BrutalThemeData.kbdStyle]'s.
///
/// ```dart
/// const BrutalKbd.shortcut(SingleActivator(LogicalKeyboardKey.keyK, control: true))
/// ```
class BrutalKbd extends StatelessWidget {
  /// The caps for [keys].
  const BrutalKbd(this.keys, {super.key, this.semanticLabel, this.style})
    : activator = null;

  /// The caps of [activator]'s keys (a [SingleActivator] or a
  /// [CharacterActivator]), as Flutter's own menus print them.
  const BrutalKbd.shortcut(
    MenuSerializableShortcut this.activator, {
    super.key,
    this.semanticLabel,
    this.style,
  }) : keys = const [];

  /// The keys, in the order they are held; empty for [BrutalKbd.shortcut].
  final List<String> keys;

  /// The shortcut whose keys it prints, for [BrutalKbd.shortcut].
  final MenuSerializableShortcut? activator;

  /// What a screen reader hears.
  final String? semanticLabel;

  /// Its style, over [BrutalThemeData.kbdStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.kbdStyle], const {});
    final minimum = layered.minimumSize ?? const Size(28, 28);
    final activator = this.activator;
    final keys = activator == null
        ? this.keys
        : designShortcutKeys(context, activator);
    return Semantics(
      label:
          semanticLabel ??
          (activator == null
              ? keys.join(' ')
              : designShortcutLabel(context, activator, appleSymbols: false)),
      excludeSemantics: true,
      child: Padding(
        // The shadows' room, so a line under the caps does not run into them.
        padding: EdgeInsetsDirectional.only(
          end: theme.shadowOffset,
          bottom: theme.shadowOffset,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, key) in keys.indexed) ...[
              if (i > 0) const SizedBox(width: BrutalSpacing.small),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: minimum.width,
                  minHeight: minimum.height,
                ),
                child: BrutalSurface(
                  face: layered.on(
                    BrutalFace(
                      fill: c.surface,
                      border: c.ink,
                      foreground: c.ink,
                      shadow: c.ink,
                    ),
                  ),
                  child: Padding(
                    padding:
                        layered.padding(Directionality.of(context)) ??
                        const EdgeInsets.symmetric(
                          horizontal: BrutalSpacing.tight + 2,
                        ),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: DesignCapCenter(
                        capHeightFactor: BrutalTheme.of(context)
                            .capHeightFactor,
                        child: Text(
                          key,
                          maxLines: 1,
                          style: layered.text(
                            theme.textTheme.caption.copyWith(
                              letterSpacing: 0,
                              height: 16 / 12,
                              color: layered.foreground,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('keys', keys))
      ..add(
        DiagnosticsProperty<MenuSerializableShortcut>(
          'activator',
          activator,
          defaultValue: null,
        ),
      );
  }
}
