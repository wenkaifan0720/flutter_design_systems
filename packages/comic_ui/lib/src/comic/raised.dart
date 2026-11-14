/// Panels and speech raised over the page, with Comic's routes and overlays.
library;

import 'package:ui_core/ui_core.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart' show ShellInsets;

import 'glyphs.dart';

import 'balloons.dart';
import 'controls.dart';
import 'frames.dart';
import 'localizations.dart';
import 'press.dart';
import 'theme.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'rows.dart';
import 'layout.dart';
import 'tell.dart';
import 'tones.dart';
import 'internal/cap_label.dart';
import 'internal/track.dart';

class _Carried {
  _Carried(BuildContext context, NavigatorState navigator)
    : themes = InheritedTheme.capture(from: context, to: navigator.context),
      direction = Directionality.of(context),
      locale = Localizations.maybeLocaleOf(context),
      motion = ComicMotion.of(context),
      scrim = ComicTheme.of(context).colors.scrim,
      words = ComicLocalizations.of(context);
  final CapturedThemes themes;
  final TextDirection direction;
  final Locale? locale;
  final ComicMotion motion;
  final Color scrim;
  final ComicLocalizations words;

  Widget wrap(BuildContext context, Widget child) => Localizations.override(
    context: context,
    locale: locale,
    // The carried themes leave Material's words behind (see ComicTheme.wrap); a raised field still asks for them.
    delegates: [_WordsDelegate(words), ...comicMaterialWords(context)],
    child: themes.wrap(Directionality(textDirection: direction, child: child)),
  );
}

/// Carries [context]'s theme, direction and words over to a surface a route raises on [navigator]. Returns what wraps the
/// surface. Kept out of the barrel.
Widget Function(BuildContext, Widget) comicCarryTo(
  BuildContext context,
  NavigatorState navigator,
) => _Carried(context, navigator).wrap;

class _WordsDelegate extends LocalizationsDelegate<ComicLocalizations> {
  const _WordsDelegate(this.words);
  final ComicLocalizations words;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<ComicLocalizations> load(Locale locale) => SynchronousFuture(words);
  @override
  bool shouldReload(_WordsDelegate old) => !identical(words, old.words);
}

class _ComicRoute<T> extends PopupRoute<T> {
  _ComicRoute({
    required this.carried,
    required this.builder,
    required this.dismissible,
    required this.sheet,
    required this.closeLabel,
    required this.dimBackground,
    this.drawer = false,
  }) : super(
         requestFocus: true,
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
       );
  final _Carried carried;
  final WidgetBuilder builder;
  final bool dismissible, sheet;
  final bool dimBackground;

  /// Stands at the start edge, the window's full height, and slides in from that edge.
  final bool drawer;
  final String closeLabel;
  @override
  bool get barrierDismissible => dismissible;
  @override
  String get barrierLabel => closeLabel;
  @override
  Color? get barrierColor => dimBackground ? carried.scrim : null;
  @override
  Duration get transitionDuration =>
      sheet || drawer ? carried.motion.travel : carried.motion.raise;
  @override
  Duration get reverseTransitionDuration => carried.motion.leave;

  bool _escape(KeyEvent event) {
    if (isCurrent &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      navigator?.maybePop();
      return true;
    }
    return false;
  }

  @override
  void install() {
    super.install();
    HardwareKeyboard.instance.addHandler(_escape);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_escape);
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => carried.wrap(
    context,
    Builder(
      builder: (context) => sheet
          ? _SheetFrame(child: Builder(builder: builder))
          : drawer
          ? _DrawerFrame(child: Builder(builder: builder))
          : builder(context),
    ),
  );
  // Motion is drawn, never faded (law 6): every frame of a raised layer is printed at full ink. A drawer or a
  // sheet travels in from its edge and stops there, its overshoot held at the edge so it never comes loose from
  // it; a dialog pops in, its overshoot a short bounce in place.
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final travel = CurveTween(curve: _HeldAtEdge(carried.motion.enter));
    if (drawer || sheet) {
      return SlideTransition(
        position: Tween(
          begin: drawer
              ? Offset(
                  Directionality.of(context) == TextDirection.rtl ? 1 : -1,
                  0,
                )
              : const Offset(0, 1),
          end: Offset.zero,
        ).chain(travel).animate(animation),
        child: child,
      );
    }
    return ScaleTransition(
      scale: Tween(
        begin: .92,
        end: 1.0,
      ).chain(CurveTween(curve: carried.motion.enter)).animate(animation),
      child: child,
    );
  }
}

/// [curve] with its overshoot held at the end: a layer that travels to an edge stops on it.
class _HeldAtEdge extends Curve {
  const _HeldAtEdge(this.curve);
  final Curve curve;
  @override
  double transformInternal(double t) => math.min(curve.transform(t), 1);
}

Future<T?> _raise<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool sheet = false,
  bool drawer = false,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  bool dimBackground = true,
  String? closeLabel,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final carried = _Carried(context, navigator);
  return navigator.push<T>(
    _ComicRoute<T>(
      carried: carried,
      builder: builder,
      dismissible: barrierDismissible,
      sheet: sheet,
      closeLabel:
          closeLabel ?? DesignLocalizations.of(context).closeButtonLabel,
      dimBackground: dimBackground,
      drawer: drawer,
    ),
  );
}

class _DrawerFrame extends StatelessWidget {
  const _DrawerFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: math.min(320, width * .86),
        height: double.infinity,
        child: SafeArea(right: false, left: false, child: child),
      ),
    );
  }
}

/// Raises a navigation drawer from the start edge, the window's full height, over a scrim: the phone's form of the
/// side navigation. Escape, back and a press on the scrim close it, and focus returns to what opened it. Pop it with a
/// value (the destination chosen) from inside, as a [ComicNavigationDrawer]'s `onDestinationSelected` does.
///
/// ```dart
/// showComicNavigationDrawer<int>(context, builder: (context) => ComicNavigationDrawer(destinations: items, selectedIndex: at, onDestinationSelected: (i) => Navigator.of(context).pop(i)))
/// ```
Future<T?> showComicNavigationDrawer<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  String? closeLabel,
}) => _raise<T>(
  context,
  builder,
  drawer: true,
  useRootNavigator: useRootNavigator,
  closeLabel: closeLabel,
);

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: math.max(
                48,
                media.size.height -
                    media.viewInsets.bottom -
                    media.padding.top -
                    24,
              ),
            ),
            child: MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Raises a dialog, restoring focus when it closes. Escape and back close it;
