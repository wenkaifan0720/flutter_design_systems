/// Panels and speech raised over the page, with Comic's routes and overlays.
library;

import 'package:ui_core/ui_core.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart' show ShellInsets;

import 'glyphs.dart';

import 'balloons.dart';
import 'controls.dart';
import 'internal/menu_open.dart';
import 'print.dart' show ComicScreenGrid;
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
import 'internal/style_guard.dart';
import 'knobs.dart' show ComicSpace;

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

class _ComicRoute<T> extends PopupRoute<T> with ComicScreenedRoute<T> {
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
  // The page behind is screened, not dimmed (law 1: nothing see-through): Ben-Day dots of the night ink swell over
  // it as the layer comes in, and the barrier under them takes the presses.
  @override
  Color? get barrierColor => null;

  @override
  Color? get screenInk => dimBackground ? carried.scrim : null;
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
/// showComicDialog<void>(context, builder: (_) => ComicDialog(title: 'Keep this issue?'))
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
          spacing: ComicSpace.close,
          overflowSpacing: 8,
          alignment: MainAxisAlignment.end,
          overflowAlignment: OverflowBarAlignment.end,
          overflowDirection: VerticalDirection.up,
          children: actions,
        ),
    ],
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(EnumProperty<ComicTone>('tone', tone, defaultValue: null))
      ..add(StringProperty('message', message, defaultValue: null))
      ..add(
        DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null),
      );
  }
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
        padding: EdgeInsets.fromLTRB(
          ComicSpace.gap,
          ComicSpace.gap,
          ComicSpace.gap,
          media.viewInsets.bottom + 16,
        ),
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
                // The panel stands on its print, which the scroll view would clip: the print's room is inside it.
                padding: const EdgeInsetsDirectional.only(
                  end: comicRaisedPlate,
                  bottom: comicRaisedPlate,
                ),
                child: _RaisedFrame(
                  style: style,
                  theme: t.dialogTheme,
                  shape: t.shapes.large,
                  plate: true,
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
/// showComicBottomSheet<void>(context, builder: (_) => ComicBottomSheet(title: 'Details', child: Text('Issue 12')))
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
    final look = comicStyleOf([style, t.sheetTheme], const {}),
        rim = comicRim(
          t,
          comicStyleOf([style, t.sheetTheme], const {}),
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
            padding: const EdgeInsets.all(ComicSpace.gap),
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
                  const SizedBox(height: ComicSpace.close),
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
                        padding: EdgeInsets.fromLTRB(
                          ComicSpace.gap,
                          ComicSpace.near,
                          ComicSpace.gap,
                          14 + safe,
                        ),
                        // On a phone the actions stack, each across the sheet; from 600 wide they keep to their
                        // words in one line, as a dialog's (the design kit's checks: a sheet's spanning acts are a fault).
                        child: t.width >= 600
                            ? OverflowBar(
                                spacing: ComicSpace.close,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(IterableProperty<Widget>('slivers', slivers, defaultValue: null))
      ..add(
        DiagnosticsProperty<ScrollController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onClose', onClose))
      ..add(StringProperty('closeLabel', closeLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'showClose',
          value: showClose,
          ifFalse: 'showClose: false',
          defaultValue: true,
        ),
      )
      ..add(
        DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null),
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

/// An inked menu. The current option ([ComicMenuItem.selected]) is printed chosen, as every chosen thing in Comic is:
/// the caption's flat yellow, its words in the caption's ink, and a check. Opened from the keys, [showComicMenu]'s menu
/// opens with it (else the first item) active; opened by the pointer, with no item active until the pointer reaches
/// one or a key lights it. The active item, the one Enter takes, wears the pointer's light Ben-Day shade (swollen
/// under the press) and follows both the pointer and the keys, one item at a time, as a desktop menu's does: the arrows (wrapping at the ends), Home and End, and a typed letter
/// (the next item it starts; letters typed in a run spell the start). Dots, never the chosen fill nor a line, so it
/// can't read as a second choice or a divider. The focused choice stays visible inside a scrolling menu.
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
  }) : _raised = false,
       _quiet = false;

  /// The menu [showComicMenu] raises: standing on its plate over the page, scrolling inside its rim.
  const ComicMenu._raised({
    super.key,
    this.style,
    required this.items,
    this.onSelected,
    this.autofocus = false,
    this.wordsAt,
    this._quiet = false,
  }) : _raised = true;

  final bool _raised;

  // Opened by the pointer: no item is active until the pointer reaches one or a key is pressed.
  final bool _quiet;

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<ComicMenuItem<T>>('items', items))
      ..add(DoubleProperty('wordsAt', wordsAt, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      )
      ..add(
        DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null),
      );
  }
}