/// [barrierDismissible] controls only presses on the scrim.
///
/// ```dart
/// showComicDialog(context, builder: (_) => ComicDialog(title: 'Keep this issue?'))
/// ```
Future<T?> showComicDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  String? closeLabel,
}) => _raise<T>(
  context,
  builder,
  barrierDismissible: barrierDismissible,
  useRootNavigator: useRootNavigator,
  closeLabel: closeLabel,
);

/// A square inked panel with a lettered title and wrapping action row.
///
/// ```dart
/// ComicDialog(title: 'Remove issue?', message: 'This cannot be undone.', actions: [ComicButton.filled('Remove', onPressed: remove)])
/// ```
class ComicDialog extends StatelessWidget {
  /// Creates a dialog face, raised with [showComicDialog].
  const ComicDialog({
    super.key,
    this.style,
    required this.title,
    this.message,
    this.content = const [],
    this.actions = const [],
    this.tone,
    this.icon,
  });

  /// Its heading and route name.
  final String title;

  /// An optional semantic status mark above the message.
  final ComicTone? tone;

  /// An optional caller-supplied graphic.
  final Widget? icon;

  /// A short explanation below the heading.
  final String? message;

  /// Fields or other content; the panel scrolls when necessary.
  final List<Widget> content;

  /// Actions from least to most prominent, in a row at the dialog's trailing end, the confirming one last (give it
  /// the act button); stacked where the row has no room, the last first.
  final List<Widget> actions;

  /// Appearance above this surface's component theme.
  final ComicStyle? style;
  @override
  Widget build(BuildContext context) => _ModalPanel(
    style: style,
    title: title,
    children: [
      if (icon != null || tone != null)
        ExcludeSemantics(child: icon ?? ComicToneMark(tone!)),
      if (message != null)
        Text(message!, style: ComicTheme.of(context).type.body),
      ...content,
      if (actions.isNotEmpty)
        // The actions stand at the trailing end in reading order, the confirming one last (11-12), as every system a
        // product team knows sets a dialog's.
        OverflowBar(
          spacing: 8,
          overflowSpacing: 8,
          alignment: MainAxisAlignment.end,
          overflowAlignment: OverflowBarAlignment.end,
          overflowDirection: VerticalDirection.up,
          children: actions,
        ),
    ],
  );
}

class _ModalPanel extends StatelessWidget {
  const _ModalPanel({this.title, required this.children, this.style});
  final ComicStyle? style;
  final String? title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context), t = ComicTheme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, media.viewInsets.bottom + 16),
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: math.max(
                0,
                media.size.height -
                    media.viewInsets.bottom -
                    media.padding.vertical -
                    32,
              ),
            ),
            child: Semantics(
              scopesRoute: true,
              explicitChildNodes: true,
              child: SingleChildScrollView(
                child: _RaisedFrame(
                  style: style,
                  theme: t.dialogTheme,
                  shape: t.shapes.large,
                  child: ComicColumn(
                    gap: 16,
                    skipEmpty: true,
                    children: [
                      if (title != null)
                        Semantics(
                          namesRoute: true,
                          header: true,
                          child: CapLabel(
                            child: Text(title!, style: t.type.panel),
                          ),
                        ),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Raises a sheet from the page's foot, carrying its theme and direction.
///
/// ```dart
/// showComicBottomSheet(context, builder: (_) => ComicBottomSheet(title: 'Details', child: Text('Issue 12')))
/// ```
Future<T?> showComicBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  String? closeLabel,
}) => _raise<T>(
  context,
  builder,
  sheet: true,
  barrierDismissible: barrierDismissible,
  useRootNavigator: useRootNavigator,
  closeLabel: closeLabel,
);

/// A scrollable inked sheet, with a close control and optional actions.
///
/// ```dart
/// ComicBottomSheet(title: 'Details', child: Text('Issue 12'))
/// ```
class ComicBottomSheet extends StatelessWidget {
  /// Creates a sheet face.
  const ComicBottomSheet({
    super.key,
    this.style,
    this.title,
    this.child,
    this.slivers,
    this.controller,
    this.actions = const [],
    this.onClose,
    this.closeLabel,
    this.showClose = true,
  }) : assert((child == null) != (slivers == null));

  /// The heading, when present.
  final String? title;

  /// The sheet's content.
  final Widget? child;

  /// A scrollable sliver body and its optional controller.
  final List<Widget>? slivers;

  /// The caller-owned editing controller.
  final ScrollController? controller;

  /// Actions below its content.
  final List<Widget> actions;

  /// Overrides closing the current route.
  final VoidCallback? onClose;

  /// Overrides the localized close label.
  final String? closeLabel;

  /// Whether to offer a close button when the route supplies its callback.
  final bool showClose;

  /// Appearance above this surface's component theme.
  final ComicStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context),
        safe = MediaQuery.paddingOf(context).bottom;
    final look = ComicStyleOf([style, t.sheetTheme], const {}),
        rim = comicRim(
          t,
          ComicStyleOf([style, t.sheetTheme], const {}),
          t.colors.nightLine,
          3,
        );
    final body = slivers != null
        ? CustomScrollView(
            controller: controller,
            shrinkWrap: true,
            slivers: slivers!,
          )
        : SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            child: child,
          );
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: AnimatedComicShape(
        shape: look.shape ?? t.shapes.large,
        builder: (context, shape) => DecoratedBox(
          decoration: ShapeDecoration(
            color: look.fill ?? t.colors.card,
            shape: (shape ?? const RoundedRectangleBorder()).copyWith(
              side: rim,
            ),
          ),
          child: Padding(
            padding: (shape?.dimensions ?? EdgeInsets.zero).add(
              shape == null ? EdgeInsets.zero : EdgeInsets.all(rim.width + 6),
            ),
            child: LayoutBuilder(
              builder: (context, box) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  if (title != null || onClose != null || showClose)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        0,
                        8,
                        8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: title == null
                                ? const SizedBox.shrink()
                                : Semantics(
                                    header: true,
                                    namesRoute: true,
                                    child: CapLabel(
                                      child: Text(title!, style: t.type.panel),
                                    ),
                                  ),
                          ),
                          if (onClose != null || showClose)
                            ComicIconButton(
                              ComicGlyphs.close,
                              label:
                                  closeLabel ??
                                  DesignLocalizations.of(context)
                                      .closeButtonLabel,
                              onPressed:
                                  onClose ??
                                  () => Navigator.of(context).maybePop(),
                            ),
                        ],
                      ),
                    ),
                  if (box.hasBoundedHeight)
                    Flexible(
                      fit: box.hasTightHeight ? FlexFit.tight : FlexFit.loose,
                      child: body,
                    )
                  else
                    body,
                  if (actions.isNotEmpty)
                    ComicRuled(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 14 + safe),
                        // On a phone the actions stack, each across the sheet; from 600 wide they keep to their
                        // words in one line, as a dialog's (the design kit's checks: a sheet's spanning acts are a fault).
                        child: t.width >= 600
                            ? OverflowBar(
                                spacing: 8,
                                overflowSpacing: 8,
                                overflowDirection: VerticalDirection.up,
                                children: actions,
                              )
                            : ComicColumn(
                                gap: 8,
                                skipEmpty: true,
                                children: actions,
                              ),
                      ),
                    )
                  else
                    SizedBox(height: safe),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One option in an inked menu. Disabled options remain readable.