class _ComicMenuState<T> extends State<ComicMenu<T>> {
  final _nodes = <FocusNode>[];

  /// The item the pointer or the keys last reached: Enter takes it, and it wears the pointer's shade.
  int? _active;

  /// A menu the pointer opened lights no item (its focus waits on the first, unshown) until the pointer reaches one
  /// or a key is pressed, so a row never reads as current before anything chose it.
  late bool _quiet = widget._quiet;
  void _sync() {
    while (_nodes.length < widget.items.length) {
      final i = _nodes.length;
      _nodes.add(
        FocusNode()..addListener(() {
          if (_nodes.length > i &&
              _nodes[i].hasFocus &&
              _active != i &&
              !_quiet) {
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
    _quiet = false;
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
    _run?.cancel();
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// The letters typed in a run; a pause of [_typeAhead] ends it.
  String _typed = '';
  Timer? _run;
  static const _typeAhead = Duration(milliseconds: 700);

  KeyEventResult _key(int index, KeyEvent event) {
    if (event is! KeyDownEvent || widget.onSelected == null) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final enabled = [
      for (var i = 0; i < widget.items.length; i++)
        if (widget.items[i].enabled) i,
    ];
    if (enabled.isEmpty) return KeyEventResult.ignored;
    // A quiet menu's first key lights the item the keys stand on (the chosen one, or the first), or the last going
    // up, and takes nothing: Enter and Space light it too, so nothing unseen is ever taken.
    final wasQuiet = _quiet;
    if (_quiet) {
      final up =
          key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.end;
      if (up ||
          key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.home ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.space) {
        _quiet = false;
        _go(
          up
              ? enabled.last
              : enabled.contains(index)
              ? index
              : enabled.first,
          backwards: !up,
        );
        return KeyEventResult.handled;
      }
    }
    // A typed letter jumps to the next item its words start with; letters typed in a run spell the start.
    final typed = _letter(event);
    if (typed != null) {
      _quiet = false;
      _typed += typed;
      _run?.cancel();
      _run = Timer(_typeAhead, () => _typed = '');
      final from = enabled.indexOf(index);
      // One letter looks past the active item, so the same letter steps through the items it starts; a longer run
      // keeps the active item while it still fits. In a quiet menu nothing is active yet: the search starts on the
      // item the keys stand on.
      final skip = _typed.length == 1 && !wasQuiet ? 1 : 0;
      for (var n = 0; n < enabled.length; n++) {
        final i = enabled[(from + skip + n) % enabled.length];
        if (widget.items[i].label.toLowerCase().startsWith(_typed)) {
          _go(i, backwards: false);
          break;
        }
      }
      return KeyEventResult.handled;
    }
    final backwards = key == LogicalKeyboardKey.arrowUp;
    if (!backwards &&
        key != LogicalKeyboardKey.arrowDown &&
        key != LogicalKeyboardKey.home &&
        key != LogicalKeyboardKey.end) {
      return KeyEventResult.ignored;
    }
    final current = enabled.indexOf(index);
    _go(
      key == LogicalKeyboardKey.home
          ? enabled.first
          : key == LogicalKeyboardKey.end
          ? enabled.last
          : enabled[(current + (backwards ? -1 : 1)) % enabled.length],
      backwards: backwards || key == LogicalKeyboardKey.home,
    );
    return KeyEventResult.handled;
  }

  /// The printable letter [event] types, lower case, with no modifier held; null for any other key.
  static String? _letter(KeyEvent event) {
    final character = event.character;
    if (character == null || character.length != 1) return null;
    final unit = character.codeUnitAt(0);
    if (unit <= 0x20 || unit == 0x7f) return null;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isMetaPressed || keys.isAltPressed) {
      return null;
    }
    return character.toLowerCase();
  }

  /// Moves the keys to item [next], keeping it in view inside a scrolling menu.
  void _go(int next, {required bool backwards}) {
    final node = _nodes[next];
    // The item the keys already stand on gains no focus, so it is lit here.
    if (_active != next) setState(() => _active = next);
    node.requestFocus();
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (!mounted || !node.hasFocus) return;
      final target = node.context;
      if (target == null) return;
      unawaited(
        Scrollable.ensureVisible(
          target,
          alignmentPolicy: backwards
              ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
              : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ),
      );
    });
    binding.ensureVisualUpdate();
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
    final look = comicStyleOf([widget.style, t.menuTheme], const {});
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
      padding: const EdgeInsets.all(ComicSpace.tight),
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
                // The active row's shade is the menu's own, below: it follows the keys as well as the pointer, so the
                // keys' row needs no ring (one round a row is painted over by the next, and reads as a rule).
                wash: false,
                ring: false,
                builder: (context, states) {
                  final lit = _active == i && states.enabled;
                  final chosen = widget.items[i].selected;
                  final ink = chosen
                      ? t.colors.onCaption
                      : states.enabled
                      ? t.colors.text
                      : t.colors.textSecondary;
                  // A row is at least the touch target tall, so the target never centres a shorter row off the
                  // menu's inset (the row's corner stays concentric with the rim).
                  return ComicHighlight(
                    states: {
                      if (lit) WidgetState.hovered,
                      if (lit && states.pressed) WidgetState.pressed,
                    },
                    shape: row,
                    ring: false,
                    washColor: chosen ? t.colors.onCaption : null,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: ComicTapTarget.targetOf(context),
                      ),
                      child: ComicStateDecoration(
                        decoration: ShapeDecoration(
                          shape: row,
                          color: chosen ? t.colors.caption : t.colors.card,
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
                                  const SizedBox(width: ComicSpace.close),
                                ],
                                Expanded(
                                  child: CapLabel(
                                    child: Text(
                                      widget.items[i].label,
                                      style: t.type.body.copyWith(color: ink),
                                    ),
                                  ),
                                ),
                                // The current option's mark beside its fill, so it reads without its colour too.
                                if (chosen) ...[
                                  const SizedBox(width: ComicSpace.close),
                                  const ExcludeSemantics(
                                    child: Icon(ComicGlyphs.check, size: 20),
                                  ),
                                ],
                              ],
                            ),
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

// The keys that open a menu: one is down while a menu opens from the keyboard (a press runs on the key's down).
final _openingKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.numpadEnter,
  LogicalKeyboardKey.space,
  LogicalKeyboardKey.select,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.arrowUp,
};

bool _openedByKeys() =>
    HardwareKeyboard.instance.logicalKeysPressed.any(_openingKeys.contains);

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
  // Opened from the keys, it lights its first item (or the chosen one); opened by the pointer, none until it moves.
  final quiet = !_openedByKeys();
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
        quiet: quiet,
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
  Widget build(BuildContext context) => _MenuAnchorHost<T>(anchor: this);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<ComicMenuItem<T>>('items', items))
      ..add(DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null))
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, VoidCallback open)
        >.has('builder', builder),
      )
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(
        FlagProperty(
          'matchAnchorWidth',
          value: matchAnchorWidth,
          ifTrue: 'matchAnchorWidth',
          defaultValue: false,
        ),
      );
  }
}

// Keeps whether a ComicMenuAnchor's menu is up, for its anchor to announce (ComicMenuOpen).
class _MenuAnchorHost<T> extends StatefulWidget {
  const _MenuAnchorHost({required this.anchor});

  final ComicMenuAnchor<T> anchor;

  @override
  State<_MenuAnchorHost<T>> createState() => _MenuAnchorHostState<T>();
}

class _MenuAnchorHostState<T> extends State<_MenuAnchorHost<T>> {
  bool _open = false;

  /// Round the anchor, taking no focus itself: its first focusable part (a select's field) takes the focus back when
  /// the menu closes, whether it was opened by the keys or by the pointer, chosen from or dismissed.
  final _anchorFocus = FocusNode(
    debugLabel: 'ComicMenuAnchor',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _anchorFocus.dispose();
    super.dispose();
  }

  void _refocus() =>
      _anchorFocus.traversalDescendants.firstOrNull?.requestFocus();

  Future<void> _show(BuildContext anchorContext) async {
    final room = anchorContext.findRenderObject();
    if (room is! RenderBox || !room.hasSize) return;
    // A dropdown's face may stand narrower than the room it is given (comicDropdownWidth): open from the face.
    final box = comicAnchorFaceOf(room);
    final anchor = widget.anchor;
    setState(() => _open = true);
    final result =
        await showComicMenu<T>(
          anchorContext,
          anchor: box.localToGlobal(Offset.zero) & box.size,
          items: anchor.items,
          style: anchor.style,
          matchAnchorWidth: anchor.matchAnchorWidth,
        ).whenComplete(() {
          if (!mounted) return;
          setState(() => _open = false);
          _refocus();
        });
    if (result != null && anchorContext.mounted) {
      widget.anchor.onSelected?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) => ComicMenuOpen(
    open: _open,
    child: Focus(
      focusNode: _anchorFocus,
      includeSemantics: false,
      child: Builder(
        builder: (anchorContext) =>
            widget.anchor.builder(anchorContext, () => _show(anchorContext)),
      ),
    ),
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
    // Its overlay went away under it, never dismissed: the entry ends with it.
    final entry = widget.handle.entry;
    widget.handle.entry = null;
    entry
      ?..remove()
      ..dispose();
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(
        DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null),
      );
  }
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(
        DiagnosticsProperty<Duration>(
          'waitDuration',
          waitDuration,
          defaultValue: const Duration(milliseconds: 400),
        ),
      )
      ..add(
        DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null),
      );
  }
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
              const SizedBox(width: ComicSpace.near),
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
        plate: true,
        child: inline
            ? Row(
                children: [
                  Expanded(child: words),
                  const SizedBox(width: ComicSpace.gap),
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) const SizedBox(width: ComicSpace.close),
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
                    const SizedBox(height: ComicSpace.close),
                  ],
                  words,
                  // The message's descenders stood on the action's rim: a beat of room between the words and the
                  // actions.
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: ComicSpace.near),
                    Wrap(
                      alignment: WrapAlignment.end,
                      // Centred across the run: the dismiss keeps a full finger's target around a face that density
                      // makes shorter, and on the run's top its face stood 2 px under the action's (ui_core's
                      // DesignRowCheck, comfortable and compact, 11-11).
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: ComicSpace.close,
                      runSpacing: ComicSpace.close,
                      children: actions,
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
      ..add(StringProperty('message', message))
      ..add(EnumProperty<ComicTone>('tone', tone, defaultValue: null))
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(StringProperty('actionLabel', actionLabel, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onAction', onAction))
      ..add(ObjectFlagProperty<VoidCallback>.has('onDismiss', onDismiss))
      ..add(StringProperty('dismissLabel', dismissLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null),
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

/// Holds an overlay entry for as long as its overlay stands: when the overlay goes, the entry is removed and
/// disposed with it (the toaster's entry has no other end).
class _OverlayLifetime extends StatefulWidget {
  const _OverlayLifetime({required this.entry, required this.child});

  final OverlayEntry entry;
  final Widget child;

  @override
  State<_OverlayLifetime> createState() => _OverlayLifetimeState();
}

class _OverlayLifetimeState extends State<_OverlayLifetime> {
  @override
  void dispose() {
    widget.entry
      ..remove()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The design kit's toaster on a navigator's overlay: empty, it takes no room and no press.
class _ToastHost {
  _ToastHost(OverlayState overlay, ComicLocalizations words) {
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _OverlayLifetime(
        entry: entry,
        child: DesignToaster(
          key: key,
          regionLabel: words.notifications,
          toastBuilder: _toastFace,
          child: const SizedBox.expand(),
        ),
      ),
    );
    overlay.insert(entry);
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
            padding: EdgeInsets.only(
              top: view.index == 0 ? 0 : ComicSpace.close,
            ),
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
        plate: true,
        padding: const EdgeInsets.symmetric(
          horizontal: ComicSpace.gap,
          vertical: ComicSpace.close,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tone != null) ...[
              ComicToneMark(tone!),
              const SizedBox(width: ComicSpace.close),
            ] else if (icon != null) ...[
              Icon(icon, size: 20, color: t.colors.text),
              const SizedBox(width: ComicSpace.close),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(EnumProperty<ComicTone>('tone', tone, defaultValue: null))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(
        DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null),
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
        look = comicStyleOf([style, theme], const {});
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
    this.padding = const EdgeInsets.all(ComicSpace.tight),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null))
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: const EdgeInsets.all(ComicSpace.tight),
        ),
      )
      ..add(
        DiagnosticsProperty<OutlinedBorder>('shape', shape, defaultValue: null),
      )
      ..add(
        FlagProperty(
          'plate',
          value: plate,
          ifFalse: 'plate: false',
          defaultValue: true,
        ),
      );
  }
}

/// Where a row's words start inside a list that opens from a field : on the field's words, less
/// the frame's rim and the 4 its rows stand in. Never under 6.
double comicFieldListWords(ComicThemeData t, [ComicStyle? style]) {
  final look = comicStyleOf([style, t.menuTheme], const {});
  final inset = comicRim(t, look, t.colors.nightLine, 3).width + 4;
  return math.max(6.0, comicFieldInset(t).start - inset);
}

/// The outline of a row inside a [ComicRaisedFrame]: the frame's own, inset by its rim and 4, so a lit row stays
/// concentric with the rim.
OutlinedBorder comicMenuRowShape(ComicThemeData t) {
  final look = comicStyleOf([t.menuTheme], const {});
  return comicInsetShape(
    look.shape ?? t.shapes.medium,
    comicRim(t, look, t.colors.nightLine, 3).width + 4,
  );
}

/// One row of a raised menu whose list the design kit drives. Chosen ([checked]) is printed as Comic prints every
/// chosen thing: the caption's flat yellow, its words in the caption's ink, and a check. The active row, while the
/// keyboard or the pointer is on it (the one Enter takes), wears the pointer's light Ben-Day shade, swollen under the
/// press: dots, never the chosen fill nor a line, so it can't read as a second choice or a divider. The quiet ink when
/// disabled. At least the touch target tall. Kept out of the barrel.
class ComicMenuRowFace extends StatelessWidget {
  /// Creates a [ComicMenuRowFace].
  const ComicMenuRowFace({
    super.key,
    required this.states,
    required this.label,
    this.icon,
    this.trailing,
    this.checked = false,
    this.mark = true,
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

  /// Chosen: the caption's fill, and a check at the end.
  final bool checked;

  /// Whether a [checked] row carries the check beside its fill. A tree's picked row is its fill alone.
  final bool mark;

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
    final ink = checked
        ? t.colors.onCaption
        : enabled
        ? (danger ? t.colors.tones.danger : t.colors.text)
        : t.colors.textSecondary;
    final outline = shape ?? comicMenuRowShape(t);
    return ComicHighlight(
      states: {
        if (lit) WidgetState.hovered,
        if (lit && states.contains(WidgetState.pressed)) WidgetState.pressed,
      },
      shape: outline,
      ring: false,
      washColor: checked ? t.colors.onCaption : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: ComicTapTarget.targetOf(context),
        ),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: outline,
            color: checked ? t.colors.caption : t.colors.card,
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
                    const SizedBox(width: ComicSpace.close),
                  ],
                  Expanded(
                    child: CapLabel(
                      child: Text(
                        label,
                        style: t.type.body.copyWith(color: ink),
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: ComicSpace.close),
                    // Words (a shortcut's) put their capitals on the row's middle, as the label's are: centred by
                    // their box, small words sit high. An icon is centred as it is.
                    if (trailing is Text)
                      CapLabel(
                        child: DefaultTextStyle.merge(
                          style: t.type.small.copyWith(color: ink),
                          child: trailing!,
                        ),
                      )
                    else
                      DefaultTextStyle.merge(
                        style: t.type.small.copyWith(color: ink),
                        child: trailing!,
                      ),
                  ],
                  if (checked && mark) ...[
                    const SizedBox(width: ComicSpace.close),
                    const ExcludeSemantics(
                      child: Icon(ComicGlyphs.check, size: 20),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('start', start, defaultValue: null))
      ..add(
        FlagProperty(
          'danger',
          value: danger,
          ifTrue: 'danger',
          defaultValue: false,
        ),
      )
      ..add(
        DiagnosticsProperty<OutlinedBorder>('shape', shape, defaultValue: null),
      )
      ..add(IterableProperty<WidgetState>('states', states))
      ..add(StringProperty('label', label))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(
        FlagProperty(
          'checked',
          value: checked,
          ifTrue: 'checked',
          defaultValue: false,
        ),
      )
      ..add(
        FlagProperty(
          'mark',
          value: mark,
          ifFalse: 'no mark',
          defaultValue: true,
        ),
      )
      ..add(DoubleProperty('lead', lead, defaultValue: null));
  }
}

/// A field that offers matching choices as a person types: the menu's own face under the field, the field's width.
/// Down or Up opens the list on the option taken (else the first), showing every option until the words are edited,
/// then the matches. Its active row wears the pointer's light Ben-Day shade and follows both the pointer and the Up and
/// Down keys, which wrap at the ends; Enter or a press takes it and writes its words into the field, which keeps the
/// focus, and while the field holds them the list shows that option chosen (the caption's flat yellow and a check).
/// Options match on [displayStringForOption]'s words, any part, any case.
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
    this.isOptionEnabled,
    this.focusNode,
    this.autofocus = false,
  });

  /// Everything the field can offer, in the order offered.
  final List<T> options;

  /// Whether an option can be taken; null: all can. One that cannot shows in the secondary ink, and the keys, the
  /// pointer and Enter pass over it.
  final bool Function(T option)? isOptionEnabled;

  /// An option's words in the field and in the list; `toString` when absent.
  final String Function(T option)? displayStringForOption;

  /// Called with the option taken.
  final ValueChanged<T>? onSelected;

  /// [label]: the field's name. [hint]: its placeholder. [helper]: a line under it. [initialValue]: its starting text.
  final String? label, hint, helper, initialValue;

  /// How many matches typed words show at most. With no words typed, or the words of the option taken, the list
  /// offers every option, scrolling.
  final int maxOptions;

  /// Appearance of the list above the menu's component theme.
  final ComicStyle? style;

  /// {@macro comic.focusNode}
  final FocusNode? focusNode;

  /// {@macro comic.autofocus}
  final bool autofocus;

  @override
  State<ComicCombobox<T>> createState() => _ComicComboboxState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('options', options))
      ..add(
        ObjectFlagProperty<String Function(T option)>.has(
          'displayStringForOption',
          displayStringForOption,
        ),
      )
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('initialValue', initialValue, defaultValue: null))
      ..add(IntProperty('maxOptions', maxOptions, defaultValue: 6))
      ..add(
        ObjectFlagProperty<bool Function(T option)>.has(
          'isOptionEnabled',
          isOptionEnabled,
        ),
      )
      ..add(DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
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

  /// The option last taken, while the field still holds its words: the list shows it chosen.
  T? _taken;

  void _take(T option) {
    setState(() => _taken = option);
    widget.onSelected?.call(option);
  }

  bool _chosen(T option) => option == _taken && _text.text == _words(option);

  Iterable<T> _search(String text) {
    final query = text.trim().toLowerCase();
    // No words yet: every option, so Down opens the list on an empty field.
    if (query.isEmpty) return widget.options;
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
      // The option taken: an opened list starts on it.
      value: _taken,
      isOptionEnabled: widget.isOptionEnabled,
      // The pointer's row and the keys' wear the same dots: one place, the pointer moving it, so two rows never read
      // as two current options.
      highlightFollowsPointer: true,
      onSelected: _take,
      semanticLabel: widget.label,
      fieldBuilder: (context, field) => ComicTextField(
        controller: field.controller,
        focusNode: field.focusNode,
        autofocus: widget.autofocus,
        label: widget.label,
        hint: widget.hint,
        helper: widget.helper,
        // Enter takes the highlighted option and the field keeps the focus, as a combobox's does: Flutter's own
        // finish to a done action would drop it. The take runs here, with no onSubmitted: a field told of a submit
        // that keeps its focus has its text input restarted, and in a browser the restarted input takes no typing.
        onEditingComplete: field.submit,
      ),
      // Its options' words start on the field's words. The kit marks the value selected; Comic prints the chosen option yellow and checked while the field holds its
      // words, so the face takes the keys' and the pointer's states alone.
      optionBuilder: (context, option, states) => ComicMenuRowFace(
        states: states.difference(const {WidgetState.selected}),
        label: _words(option),
        checked: _chosen(option),
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

/// The page behind a modal layer, screened (law 1: nothing see-through): Ben-Day dots of [ink], opaque, swelling over the
/// whole screen with [animation] and shrinking away with it (law 6: drawn, not faded). The page shows between the dots.
/// Comic's routes lay it under their barrier; a route of your own can too. Give it the theme's `colors.scrim`: black
/// dots by day, and by night the night's cream line, a reverse screen that knocks the black ground back.
///
/// ```dart
/// ComicScreenScrim(animation: animation, ink: ComicTheme.of(context).colors.scrim)
/// ```
class ComicScreenScrim extends StatelessWidget {
  /// Creates a [ComicScreenScrim].
  const ComicScreenScrim({
    super.key,
    required this.animation,
    required this.ink,
  });

  /// The layer's own coming and going: 0 is no dots, 1 the whole screen.
  final Animation<double> animation;

  /// The dots' ink; its alpha is dropped, as print has none.
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => SizedBox.expand(
          child: CustomPaint(
            painter: _ScrimPainter(
              ink.withValues(alpha: 1),
              ComicScreenGrid(
                comicScrimPitch,
                comicScrimRadius * animation.value.clamp(0, 1),
                dpr,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Animation<double>>('animation', animation))
      ..add(ColorProperty('ink', ink));
  }
}

/// A modal route whose page behind is screened, not dimmed (law 1): a [ComicScreenScrim] of [screenInk] under its
/// barrier, which still takes the presses. Give the route no barrier colour of its own.
///
/// ```dart
/// class IssueRoute<T> extends RawDialogRoute<T> with ComicScreenedRoute<T> { IssueRoute({required super.pageBuilder}) : super(barrierColor: null, barrierLabel: 'Close'); @override Color? get screenInk => const Color(0x99000000); }
/// ```
mixin ComicScreenedRoute<T> on ModalRoute<T> {
  /// The dots' ink; null leaves the page as it is.
  Color? get screenInk;

  @override
  Widget buildModalBarrier() {
    final barrier = super.buildModalBarrier();
    final ink = screenInk;
    if (ink == null || offstage) return barrier;
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: ComicScreenScrim(animation: animation!, ink: ink),
        ),
        barrier,
      ],
    );
  }
}

/// The modal screen's dots: one every [comicScrimPitch], [comicScrimRadius] round at full strength, about a quarter of
/// the page in ink: the page still reads behind, screened back.
const double comicScrimPitch = 6, comicScrimRadius = 1.25;

class _ScrimPainter extends CustomPainter {
  const _ScrimPainter(this.ink, this.grid);
  final Color ink;
  final ComicScreenGrid grid;
  @override
  void paint(Canvas canvas, Size size) {
    if (grid.radius <= 0) return;
    grid.paint(canvas, Offset.zero & size, ink);
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.ink != ink ||
      old.grid.radius != grid.radius ||
      old.grid.pitch != grid.pitch;
}