@immutable
class ComicMenuItem<T> {
  /// Creates an option with the value returned when selected.
  const ComicMenuItem(
    this.value,
    this.label, {
    this.icon,
    this.enabled = true,
    this.selected = false,
  });

  /// The value returned to the caller.
  final T value;

  /// Its visible and spoken name.
  final String label;

  /// An optional leading glyph.
  final IconData? icon;

  /// Whether it can be selected.
  final bool enabled;

  /// Whether it is the current option.
  final bool selected;
}

/// An inked menu. Its active item, the one Enter takes, wears the look's selection fill and follows both the pointer
/// and the Arrow, Home and End keys, as a desktop menu's does; the focused choice stays visible inside a scrolling
/// menu. The current option ([ComicMenuItem.selected]) carries a check, and the menu opens with it active.
///
/// ```dart
/// ComicMenu<String>(items: const [ComicMenuItem('save', 'Save')], onSelected: save)
/// ```
class ComicMenu<T> extends StatefulWidget {
  /// Creates a menu face. [showComicMenu] owns placement and dismissal.
  const ComicMenu({
    super.key,
    this.style,
    required this.items,
    this.onSelected,
    this.autofocus = false,
    this.wordsAt,
  }) : _raised = false;

  /// The menu [showComicMenu] raises: standing on its plate over the page, scrolling inside its rim.
  const ComicMenu._raised({
    super.key,
    this.style,
    required this.items,
    this.onSelected,
    this.autofocus = false,
    this.wordsAt,
  }) : _raised = true;

  final bool _raised;

  /// Options in reading order.
  final List<ComicMenuItem<T>> items;

  /// Where each row's words start, from the menu's outer edge. A menu opened from a field puts them on the field's
  /// words ([showComicMenu] does, with `matchAnchorWidth`); null keeps the menu's own inset.
  final double? wordsAt;

  /// Called for an enabled option; absent means the whole menu is disabled.
  final ValueChanged<T>? onSelected;

  /// Requests initial focus when raised; inline menus normally use Tab.
  final bool autofocus;

  /// Appearance above this surface's component theme.
  final ComicStyle? style;
  @override
  State<ComicMenu<T>> createState() => _ComicMenuState<T>();
}

class _ComicMenuState<T> extends State<ComicMenu<T>> {
  final _nodes = <FocusNode>[];

  /// The item the pointer or the keys last reached: Enter takes it, and it wears the selection fill.
  int? _active;
  void _sync() {
    while (_nodes.length < widget.items.length) {
      final i = _nodes.length;
      _nodes.add(
        FocusNode()..addListener(() {
          if (_nodes.length > i && _nodes[i].hasFocus && _active != i) {
            setState(() => _active = i);
          }
        }),
      );
    }
    while (_nodes.length > widget.items.length) {
      _nodes.removeLast().dispose();
    }
    if (_active != null && _active! >= _nodes.length) _active = null;
  }

  /// The pointer reaches item [i]: it becomes the active one, and the keys go on from it.
  void _reach(int i) {
    if (!widget.items[i].enabled || widget.onSelected == null) return;
    if (_active != i) setState(() => _active = i);
    if (!_nodes[i].hasFocus) _nodes[i].requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ComicMenu<T> old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _key(int index, KeyEvent event) {
    if (event is! KeyDownEvent || widget.onSelected == null) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final backwards = key == LogicalKeyboardKey.arrowUp;
    if (!backwards &&
        key != LogicalKeyboardKey.arrowDown &&
        key != LogicalKeyboardKey.home &&
        key != LogicalKeyboardKey.end) {
      return KeyEventResult.ignored;
    }
    final enabled = [
      for (var i = 0; i < widget.items.length; i++)
        if (widget.items[i].enabled) i,
    ];
    if (enabled.isNotEmpty) {
      final current = enabled.indexOf(index);
      final next = key == LogicalKeyboardKey.home
          ? enabled.first
          : key == LogicalKeyboardKey.end
          ? enabled.last
          : enabled[(current + (backwards ? -1 : 1)) % enabled.length];
      final node = _nodes[next];
      node.requestFocus();
      final binding = WidgetsBinding.instance;
      binding.addPostFrameCallback((_) {
        if (!mounted || !node.hasFocus) return;
        final target = node.context;
        if (target == null) return;
        unawaited(
          Scrollable.ensureVisible(
            target,
            alignmentPolicy: backwards || key == LogicalKeyboardKey.home
                ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
                : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          ),
        );
      });
      binding.ensureVisualUpdate();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final current = widget.items.indexWhere(
      (item) => item.enabled && item.selected,
    );
    final first = current >= 0
        ? current
        : widget.items.indexWhere((item) => item.enabled);
    final look = ComicStyleOf([widget.style, t.menuTheme], const {});
    final frame = look.shape ?? t.shapes.medium;
    // A row sits 4 px inside the rim, so its corner is the menu's minus that inset: concentric, never a square
    // block inside a rounded menu. Its wash and ring take the same outline.
    final inset = comicRim(t, look, t.colors.nightLine, 3).width + 4;
    final row = comicInsetShape(frame, inset);
    // The words' start inside a row: the menu's own 12, or the field's words when it opened from one.
    final start = widget.wordsAt == null
        ? 12.0
        : math.max(6.0, widget.wordsAt! - inset);
    // A raised menu stands on its plate over the page, and a long one scrolls inside its rim (11-11).
    return _RaisedFrame(
      style: widget.style,
      theme: t.menuTheme,
      shape: t.shapes.medium,
      padding: const EdgeInsets.all(4),
      plate: widget._raised,
      scrolls: widget._raised,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.items.length; i++)
            MouseRegion(
              onEnter: (_) => _reach(i),
              onHover: (_) => _reach(i),
              child: ComicPressable(
                focusNode: _nodes[i],
                autofocus:
                    widget.autofocus && i == first && widget.onSelected != null,
                label: widget.items[i].label,
                selected: widget.items[i].selected,
                onPressed: !widget.items[i].enabled || widget.onSelected == null
                    ? null
                    : () => widget.onSelected!(widget.items[i].value),
                keys: (_, event) => _key(i, event),
                outline: WidgetStatePropertyAll(row),
                builder: (context, states) {
                  final lit = _active == i && states.enabled;
                  final ink = lit
                      ? t.colors.onCaption
                      : states.enabled
                      ? t.colors.text
                      : t.colors.textSecondary;
                  // A row is at least the touch target tall, so the target never centres a shorter row off the
                  // menu's inset (the row's corner stays concentric with the rim).
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: ComicTapTarget.targetOf(context),
                    ),
                    child: ComicStateDecoration(
                      decoration: ShapeDecoration(
                        shape: row,
                        color: lit ? t.colors.caption : t.colors.card,
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          start,
                          12,
                          12,
                          12,
                        ),
                        child: IconTheme.merge(
                          data: IconThemeData(color: ink),
                          child: Row(
                            children: [
                              if (widget.items[i].icon != null) ...[
                                Icon(widget.items[i].icon, size: 20),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: CapLabel(
                                  child: Text(
                                    widget.items[i].label,
                                    style: t.type.body.copyWith(color: ink),
                                  ),
                                ),
                              ),
                              // The current option's mark, so the active one and the chosen one never read alike.
                              if (widget.items[i].selected) ...[
                                const SizedBox(width: 10),
                                ExcludeSemantics(
                                  child: Icon(ComicGlyphs.check, size: 20),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AnchorLayout extends SingleChildLayoutDelegate {
  const _AnchorLayout(
    this.anchor,
    this.direction, {
    this.tooltip = false,
    this.matchAnchorWidth = false,
  });
  final Rect anchor;
  final TextDirection direction;
  final bool tooltip;
  final bool matchAnchorWidth;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final available = math.max(0.0, constraints.maxWidth - 16);
    final width = anchor.width.clamp(0.0, available);
    return BoxConstraints(
      minWidth: matchAnchorWidth ? width : 0,
      maxWidth: matchAnchorWidth ? width : math.min(320, available),
      maxHeight: math.max(0, constraints.maxHeight - 16),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = tooltip
        ? anchor.center.dx - childSize.width / 2
        : direction == TextDirection.rtl
        ? anchor.right - childSize.width
        : anchor.left;
    var y = anchor.bottom + 6;
    if (y + childSize.height > size.height - 8) {
      y = anchor.top - childSize.height - 6;
    }
    return Offset(
      x.clamp(8, math.max(8, size.width - childSize.width - 8)),
      y.clamp(8, math.max(8, size.height - childSize.height - 8)),
    );
  }

  @override
  bool shouldRelayout(_AnchorLayout old) =>
      anchor != old.anchor ||
      direction != old.direction ||
      tooltip != old.tooltip ||
      matchAnchorWidth != old.matchAnchorWidth;
}

/// Opens a menu beside a rectangle in global coordinates and returns its value.
/// [matchAnchorWidth] gives a select menu the field's width, within the viewport.
/// The dismissal barrier is transparent; dialogs and sheets retain their scrims.
///
/// ```dart
/// final value = await showComicMenu(context, anchor: rect, items: const [ComicMenuItem('save', 'Save')]);
/// ```
Future<T?> showComicMenu<T>(
  BuildContext context, {
  ComicStyle? style,
  required Rect anchor,
  required List<ComicMenuItem<T>> items,
  bool matchAnchorWidth = false,
  bool useRootNavigator = true,
  String? closeLabel,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final box = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final local = anchor.shift(-box.localToGlobal(Offset.zero));
  return _raise<T>(
    context,
    (context) => CustomSingleChildLayout(
      delegate: _AnchorLayout(
        local,
        Directionality.of(context),
        matchAnchorWidth: matchAnchorWidth,
      ),
      // The menu scrolls inside its own rim when the window is short (11-11): its frame stays whole.
      child: ComicMenu<T>._raised(
        style: style,
        autofocus: true,
        items: items,
        // A select's list sets its words on the field's (a list that opens from a field).
        wordsAt: matchAnchorWidth
            ? comicFieldInset(ComicTheme.of(context)).start
            : null,
        onSelected: (value) => Navigator.of(context).pop(value),
      ),
    ),
    useRootNavigator: useRootNavigator,
    closeLabel: closeLabel,
    dimBackground: false,
  );
}

/// Wires a menu's anchor without exposing a render box to the app. A list that opens from a field
/// ([matchAnchorWidth]) marks the field's current value ([ComicMenuItem.selected]), as a [ComicSelect]'s list does:
/// it opens on that row, which carries the check.
///
/// ```dart
/// ComicMenuAnchor<String>(items: const [ComicMenuItem('save', 'Save')], builder: (context, open) => ComicButton.filled('More', onPressed: open))
/// ```
class ComicMenuAnchor<T> extends StatelessWidget {
  /// Creates an anchored menu.
  const ComicMenuAnchor({
    super.key,
    this.style,
    required this.items,
    required this.builder,
    this.onSelected,
    this.matchAnchorWidth = false,
  });

  /// Its menu options.
  final List<ComicMenuItem<T>> items;

  /// Surface appearance above the menu theme.
  final ComicStyle? style;

  /// Builds the anchor using the supplied open callback.
  final Widget Function(BuildContext context, VoidCallback open) builder;

  /// Receives the selected value; dismissing sends nothing.
  final ValueChanged<T>? onSelected;

  /// Matches the menu to the anchor width, as a select field requires.
  final bool matchAnchorWidth;
  @override
  Widget build(BuildContext context) => Builder(
    builder: (anchorContext) => builder(anchorContext, () async {
      final room = anchorContext.findRenderObject();
      if (room is! RenderBox || !room.hasSize) return;
      // A dropdown's face may stand narrower than the room it is given (comicDropdownWidth): open from the face.
      final box = comicAnchorFaceOf(room);
      final result = await showComicMenu<T>(
        anchorContext,
        anchor: box.localToGlobal(Offset.zero) & box.size,
        items: items,
        style: style,
        matchAnchorWidth: matchAnchorWidth,
      );
      if (result != null && anchorContext.mounted) onSelected?.call(result);
    }),
  );
}

/// A dismissible overlay and the future that completes when it is gone.
abstract class ComicRaised {
  /// Dismisses once, with the look's departure motion.
  void dismiss();

  /// Completes when the overlay has been removed.
  Future<void> get closed;
}

class _Overlaid implements ComicRaised {
  OverlayEntry? entry;
  Timer? timer;
  VoidCallback? leave;
  final _closed = Completer<void>();
  bool going = false;
  @override
  Future<void> get closed => _closed.future;
  @override
  void dismiss() {
    if (going) return;
    going = true;
    timer?.cancel();
    if (leave != null) {
      leave!();
    } else {
      remove();
    }
  }

  void remove() {
    timer?.cancel();
    final old = entry;
    entry = null;
    old?.remove();
    old?.dispose();
    finish();
  }

  void finish() {
    going = true;
    timer?.cancel();
    leave = null;
    if (!_closed.isCompleted) _closed.complete();
  }
}

class _OverlayMotion extends StatefulWidget {
  const _OverlayMotion({
    required this.handle,
    required this.motion,
    required this.child,
  });
  final _Overlaid handle;
  final ComicMotion motion;
  final Widget child;
  @override
  State<_OverlayMotion> createState() => _OverlayMotionState();
}

class _OverlayMotionState extends State<_OverlayMotion>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.motion.raise,
    reverseDuration: widget.motion.leave,
  );
  @override
  void initState() {
    super.initState();
    widget.handle.leave = () => _controller.reverse().whenCompleteOrCancel(() {
      if (mounted) widget.handle.remove();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    widget.handle.finish();
    _controller.dispose();
    super.dispose();
  }

  @override
  // A short pop from .92, opaque from its first frame, and cut away at the end: nothing fades (law 6).
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween<double>(begin: .92, end: 1).animate(_controller),
    child: widget.child,
  );
}

/// The balloon drawn by a tooltip, also useful in a static specimen.
///
/// ```dart
/// ComicTooltipFace(message: 'Save this issue')
/// ```
class ComicTooltipFace extends StatelessWidget {
  /// Creates a tooltip face.
  const ComicTooltipFace({super.key, required this.message, this.style});

  /// Its short explanation.
  final String message;

  /// Appearance above this surface's component theme.
  final ComicStyle? style;
  @override
  Widget build(BuildContext context) => ComicBalloon(
    message,
    small: true,
    style: ComicStyle.layered([
      style,
      ComicTheme.of(context).tooltipTheme,
      ComicStyle(
        shape: WidgetStatePropertyAll(ComicTheme.of(context).shapes.medium),
      ),
    ]),
  );
}

/// Shows a tooltip without taking keyboard focus. Escape dismisses it.
///
/// ```dart
/// showComicTooltip(context, message: 'Save this issue', anchor: rect)
/// ```
ComicRaised showComicTooltip(
  BuildContext context, {
  ComicStyle? style,
  required String message,
  required Rect anchor,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final overlay = navigator.overlay!;
  final box = overlay.context.findRenderObject()! as RenderBox;
  final local = anchor.shift(-box.localToGlobal(Offset.zero));
  final carried = _Carried(context, navigator);
  final handle = _Overlaid();
  bool escape(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      handle.dismiss();
      return true;
    }
    return false;
  }

  HardwareKeyboard.instance.addHandler(escape);
  handle.closed.whenComplete(
    () => HardwareKeyboard.instance.removeHandler(escape),
  );
  handle.entry = OverlayEntry(
    builder: (context) => carried.wrap(
      context,
      IgnorePointer(
        child: ExcludeSemantics(
          child: _OverlayMotion(
            handle: handle,
            motion: carried.motion,
            child: CustomSingleChildLayout(
              delegate: _AnchorLayout(local, carried.direction, tooltip: true),
              child: ComicTooltipFace(style: style, message: message),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(handle.entry!);
  return handle;
}

/// Explains its child on hover, keyboard focus or long press.
///
/// ```dart
/// ComicTooltip(message: 'Save this issue', child: ComicIconButton(icon, label: 'Save', onPressed: save))
/// ```
class ComicTooltip extends StatefulWidget {
  /// Creates a tooltip. Its child keeps its own semantics and activation.
  const ComicTooltip({
    super.key,
    this.style,
    required this.message,
    required this.child,
    this.waitDuration = const Duration(milliseconds: 400),
  });

  /// The explanation, also exposed to assistive technology.
  final String message;

  /// The control being explained.
  final Widget child;

  /// How long the pointer rests before the tooltip appears.
  final Duration waitDuration;

  /// Appearance of the explanation balloon.
  final ComicStyle? style;
  @override
  State<ComicTooltip> createState() => _ComicTooltipState();
}

class _ComicTooltipState extends State<ComicTooltip> {
  ComicRaised? _up;
  Timer? _timer;
  void _show() {
    _timer?.cancel();
    if (!mounted || _up != null) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final up = showComicTooltip(
      context,
      message: widget.message,
      style: widget.style,
      anchor: box.localToGlobal(Offset.zero) & box.size,
    );
    _up = up;
    up.closed.whenComplete(() {
      if (identical(up, _up)) _up = null;
    });
  }

  void _hide() {
    _timer?.cancel();
    _up?.dismiss();
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ComicTooltip old) {
    super.didUpdateWidget(old);
    if (old.message != widget.message) _hide();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    tooltip: widget.message,
    child: MouseRegion(
      onEnter: (_) {
        _timer?.cancel();
        _timer = Timer(widget.waitDuration, _show);
      },
      onExit: (_) => _hide(),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onFocusChange: (focused) {
          if (focused &&
              FocusManager.instance.highlightMode ==
                  FocusHighlightMode.traditional) {
            _show();
          } else if (!focused) {
            _hide();
          }
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          onLongPress: _show,
          onLongPressEnd: (_) => _hide(),
          child: widget.child,
        ),
      ),
    ),
  );
}

/// A short announcement printed as a narration panel, with an optional action.
///
/// ```dart
/// ComicSnackBar('Saved to your collection', actionLabel: 'Undo', onAction: undo)
/// ```
class ComicSnackBar extends StatelessWidget {
  /// Creates an announcement face. [showComicSnackBar] owns its lifetime.
  const ComicSnackBar._toasted(
    this.message, {
    this.style,
    this.title,
    this.tone,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.dismissLabel,
  }) : _live = false;

  /// Creates an announcement face. [showComicSnackBar] gives it its timing.
  const ComicSnackBar(
    this.message, {
    super.key,
    this.style,
    this.title,
    this.tone,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.dismissLabel,
  }) : _live = true;

  /// Speaks when it appears; the toaster speaks for the toasts it holds.
  final bool _live;

  /// What happened.
  final String message;

  /// Optional status, shown with a distinct mark as well as color.
  final ComicTone? tone;

  /// An optional heading.
  final String? title;

  /// The action's label; only shown with [onAction].
  final String? actionLabel;

  /// Handles the optional action.
  final VoidCallback? onAction;

  /// Dismisses the overlay when wired by its show helper.
  final VoidCallback? onDismiss;

  /// Overrides the localized dismiss label.
  final String? dismissLabel;

  /// Appearance above this surface's component theme.
  final ComicStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final words = tone == null
        ? Text(message, style: t.type.body)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: ComicToneMark(tone!)),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: t.type.body)),
            ],
          );
    final actions = <Widget>[
      if (onAction != null && actionLabel != null)
        ComicButton(actionLabel!, onPressed: onAction),
      if (onDismiss != null)
        // As tall as the action beside it: one row, one height.
        ComicIconButton(
          ComicGlyphs.x,
          // Its size takes the density again: the field's height before it.
          size: ComicTrack.fieldHeight(context) - t.density.heightDelta,
          label: dismissLabel ?? ComicLocalizations.of(context).dismiss,
          onPressed: onDismiss,
        ),
    ];
    // On a desktop an announcement with no heading is one strip: its actions stand at the end of the message's line,
    // not on a second line under it (r3, a tall bar at desktop width).
    final inline = t.desk && title == null && actions.isNotEmpty;
    return Semantics(
      liveRegion: _live,
      child: _RaisedFrame(
        style: style,
        theme: t.snackBarTheme,
        shape: t.shapes.medium,
        child: inline
            ? Row(
                children: [
                  Expanded(child: words),
                  const SizedBox(width: 16),
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    action,
                  ],
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) ...[
                    CapLabel(child: Text(title!, style: t.type.panel)),
                    const SizedBox(height: 8),
                  ],
                  words,
                  // The message's descenders stood on the action's rim: a beat of room between the words and the
                  // actions.
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.end,
                      // Centred across the run: the dismiss keeps a full finger's target around a face that density
                      // makes shorter, and on the run's top its face stood 2 px under the action's (ui_core's
                      // DesignRowCheck, comfortable and compact, 11-11).
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: actions,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Shows one announcement per navigator, replacing the previous one.
/// Actions remain available indefinitely when accessible navigation is on.
///
/// ```dart
/// showComicSnackBar(context, 'Saved', actionLabel: 'Undo', onAction: undo)
/// ```
ComicRaised showComicSnackBar(
  BuildContext context,
  String message, {
  ComicStyle? style,
  String? title,
  ComicTone? tone,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
  String? dismissLabel,
}) {
  final navigator = Navigator.of(context);
  final overlay = navigator.overlay!;
  final words = ComicLocalizations.of(context);
  final host = _toasters[overlay] ??= _ToastHost(overlay, words);
  final handle = _Toasted();
  host.raise(
    DesignToast(
      message: message,
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      data: _ToastShown(
        carried: _Carried(context, navigator),
        shell: ShellInsets.of(context),
        style: style,
        tone: tone,
        dismissLabel: dismissLabel,
      ),
    ),
    handle,
  );
  return handle;
}

final _toasters = Expando<_ToastHost>();

class _ToastShown {
  const _ToastShown({
    required this.carried,
    required this.shell,
    this.style,
    this.tone,
    this.dismissLabel,
  });
  final _Carried carried;
  final double shell;
  final ComicStyle? style;
  final ComicTone? tone;
  final String? dismissLabel;
}

/// The design kit's toaster on a navigator's overlay: empty, it takes no room and no press.
class _ToastHost {
  _ToastHost(OverlayState overlay, ComicLocalizations words) {
    overlay.insert(
      OverlayEntry(
        builder: (context) => DesignToaster(
          key: key,
          regionLabel: words.notifications,
          toastBuilder: _toastFace,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  final key = GlobalKey<DesignToasterState>();

  void raise(DesignToast toast, _Toasted handle) {
    final now = key.currentState;
    if (now != null) {
      handle.attach(now.show(toast));
      return;
    }
    // The first toast waits for the frame that builds the toaster.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = key.currentState;
      if (state == null) {
        handle.finish();
      } else {
        handle.attach(state.show(toast));
      }
    });
  }

  static Widget _toastFace(BuildContext context, DesignToastDetails view) {
    final toast = view.toast;
    final shown = toast.data! as _ToastShown;
    return shown.carried.wrap(
      context,
      Transform.translate(
        offset: Offset(
          0,
          -math.max(shown.shell, MediaQuery.viewInsetsOf(context).bottom),
        ),
        child: AnimatedBuilder(
          animation: view.animation,
          builder: (context, child) {
            final here = view.animation.value.clamp(0.0, 1.0);
            // Opaque paper from its first frame, sliding its last 16 px: the page never shows through (law 6).
            return Transform.translate(
              offset: Offset(0, (1 - here) * 16),
              child: child,
            );
          },
          child: Padding(
            padding: EdgeInsets.only(top: view.index == 0 ? 0 : 8),
            child: ComicSnackBar._toasted(
              toast.message,
              style: shown.style,
              title: toast.title,
              tone: shown.tone,
              actionLabel: toast.actionLabel,
              onAction: view.runAction,
              onDismiss: view.dismiss,
              dismissLabel: shown.dismissLabel,
            ),
          ),
        ),
      ),
    );
  }
}

class _Toasted implements ComicRaised {
  DesignToastHandle? _handle;
  bool _dismissed = false;
  final _closed = Completer<void>();

  void attach(DesignToastHandle handle) {
    _handle = handle;
    handle.closed.whenComplete(finish);
    if (_dismissed) handle.dismiss();
  }

  void finish() {
    if (!_closed.isCompleted) _closed.complete();
  }

  @override
  Future<void> get closed => _closed.future;

  @override
  void dismiss() {
    _dismissed = true;
    _handle?.dismiss();
  }
}

/// A brief confirmation that needs nothing back: "Link copied", "Saved". Smaller than a [ComicSnackBar], it holds one
/// line and an optional status mark, never an action, and leaves by itself. [showComicToast] owns its lifetime.
///
/// ```dart
/// ComicToast('Link copied', tone: ComicTone.success)
/// ```
class ComicToast extends StatelessWidget {
  /// Creates a toast face.
  const ComicToast(this.message, {super.key, this.tone, this.icon, this.style});

  /// What happened, in a few words.
  final String message;

  /// Optional status, shown with its mark as well as colour.
  final ComicTone? tone;

  /// An optional glyph before the words, when no [tone] is given.
  final IconData? icon;

  /// Appearance above the snack bar's component theme.
  final ComicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      excludeSemantics: true,
      child: _RaisedFrame(
        style: style,
        theme: t.snackBarTheme,
        shape: t.shapes.medium,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tone != null) ...[
              ComicToneMark(tone!),
              const SizedBox(width: 10),
            ] else if (icon != null) ...[
              Icon(icon, size: 20, color: t.colors.text),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.type.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _toasts = Expando<_Overlaid>();

/// Shows [message] as a [ComicToast] above the page's foot for [duration], replacing the navigator's previous toast. It
/// takes no focus and no press: a toast that needs an answer is a [showComicSnackBar].
///
/// ```dart
/// showComicToast(context, 'Link copied', tone: ComicTone.success)
/// ```
ComicRaised showComicToast(
  BuildContext context,
  String message, {
  ComicTone? tone,
  IconData? icon,
  ComicStyle? style,
  Duration duration = const Duration(milliseconds: 2500),
}) {
  final navigator = Navigator.of(context);
  final overlay = navigator.overlay!;
  _toasts[overlay]?.dismiss();
  final carried = _Carried(context, navigator);
  final shellAllowance = ShellInsets.of(context);
  final handle = _Overlaid();
  _toasts[overlay] = handle;
  handle.closed.whenComplete(() {
    if (identical(_toasts[overlay], handle)) _toasts[overlay] = null;
  });
  handle.entry = OverlayEntry(
    builder: (context) => carried.wrap(
      context,
      _OverlayMotion(
        handle: handle,
        motion: carried.motion,
        child: IgnorePointer(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24 +
                    math.max(
                      shellAllowance,
                      MediaQuery.viewInsetsOf(context).bottom,
                    ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ComicToast(
                    message,
                    tone: tone,
                    icon: icon,
                    style: style,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(handle.entry!);
  handle.timer = Timer(duration, handle.dismiss);
  return handle;
}

/// How far a floating surface's plate stands off it (11-12): the floating action button's print, the surface's own
/// outline in its rim's ink, this far down and to the end, under it. Comic draws no shadow; the plate is its mark for
/// "raised", so a surface reads on top wherever its edge falls (on a panel's rule, a field's rim). Drawn outside the
/// surface's box: a list keeps its field's width.
const double comicRaisedPlate = 4;

class _RaisedFrame extends StatelessWidget {
  const _RaisedFrame({
    required this.child,
    required this.theme,
    this.style,
    this.shape,
    this.padding,
    this.plate = false,
    this.scrolls = false,
  });
  final Widget child;
  final ComicStyle? style;
  final ComicStyle theme;
  final OutlinedBorder? shape;
  final EdgeInsetsGeometry? padding;

  /// Floats over the page: it stands on its plate ([comicRaisedPlate]).
  final bool plate;

  /// Its content scrolls inside the rim when the room is short, so the frame itself stays whole: its bottom edge never
  /// scrolls away with the rows.
  final bool scrolls;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context),
        look = ComicStyleOf([style, theme], const {});
    final rim = comicRim(t, look, t.colors.nightLine, 3);
    final fill = look.fill ?? t.colors.card;
    final direction = Directionality.of(context);
    final inner = look.padding(direction) ?? padding ?? comicPanelInset(t);
    Widget content = child;
    if (look.foreground != null) {
      content = ComicLetteringScope(look.foreground!, child: content);
    }
    if (look.textStyle != null) {
      content = DefaultTextStyle.merge(style: look.textStyle!, child: content);
    }
    return AnimatedComicShape(
      shape: look.shape ?? shape,
      builder: (context, outline) {
        final edge = EdgeInsets.all(rim.width)
            .add(outline?.dimensions ?? EdgeInsets.zero);
        final Widget face = DecoratedBox(
          decoration: ShapeDecoration(
            color: fill,
            shape: (outline ?? const RoundedRectangleBorder()).copyWith(
              side: rim,
            ),
          ),
          child: scrolls
              ? Padding(
                  padding: edge,
                  child: SingleChildScrollView(
                    child: Padding(padding: inner, child: content),
                  ),
                )
              : Padding(padding: inner.add(edge), child: content),
        );
        if (!plate) return face;
        return CustomPaint(
          painter: _PlatePainter(
            outline ?? const RoundedRectangleBorder(),
            rim.color,
            direction,
          ),
          child: face,
        );
      },
    );
  }
}

/// Paints a surface's plate behind it: its outline, [comicRaisedPlate] down and to the end, in its rim's ink (the
/// line by day, the lit line by night, so it reads on either ground).
class _PlatePainter extends CustomPainter {
  const _PlatePainter(this.outline, this.ink, this.direction);
  final ShapeBorder outline;
  final Color ink;
  final TextDirection direction;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    outline.getOuterPath(
      (Offset.zero & size).shift(
        Offset(
          direction == TextDirection.rtl ? -comicRaisedPlate : comicRaisedPlate,
          comicRaisedPlate,
        ),
      ),
      textDirection: direction,
    ),
    Paint()..color = ink,
  );

  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_PlatePainter old) =>
      old.outline != outline || old.ink != ink || old.direction != direction;
}

/// The menu's raised face for a surface the design kit places (a split button's menu, a menubar's, a popover, a
/// palette): the menu theme's fill and rim in the medium corner, [padding] inside. Kept out of the barrel: the parts
/// that need it stand on it.
class ComicRaisedFrame extends StatelessWidget {
  /// Creates a [ComicRaisedFrame].
  const ComicRaisedFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(4),
    this.shape,
    this.style,
    this.plate = true,
  });

  /// Appearance above the menu's component theme.
  final ComicStyle? style;

  /// What the surface holds.
  final Widget child;

  /// The room inside the rim.
  final EdgeInsetsGeometry padding;

  /// The outline; the medium corner when null.
  final OutlinedBorder? shape;

  /// Floats over the page, standing on its plate ([comicRaisedPlate]); false for one standing in the page.
  final bool plate;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return _RaisedFrame(
      style: style,
      theme: t.menuTheme,
      shape: shape ?? t.shapes.medium,
      padding: padding,
      plate: plate,
      child: child,
    );
  }
}

/// Where a row's words start inside a list that opens from a field : on the field's words, less
/// the frame's rim and the 4 its rows stand in. Never under 6.
double comicFieldListWords(ComicThemeData t, [ComicStyle? style]) {
  final look = ComicStyleOf([style, t.menuTheme], const {});
  final inset = comicRim(t, look, t.colors.nightLine, 3).width + 4;
  return math.max(6.0, comicFieldInset(t).start - inset);
}

/// The outline of a row inside a [ComicRaisedFrame]: the frame's own, inset by its rim and 4, so a lit row stays
/// concentric with the rim.
OutlinedBorder comicMenuRowShape(ComicThemeData t) {
  final look = ComicStyleOf([t.menuTheme], const {});
  return comicInsetShape(
    look.shape ?? t.shapes.medium,
    comicRim(t, look, t.colors.nightLine, 3).width + 4,
  );
}

/// One row of a raised menu whose list the design kit drives: lit with the selection fill while the keyboard or the
/// pointer is on it (a menu's active row, the one Enter takes), a check when [checked], the quiet ink when disabled.
/// At least the touch target tall. Kept out of the barrel.
class ComicMenuRowFace extends StatelessWidget {
  /// Creates a [ComicMenuRowFace].
  const ComicMenuRowFace({
    super.key,
    required this.states,
    required this.label,
    this.icon,
    this.trailing,
    this.checked = false,
    this.lead,
    this.start,
    this.danger = false,
    this.shape,
  });

  /// Where the words start inside the row: 12 when null. A list that opens from a field sets them on the field's
  /// words ([comicFieldListWords]).
  final double? start;

  /// A destructive row: its words in the danger tone until lit.
  final bool danger;

  /// The lit fill's outline: [comicMenuRowShape] (concentric with a menu's rim) when null. A row standing free on a
  /// sheet, beside buttons, takes their control step instead.
  final OutlinedBorder? shape;

  /// The row's states from the design kit: focused (the keyboard), hovered, pressed, disabled.
  final Set<WidgetState> states;

  /// The row's words.
  final String label;

  /// An optional leading glyph.
  final IconData? icon;

  /// Something at the row's end: a shortcut, a submenu's arrow.
  final Widget? trailing;

  /// Chosen: a check at the end.
  final bool checked;

  /// Room before the words, for a nested row.
  final double? lead;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final enabled = !states.contains(WidgetState.disabled);
    final lit =
        enabled &&
        (states.contains(WidgetState.focused) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.selected));
    final ink = lit
        ? t.colors.onCaption
        : enabled
        ? (danger ? t.colors.tones.danger : t.colors.text)
        : t.colors.textSecondary;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: ComicTapTarget.targetOf(context)),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape ?? comicMenuRowShape(t),
          color: lit
              ? (enabled && states.contains(WidgetState.pressed)
                    ? Color.alphaBlend(
                        t.colors.onCaption.withValues(alpha: .1),
                        t.colors.caption,
                      )
                    : t.colors.caption)
              : t.colors.card,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            (start ?? 12) + (lead ?? 0),
            12,
            12,
            12,
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: ink),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: CapLabel(
                    child: Text(label, style: t.type.body.copyWith(color: ink)),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  DefaultTextStyle.merge(
                    style: t.type.small.copyWith(color: ink),
                    child: trailing!,
                  ),
                ],
                if (checked) ...[
                  const SizedBox(width: 10),
                  ExcludeSemantics(child: Icon(ComicGlyphs.check, size: 20)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A field that offers matching choices as a person types: the menu's own face under the field, the field's width.
/// Its active row wears the selection fill and follows both the pointer and the Up and Down keys; Enter or a press
/// takes it and writes its words into the field. Options match on [displayStringForOption]'s words, any part, any case.
///
/// ```dart
/// ComicCombobox<String>(label: 'City', options: const ['Lisbon', 'London', 'Lyon'], onSelected: pick)
/// ```
class ComicCombobox<T extends Object> extends StatefulWidget {
  /// Creates an autocomplete field over [options].
  const ComicCombobox({
    super.key,
    this.style,
    required this.options,
    this.displayStringForOption,
    this.onSelected,
    this.label,
    this.hint,
    this.helper,
    this.initialValue,
    this.maxOptions = 6,
    this.focusNode,
    this.autofocus = false,
  });

  /// Everything the field can offer, in the order offered.
  final List<T> options;

  /// An option's words in the field and in the list; `toString` when absent.
  final String Function(T option)? displayStringForOption;

  /// Called with the option taken.
  final ValueChanged<T>? onSelected;

  /// [label]: the field's name. [hint]: its placeholder. [helper]: a line under it. [initialValue]: its starting text.
  final String? label, hint, helper, initialValue;

  /// How many matches the list shows at most.
  final int maxOptions;

  /// Appearance of the list above the menu's component theme.
  final ComicStyle? style;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  State<ComicCombobox<T>> createState() => _ComicComboboxState<T>();
}

class _ComicComboboxState<T extends Object> extends State<ComicCombobox<T>> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String _words(T option) =>
      widget.displayStringForOption?.call(option) ?? option.toString();

  Iterable<T> _search(String text) {
    final query = text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return widget.options
        .where((option) => _words(option).toLowerCase().contains(query))
        .take(widget.maxOptions);
  }

  @override
  Widget build(BuildContext context) => comicDropdownWidth(
    context,
    DesignCombobox<T>(
      controller: _text,
      focusNode: widget.focusNode,
      search: _search,
      displayStringForOption: _words,
      onSelected: widget.onSelected,
      semanticLabel: widget.label,
      fieldBuilder: (context, field) => ComicTextField(
        controller: field.controller,
        focusNode: field.focusNode,
        autofocus: widget.autofocus,
        label: widget.label,
        hint: widget.hint,
        helper: widget.helper,
        onSubmitted: (_) => field.submit(),
      ),
      // Its options' words start on the field's .
      optionBuilder: (context, option, states) => ComicMenuRowFace(
        states: states,
        label: _words(option),
        start: comicFieldListWords(ComicTheme.of(context), widget.style),
      ),
      surfaceBuilder: (context, list) =>
          ComicRaisedFrame(style: widget.style, child: list),
      emptyBuilder: (context) {
        final t = ComicTheme.of(context);
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: comicFieldListWords(t, widget.style),
              vertical: 10,
            ),
            child: Text(
              DesignLocalizations.of(context).noResultsLabel,
              style: t.type.body.copyWith(color: t.colors.textSecondary),
            ),
          ),
        );
      },
    ),
  );
}
