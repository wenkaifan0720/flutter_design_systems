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
import 'internal/pop.dart';
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
import 'internal/footer_clear.dart';
import 'internal/list_open.dart';
import 'internal/message_line.dart';
import 'internal/cap_label.dart';
import 'print.dart' show ComicScreenGrid;
import 'internal/lettering.dart' show comicDisplayFor;
import 'internal/track.dart';
import 'internal/style_guard.dart';
import 'knobs.dart' show ComicSpace;
import 'internal/corners.dart';

class _Carried {
  _Carried(BuildContext context, NavigatorState navigator)
    : this.into(context, navigator.context);

  // What [context] reads, carried into a part built under [to], one of its ancestors.
  _Carried.into(BuildContext context, BuildContext to)
    : themes = InheritedTheme.capture(from: context, to: to),
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

/// Carries the current theme, text direction and localizations into a route on [navigator].
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
    required this.closeLabel,
    required this.dimBackground,
    this.drawer = false,
  }) : super(
         requestFocus: true,
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
       );
  final _Carried carried;
  final WidgetBuilder builder;
  final bool dismissible;
  final bool dimBackground;

  /// Stands at the start edge, the window's full height, and slides in from that edge.
  final bool drawer;
  final String closeLabel;
  @override
  bool get barrierDismissible => dismissible;
  @override
  String get barrierLabel => closeLabel;
  // The page behind is screened (law 1): Ben-Day dots swell over it as the layer comes in, over an overprint of the
  // ground at night, and the barrier under them takes the presses.
  @override
  Color? get barrierColor => null;

  @override
  Color? get screenInk => dimBackground ? carried.scrim : null;
  @override
  Duration get transitionDuration =>
      drawer ? carried.motion.travel : carried.motion.raise;
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
      builder: (context) => drawer
          ? _DrawerFrame(child: Builder(builder: builder))
          : builder(context),
    ),
  );
  // Motion is drawn, never faded (law 6): every frame of a raised layer is printed at full ink. A drawer travels
  // in from its edge and stops there, its overshoot held at the edge so it never comes loose from it; a menu pops
  // in, its overshoot a short bounce in place.
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final travel = CurveTween(curve: _HeldAtEdge(carried.motion.enter));
    if (drawer) {
      return SlideTransition(
        position: Tween(
          begin: Offset(
            Directionality.of(context) == TextDirection.rtl ? 1 : -1,
            0,
          ),
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
      closeLabel:
          closeLabel ?? RawWidgetsLocalizations.of(context).closeButtonLabel,
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

/// Shows a dialog and returns the result passed to [Navigator.pop].
/// Escape and back dismiss the dialog. Focus returns to the control that opened it.
/// Set [barrierDismissible] to control whether tapping the backdrop dismisses it.
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
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final carry = comicCarryTo(context, navigator);
  return navigator.push<T>(
    ComicDialogRoute<T>(
      screenInk: ComicTheme.of(context).colors.scrim,
      barrierDismissible: barrierDismissible,
      barrierLabel:
          closeLabel ?? RawWidgetsLocalizations.of(context).closeButtonLabel,
      builder: (context) => carry(context, Builder(builder: builder)),
    ),
  );
}

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
  /// the act button); where the row has no room, stacked each as wide as the dialog, the last on top.
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
        // The actions stand at the trailing end in reading order, the confirming one last, as Material's and
        // Cupertino's dialogs set theirs; stacked, one column at the dialog's width, the confirming one on top.
        RawActionBar(
          spacing: ComicSpace.close,
          overflowSpacing: ComicSpace.close,
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
                padding: EdgeInsetsDirectional.only(
                  end: comicRaisedPlate * t.depth,
                  bottom: comicRaisedPlate * t.depth,
                ),
                child: _RaisedFrame(
                  style: style,
                  theme: t.dialogTheme,
                  corner: RawCorner.large,
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
                            child: Text(
                              title!,
                              style: comicDisplayFor(title!, t.type.panel),
                            ),
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

/// Raises a sheet from the page's foot on ui_core's [RawBottomSheetRoute], carrying its theme and direction. It
/// travels in on a spring and stops at its edge, as tall as its content up to the window less 24; a drag down or a
/// fling puts it away, and a [ComicBottomSheet] inside hands its scroll over to that drag. Escape, back and a press on
/// the screen close it, and focus returns to what opened it.
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
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final carry = comicCarryTo(context, navigator);
  return navigator.push<T>(
    ComicBottomSheetRoute<T>(
      screenInk: ComicTheme.of(context).colors.scrim,
      barrierDismissible: barrierDismissible,
      barrierLabel:
          closeLabel ?? RawWidgetsLocalizations.of(context).closeButtonLabel,
      builder: (context, sheet) => carry(
        context,
        _SheetScope(
          sheet: sheet,
          child: SafeArea(
            top: false,
            bottom: false,
            child: LayoutBuilder(
              builder: (context, room) => ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: math.max(48, room.maxHeight - 24),
                ),
                child: Builder(builder: builder),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// The open sheet round a ComicBottomSheet, whose scroll view takes the sheet's controller (the hand-over to its drag).
class _SheetScope extends InheritedWidget {
  const _SheetScope({required this.sheet, required super.child});
  final RawBottomSheetDetails sheet;

  static ScrollController? scrollOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SheetScope>()
      ?.sheet
      .scrollController;

  @override
  bool updateShouldNotify(_SheetScope old) =>
      sheet.scrollController != old.sheet.scrollController;
}

/// A dialog that springs into view over a [ComicScreenScrim].
/// The dialog appears immediately when reduced motion is enabled.
class ComicDialogRoute<T> extends RawModalDialogRoute<T> {
  /// Creates a [ComicDialogRoute] whose face [builder] builds.
  ComicDialogRoute({
    required Color screenInk,
    required WidgetBuilder builder,
    super.barrierDismissible,
    super.barrierLabel,
    super.settings,
  }) : super(
         dampingRatio: .6,
         stiffness: 900,
         barrierBuilder: (context, animation) =>
             ComicScreenScrim(animation: animation, ink: screenInk),
         builder: (context, dialog) =>
             _Pop(animation: dialog.animation, child: builder(context)),
       );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

// The face's pop: .92 to 1 on the route's presence, which passes 1 and comes back. A theme's still motion holds it.
class _Pop extends StatelessWidget {
  const _Pop({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      ComicMotion.of(context).raise == Duration.zero
      ? child
      : AnimatedBuilder(
          animation: animation,
          builder: (context, child) =>
              Transform.scale(scale: .92 + .08 * animation.value, child: child),
          child: child,
        );
}

/// A sheet that slides up over a [ComicScreenScrim].
/// The sheet is centred and at most 640 logical pixels wide.
class ComicBottomSheetRoute<T> extends RawBottomSheetRoute<T> {
  /// Creates a [ComicBottomSheetRoute] whose panel [builder] builds.
  ComicBottomSheetRoute({
    required Color screenInk,
    required super.builder,
    super.barrierDismissible,
    super.barrierLabel,
    super.settings,
  }) : super(
         useSafeArea: true,
         dampingRatio: .75,
         stiffness: 600,
         barrierBuilder: (context, animation) =>
             ComicScreenScrim(animation: animation, ink: screenInk),
       );

  /// The panel's widest.
  static const double maxWidth = 640;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Align(
    alignment: Alignment.bottomCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: super.buildPage(context, animation, secondaryAnimation),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

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
            controller: controller ?? _SheetScope.scrollOf(context),
            shrinkWrap: true,
            slivers: slivers!,
          )
        : SingleChildScrollView(
            controller: controller ?? _SheetScope.scrollOf(context),
            padding: const EdgeInsets.all(ComicSpace.gap),
            child: child,
          );
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: AnimatedComicShape(
        shape: comicPartShape(t, look, RawCorner.large),
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
                                      child: Text(
                                        title!,
                                        style: comicDisplayFor(
                                          title!,
                                          t.type.panel,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          if (onClose != null || showClose)
                            ComicIconButton(
                              ComicGlyphs.close,
                              semanticLabel:
                                  closeLabel ??
                                  RawWidgetsLocalizations.of(context)
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

/// A menu that marks the selected item with a yellow fill and check.
///
/// Arrow keys, Home, End, Tab and typing move the active row. Hovering a row
/// gives it the same tint. The row the keyboard stands on also pops inside
/// its outline: a hard print along its bottom and end edges, its words on
/// the row's plain fill. Enter selects the active item. [showComicMenu]
/// initially focuses the selected or first item when opened from the keyboard.
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

  /// Whether the pointer, not a key, moved the active item last. The pointer's row wears the shade alone; the keys'
  /// row also shows the keyboard's print.
  bool _pointer = false;

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
    if (_active != i || !_pointer) {
      setState(() {
        _active = i;
        _pointer = true;
      });
    }
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
    // From here the keys move the active item, so it shows the keyboard's print.
    if (_pointer) setState(() => _pointer = false);
    // A quiet menu's first key lights the item the keys stand on (the chosen one, or the first), or the last going
    // up (Up, End, Shift+Tab), and takes nothing: Enter, Space and Tab light it too, so nothing unseen is ever taken
    // and Tab never passes over a row it never showed. After that, Tab moves the focus as Flutter's traversal does.
    final wasQuiet = _quiet;
    if (_quiet) {
      final tab = key == LogicalKeyboardKey.tab;
      final up =
          key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.end ||
          (tab && HardwareKeyboard.instance.isShiftPressed);
      if (up ||
          tab ||
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
    final frame = comicPartShape(t, look, RawCorner.medium);
    // A row sits 4 px inside the rim, so its corner is the menu's minus that inset: concentric, never a square
    // block inside a rounded menu. Its wash takes the same outline.
    final inset = comicRim(t, look, t.colors.nightLine, 3).width + 4;
    final row = comicInsetShape(frame, inset);
    // The words' start inside a row: the menu's own 12, or the field's words when it opened from one.
    final start = widget.wordsAt == null
        ? 12.0
        : math.max(6.0, widget.wordsAt! - inset);
    // A raised menu stands on its plate over the page, and a long one scrolls inside its rim.
    return _RaisedFrame(
      style: widget.style,
      theme: t.menuTheme,
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
                semanticLabel: widget.items[i].label,
                selected: widget.items[i].selected,
                onPressed: !widget.items[i].enabled || widget.onSelected == null
                    ? null
                    : () => widget.onSelected!(widget.items[i].value),
                keys: (_, event) => _key(i, event),
                outline: WidgetStatePropertyAll(row),
                // The active row's shade and the keyboard's print are the menu's own, below: the shade follows the
                // keys as well as the pointer, and the print marks the keys' row inside its outline, since a row
                // lifted over the next would cover it.
                wash: false,
                ring: false,
                builder: (context, states) {
                  final lit = _active == i && states.enabled;
                  final keys = states.focused && states.enabled && !_pointer;
                  final chosen = widget.items[i].selected;
                  final ink = chosen
                      ? t.colors.onCaption
                      : states.enabled
                      ? t.colors.text
                      : t.colors.textSecondary;
                  // A row is at least the touch target tall, so the target never centres a shorter row off the
                  // menu's inset (the row's corner stays concentric with the rim).
                  final face = ComicHighlight(
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
                  // Rows stand edge to edge, so the keys' row pops inside itself: a hard print along its bottom and
                  // end, as a tree's row does. On the chosen row's yellow a band of the card's colour keeps it apart.
                  return Stack(
                    children: [
                      face,
                      Positioned.fill(
                        child: PopInside(
                          child: ComicHighlight(
                            states: keys ? _keysRow : const <WidgetState>{},
                            shape: row,
                            wash: false,
                            ringGap: t.colors.card,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// The states of the menu row the keyboard stands on, for its print.
const Set<WidgetState> _keysRow = {WidgetState.focused};

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
      // The menu scrolls inside its own rim when the window is short: its frame stays whole.
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
      // A box at the medium step, or the corners a style gives it.
      ComicStyle(
        shape: WidgetStatePropertyAll(
          comicPartShape(
            ComicTheme.of(context),
            comicStyleOf([
              style,
              ComicTheme.of(context).tooltipTheme,
            ], const {}),
            RawCorner.medium,
          ),
        ),
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

/// Explains its child on hover, keyboard focus or long press: Flutter's [RawTooltip] in Comic's balloon
/// ([ComicTooltipFace]), under the child, centred on it.
///
/// It shows when a pointer rests on the child for [waitDuration], at once when the keyboard's focus reaches it
/// (ui_core's [RawTooltipFocusFix]), and after a long press. The pointer may move onto the balloon and it stays; Escape
/// hides it; one shows at a time. [RawTooltipPlacement] sets it below the child, or above where too little room is
/// left below. A screen reader hears [message] as the child's tooltip.
///
/// ```dart
/// ComicTooltip(message: 'Save this issue', child: ComicIconButton(icon, semanticLabel: 'Save', onPressed: save))
/// ```
class ComicTooltip extends StatelessWidget {
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

  // Under the child and centred on it, 6 px off; above it where too little room is left below.
  static const _placement = RawPopoverPlacement(
    side: RawPopoverSide.below,
    align: RawPopoverAlign.center,
    gap: 6,
    preferredExtent: 48,
    matchAnchorWidth: false,
  );

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return child;
    final spring = RawMotionPolicy.of(context)
        .effects(dampingRatio: 1, stiffness: 1600);
    // The balloon comes and goes on its own spring. RawTooltip's animation says only whether it shows: at once when it
    // shows, and while it hides, as long as the spring takes to close from open, so the balloon stays until it has
    // closed.
    final closing = _settleTime(spring);
    // The message joins the child's node: one control, one node.
    return MergeSemantics(
      child: RawTooltipPlacement(
        placement: _placement,
        builder: (context, positionDelegate) => RawTooltip(
          semanticsTooltip: message,
          hoverDelay: waitDuration,
          animationStyle: AnimationStyle(
            duration: Duration.zero,
            reverseDuration: closing,
          ),
          positionDelegate: positionDelegate,
          tooltipBuilder: (context, shown) => ExcludeSemantics(
            child: _TipPresence(
              shown: shown,
              spring: spring,
              builder: (context, presence) => AnimatedBuilder(
                animation: presence,
                // A short pop from .92, opaque from its first frame, and cut away at the end: nothing fades (law 6).
                // Under Reduce Motion it stands at its size.
                builder: (context, face) => presence.isDismissed
                    ? const SizedBox.shrink()
                    : Transform.scale(
                        scale: rawReduceMotionOf(context)
                            ? 1
                            : .92 + .08 * presence.value.clamp(0, 1),
                        child: face,
                      ),
                child: ComicTooltipFace(message: message, style: style),
              ),
            ),
          ),
          child: RawTooltipFocusFix(child: child),
        ),
      ),
    );
  }

  // How long [spring] takes to close the balloon from open: until its simulation is done, to the millisecond above.
  static Duration _settleTime(SpringDescription spring) {
    final closing = rawSpringSimulation(spring, from: 1, to: 0);
    var ms = 1;
    while (ms < 5000 && !closing.isDone(ms / 1000)) {
      ms++;
    }
    return Duration(milliseconds: ms);
  }

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

// A balloon's presence, 0 to 1, on [spring]: toward 1 while [shown] runs forward or has completed, toward 0 while it
// runs back.
class _TipPresence extends StatefulWidget {
  const _TipPresence({
    required this.shown,
    required this.spring,
    required this.builder,
  });

  final Animation<double> shown;
  final SpringDescription spring;
  final Widget Function(BuildContext context, Animation<double> presence)
  builder;

  @override
  State<_TipPresence> createState() => _TipPresenceState();
}

class _TipPresenceState extends State<_TipPresence>
    with SingleTickerProviderStateMixin {
  // Bounded: a balloon's presence is a pop, 0 to 1.
  late final AnimationController _presence = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _presence.addStatusListener(_settled);
    widget.shown.addStatusListener(_follow);
    _follow(widget.shown.status);
  }

  @override
  void didUpdateWidget(_TipPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shown != widget.shown) {
      oldWidget.shown.removeStatusListener(_follow);
      widget.shown.addStatusListener(_follow);
      _follow(widget.shown.status);
    }
  }

  @override
  void dispose() {
    widget.shown.removeStatusListener(_follow);
    _presence.dispose();
    super.dispose();
  }

  void _follow(AnimationStatus status) {
    final target = status.isForwardOrCompleted ? 1.0 : 0.0;
    if (_presence.value == target && !_presence.isAnimating) return;
    _presence.springTo(target, widget.spring);
  }

  // The spring started or came to rest: whether the tip is gone may change.
  void _settled(AnimationStatus status) {
    if (mounted) setState(() {});
  }

  // A hiding tip is gone once its spring has closed it, as ui_core's tooltip
  // took it away then. RawTooltip's own animation can run on (it lasts as
  // long as a close from fully open), and the tip would stay in place,
  // unseen, where a pointer could bring it back.
  bool get _gone =>
      !widget.shown.isForwardOrCompleted &&
      !_presence.isAnimating &&
      _presence.value == 0;

  @override
  Widget build(BuildContext context) =>
      _gone ? const SizedBox.shrink() : widget.builder(context, _presence);
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
    final surface = comicStyleOf([style, t.snackBarTheme], const {});
    final rim = comicRim(t, surface, t.colors.nightLine, 3);
    final inset = t.desk ? ComicSpace.wide : ComicSpace.gap;
    final pad =
        (surface.padding(Directionality.of(context)) ?? EdgeInsets.all(inset))
            .resolve(Directionality.of(context));
    final end = Directionality.of(context) == TextDirection.rtl
        ? pad.left
        : pad.right;
    final shape = comicInsetShape(
      comicPartShape(t, surface, RawCorner.medium),
      rim.width + end,
    );
    final actionStyle = ComicStyle(shape: WidgetStatePropertyAll(shape));
    final actions = <Widget>[
      // The action is the act, as a Material SnackBarAction takes the accent; the dismiss stays a plain key.
      if (onAction != null && actionLabel != null)
        ComicButton.filled(
          actionLabel!,
          style: actionStyle,
          onPressed: onAction,
        ),
      if (onDismiss != null)
        // As tall as the action beside it: one row, one height.
        ComicIconButton(
          ComicGlyphs.x,
          style: actionStyle,
          // Its size takes the density again: the field's height before it.
          size: ComicTrack.fieldHeight(context) - t.density.heightDelta,
          semanticLabel: dismissLabel ?? ComicLocalizations.of(context).dismiss,
          onPressed: onDismiss,
        ),
    ];
    // An announcement with no heading keeps its actions at the end of the message's line, as a Material SnackBar
    // does, while the words fit beside them or the actions take at most a quarter of a phone's bar (the words then
    // wrap beside them); past that they stand on a line under the words. On a desktop it is one strip whatever its
    // words: a second line would make a tall bar at desktop width. On a phone the actions always stood under the
    // words, a tall box for "Changes saved" and its dismiss.
    final inline = title == null && actions.isNotEmpty;
    return Semantics(
      liveRegion: _live,
      child: _RaisedFrame(
        style: style,
        theme: t.snackBarTheme,
        padding: EdgeInsets.all(inset),
        plate: true,
        child: inline
            ? ComicMessageLine(
                gap: ComicSpace.gap,
                // The message's descenders stood on the action's rim: a beat of room between the words and the
                // actions under them.
                runGap: ComicSpace.near,
                actionOverflowThreshold: t.desk ? 1 : .25,
                message: words,
                actions: _actionRun(actions),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) ...[
                    CapLabel(
                      child: Text(
                        title!,
                        style: comicDisplayFor(title!, t.type.panel),
                      ),
                    ),
                    const SizedBox(height: ComicSpace.close),
                  ],
                  words,
                  // The message's descenders stood on the action's rim: a beat of room between the words and the
                  // actions.
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: ComicSpace.near),
                    _actionRun(actions),
                  ],
                ],
              ),
      ),
    );
  }

  // The actions in one run, at the end of the room they are given.
  static Widget _actionRun(List<Widget> actions) => Wrap(
    alignment: WrapAlignment.end,
    // Centred across the run: the dismiss keeps a full finger's target around a face that density makes shorter; on
    // the run's top its face would stand 2 px under the action's at the comfortable and compact densities, as
    // ui_core's DesignRowCheck measures.
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: ComicSpace.close,
    runSpacing: ComicSpace.close,
    children: actions,
  );

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

/// Shows [message] as a [ComicSnackBar] for [duration], in the app's one toaster that [ComicHost] holds above the
/// navigator: it stays in sight when the app's place changes, and stands above the shell's tab bar, a page's footer and
/// the keyboard, wherever it was raised from. Up to three stand stacked, the newest last; more wait their turn. Without
/// a [ComicHost] it rises in the navigator's own overlay. An action stays until it is answered while a screen reader
/// runs.
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
  final handle = _Toasted();
  final app = _AppToasts.of(context);
  if (app != null) {
    handle.attach(
      app.show(
        RawToast(
          message: message,
          title: title,
          actionLabel: actionLabel,
          onAction: onAction,
          duration: duration,
          data: _ToastShown(
            carried: _Carried.into(context, app.context),
            shell: 0,
            hosted: true,
            style: style,
            tone: tone,
            dismissLabel: dismissLabel,
          ),
        ),
      ),
    );
    return handle;
  }
  final navigator = Navigator.of(context);
  final overlay = navigator.overlay!;
  final words = ComicLocalizations.of(context);
  final host = _toasters[overlay] ??= _ToastHost(overlay, words);
  host.raise(
    RawToast(
      message: message,
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      data: _ToastShown(
        carried: _Carried(context, navigator),
        shell: math.max(
          ShellInsets.of(context),
          ComicFooterClear.of(context, overlay),
        ),
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
    this.hosted = false,
    this.style,
    this.tone,
    this.dismissLabel,
  });
  final _Carried carried;
  final double shell;

  // In the app's toaster, which keeps it clear of the bars and the keyboard itself.
  final bool hosted;
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

/// Shows toasts in the navigator overlay.
class _ToastHost {
  _ToastHost(OverlayState overlay, ComicLocalizations words) {
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _OverlayLifetime(
        entry: entry,
        child: RawToaster(
          key: key,
          regionLabel: words.notifications,
          toastBuilder: _toastFace,
          child: const SizedBox.expand(),
        ),
      ),
    );
    overlay.insert(entry);
  }

  final key = GlobalKey<RawToasterState>();

  void raise(RawToast toast, _Toasted handle) {
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

  static Widget _toastFace(BuildContext context, RawToastDetails view) {
    final toast = view.toast;
    final data = toast.data;
    if (data is _ToastLine) return _lineFace(context, view, data);
    final shown = data! as _ToastShown;
    return shown.carried.wrap(
      context,
      Transform.translate(
        offset: Offset(
          0,
          shown.hosted
              ? 0
              : -math.max(shown.shell, MediaQuery.viewInsetsOf(context).bottom),
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

// A toast's face in the app's toaster: centred, 420 at most, a short pop from .92, opaque from its first frame and cut
// away at the end: nothing fades (law 6).
Widget _lineFace(BuildContext context, RawToastDetails view, _ToastLine line) =>
    line.carried.wrap(
      context,
      Padding(
        padding: EdgeInsets.only(top: view.index == 0 ? 0 : ComicSpace.close),
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AnimatedBuilder(
              animation: view.animation,
              builder: (context, face) => Transform.scale(
                scale: .92 + .08 * view.animation.value.clamp(0.0, 1.0),
                child: face,
              ),
              child: ComicToast._toasted(
                view.toast.message,
                tone: line.tone,
                icon: line.icon,
                style: line.style,
              ),
            ),
          ),
        ),
      ),
    );

/// The app's one toaster, which [ComicHost] holds above the navigator: every snack bar and toast raised under it
/// ([showComicSnackBar], [showComicToast]) stands here, so it outlives a switch of place and keeps clear of the shell's
/// navigation, a page's footer ([RawToasterKeepClear]) and the keyboard.
class ComicAppToaster extends StatefulWidget {
  /// Holds the toasts raised under [child].
  const ComicAppToaster({super.key, required this.child});

  /// The app: its navigator.
  final Widget child;

  @override
  State<ComicAppToaster> createState() => _ComicAppToasterState();
}

class _ComicAppToasterState extends State<ComicAppToaster> {
  final _toaster = GlobalKey<RawToasterState>(debugLabel: 'ComicAppToaster');

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    Widget toaster = RawToaster(
      key: _toaster,
      regionLabel: ComicLocalizations.of(context).notifications,
      toastBuilder: _ToastHost._toastFace,
      // The app under the toasts reads the window as it is.
      child: media == null
          ? widget.child
          : MediaQuery(data: media, child: widget.child),
    );
    if (media != null) {
      // The keyboard is an edge the toasts keep clear of, as the safe inset is: they stand above it or above a bar
      // the toaster keeps them clear of, whichever is higher.
      toaster = MediaQuery(
        data: media.copyWith(
          padding: media.padding.copyWith(
            bottom: math.max(media.padding.bottom, media.viewInsets.bottom),
          ),
        ),
        child: toaster,
      );
    }
    return _AppToasts(toaster: _toaster, child: toaster);
  }
}

// Marks the app's toaster for what is raised under it.
class _AppToasts extends InheritedWidget {
  const _AppToasts({required this.toaster, required super.child});

  final GlobalKey<RawToasterState> toaster;

  // The app's toaster above [context]; null without a [ComicHost].
  static RawToasterState? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_AppToasts>()?.toaster.currentState;

  @override
  bool updateShouldNotify(_AppToasts oldWidget) => oldWidget.toaster != toaster;
}

class _Toasted implements ComicRaised {
  RawToastController? _handle;
  bool _dismissed = false;
  final _closed = Completer<void>();

  // A newer toast took its place: it is gone, and its handle no longer reaches the newer one.
  void release() {
    _handle = null;
    finish();
  }

  void attach(RawToastController handle) {
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
  const ComicToast(this.message, {super.key, this.tone, this.icon, this.style})
    : _live = true;

  /// A toast face in the app's toaster, which speaks for it.
  const ComicToast._toasted(this.message, {this.tone, this.icon, this.style})
    : _live = false;

  /// Speaks when it appears; the toaster speaks for the toasts it holds.
  final bool _live;

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
      liveRegion: _live,
      container: true,
      label: message,
      excludeSemantics: true,
      child: _RaisedFrame(
        style: style,
        theme: t.snackBarTheme,
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

// The toast standing in each app toaster, which the next one replaces.
final _hostedToasts = Expando<_Toasted>();
const Object _comicToastId = #comicToast;

class _ToastLine {
  const _ToastLine({required this.carried, this.tone, this.icon, this.style});
  final _Carried carried;
  final ComicTone? tone;
  final IconData? icon;
  final ComicStyle? style;
}

/// Shows [message] as a [ComicToast] for [duration], in the app's one toaster that [ComicHost] holds above the
/// navigator, replacing the toast standing there: it stays in sight when the app's place changes, and stands above the
/// shell's tab bar, a page's footer and the keyboard, wherever it was raised from. Without a [ComicHost] it rises in the
/// navigator's own overlay. It asks for nothing: a toast that needs an answer is a [showComicSnackBar].
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
  final app = _AppToasts.of(context);
  if (app != null) {
    _hostedToasts[app]?.release();
    final handle = _Toasted();
    _hostedToasts[app] = handle;
    handle.closed.whenComplete(() {
      if (identical(_hostedToasts[app], handle)) _hostedToasts[app] = null;
    });
    handle.attach(
      app.show(
        RawToast(
          // One toast at a time: the next takes this one's place, its time restarted.
          id: _comicToastId,
          message: message,
          duration: duration,
          data: _ToastLine(
            carried: _Carried.into(context, app.context),
            tone: tone,
            icon: icon,
            style: style,
          ),
        ),
      ),
    );
    return handle;
  }
  final navigator = Navigator.of(context);
  final overlay = navigator.overlay!;
  _toasts[overlay]?.dismiss();
  final carried = _Carried(context, navigator);
  final shellAllowance = math.max(
    ShellInsets.of(context),
    ComicFooterClear.of(context, overlay),
  );
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

/// The offset of the solid ink shadow under a raised surface, in logical pixels.
const double comicRaisedPlate = 4;

class _RaisedFrame extends StatelessWidget {
  const _RaisedFrame({
    required this.child,
    required this.theme,
    this.style,
    this.shape,
    this.corner = RawCorner.medium,
    this.padding,
    this.plate = false,
    this.scrolls = false,
  });
  final Widget child;
  final ComicStyle? style;
  final ComicStyle theme;

  /// An outline given as it is (a [ComicRaisedFrame]'s shape); null, the frame's own at [corner], or the style's.
  final OutlinedBorder? shape;

  /// The step of Comic's corner scale the frame's own corners take: large for a dialog, medium otherwise.
  final RawCorner corner;
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
      shape: look.shape ?? shape ?? comicPartShape(t, look, corner),
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
            comicRaisedPlate * ComicTheme.of(context).depth,
          ),
          child: face,
        );
      },
    );
  }
}

/// Paints a surface's plate behind it: its outline, [plate] down and to the end ([comicRaisedPlate] at a theme's depth
/// of 1), in its rim's ink (the line by day, the lit line by night, so it reads on either ground).
class _PlatePainter extends CustomPainter {
  const _PlatePainter(this.outline, this.ink, this.direction, this.plate);
  final ShapeBorder outline;
  final Color ink;
  final TextDirection direction;
  final double plate;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    outline.getOuterPath(
      (Offset.zero & size).shift(
        Offset(direction == TextDirection.rtl ? -plate : plate, plate),
      ),
      textDirection: direction,
    ),
    Paint()..color = ink,
  );

  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_PlatePainter old) =>
      old.outline != outline ||
      old.ink != ink ||
      old.direction != direction ||
      old.plate != plate;
}

/// A menu or popover frame with a themed fill, rim and inner [padding].
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
      shape: shape,
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
    comicPartShape(t, look, RawCorner.medium),
    comicRim(t, look, t.colors.nightLine, 3).width + 4,
  );
}

/// A menu row with a solid tint for hover and a check beside a selected label.
/// The row grows to fit large text and the configured touch target.
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

  /// The active hover, focus, press and disabled states for this row.
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
          // The keys' and the pointer's row carries a rule of ink at its start, as wide as a plate is deep: the dots
          // under it alone stood 15 of 255 from its neighbours, too faint to find at a glance.
          child: CustomPaint(
            painter: lit
                ? _LitRule(ink, outline, Directionality.of(context))
                : null,
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

/// An editable field that shows matching [options] in a menu.
///
/// Use [displayStringForOption] to provide labels or [search] to request
/// suggestions asynchronously. A failed request can be retried from the menu.
/// Arrow keys and the pointer move the active row. Enter or a tap selects it
/// and returns focus to the field.
///
/// ```dart
/// ComicCombobox<String>(labelText: 'City', options: const ['Lisbon', 'London', 'Lyon'], onSelected: pick)
/// ```
class ComicCombobox<T extends Object> extends StatefulWidget {
  /// Creates an autocomplete field over [options].
  const ComicCombobox({
    super.key,
    this.style,
    required this.options,
    this.displayStringForOption,
    this.onSelected,
    this.labelText,
    this.hintText,
    this.helperText,
    this.initialValue,
    this.maxOptions = 6,
    this.isOptionEnabled,
    this.focusNode,
    this.autofocus = false,
    this.search,
    this.debounceDuration,
  });

  /// Everything the field can offer, in the order offered. With a [search], the options it offers before any words
  /// are typed are the search's for no words, and these go unused.
  final List<T> options;

  /// Finds the options for the typed words in place of matching [options]: ui_core's `RawCombobox.search`. Only
  /// the latest words' answer shows; while it is on its way the list says it is looking, and if it throws, the list
  /// says the search failed and offers Try again, the field keeping the focus.
  final RawOptionSearch<T>? search;

  /// How long typing rests before [search] runs: one search a pause, not one a letter. Null runs it at every change.
  final Duration? debounceDuration;

  /// Whether an option can be taken; null: all can. One that cannot shows in the secondary ink, and the keys, the
  /// pointer and Enter pass over it.
  final bool Function(T option)? isOptionEnabled;

  /// An option's words in the field and in the list; `toString` when absent.
  final String Function(T option)? displayStringForOption;

  /// Called with the option taken.
  final ValueChanged<T>? onSelected;

  /// [labelText]: the field's name. [hintText]: its placeholder. [helperText]: a line under it. [initialValue]: its starting text;
  /// the words of one of [options] start it on that option, taken.
  final String? labelText, hintText, helperText, initialValue;

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
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
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
      )
      ..add(ObjectFlagProperty<RawOptionSearch<T>>.has('search', search))
      ..add(
        DiagnosticsProperty<Duration>(
          'debounceDuration',
          debounceDuration,
          defaultValue: null,
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

  /// The option last taken, while the field still holds its words: the list shows it chosen and offers every option
  /// (ui_core's combobox does, for its value). An [ComicCombobox.initialValue] that is an option's words starts on it.
  late T? _taken = widget.options
      .where((option) => _words(option) == widget.initialValue)
      .firstOrNull;

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
    RawCombobox<T>(
      controller: _text,
      focusNode: widget.focusNode,
      search: widget.search ?? _search,
      debounceDuration: widget.debounceDuration,
      displayStringForOption: _words,
      // The option taken: an opened list starts on it.
      value: _taken,
      isOptionEnabled: widget.isOptionEnabled,
      // The pointer's row and the keys' wear the same dots: one place, the pointer moving it, so two rows never read
      // as two current options.
      highlightFollowsPointer: true,
      onSelected: _take,
      semanticLabel: widget.labelText,
      fieldBuilder: (context, field) => ComicListOpen(
        open: field.isOpen,
        child: ComicTextField(
          controller: field.controller,
          focusNode: field.focusNode,
          autofocus: widget.autofocus,
          labelText: widget.labelText,
          hintText: widget.hintText,
          helperText: widget.helperText,
          // It ends in the select's chevron, pointing up while the list shows: the field opens a list as a select
          // does.
          trailing: Icon(
            field.isOpen ? ComicGlyphs.chevronUp : ComicGlyphs.chevronDown,
          ),
          // Enter takes the highlighted option and the field keeps the focus, as a combobox's does: Flutter's own
          // finish to a done action would drop it. The take runs here, with no onSubmitted: a field told of a submit
          // that keeps its focus has its text input restarted, and in a browser the restarted input takes no typing.
          onEditingComplete: field.submit,
        ),
      ),
      // Its options' words start on the field's words. The kit marks the value selected; Comic prints the chosen option yellow and checked while the field holds its
      // words, so the face takes the keys' and the pointer's states alone.
      optionBuilder: (context, option, states) => ComicMenuRowFace(
        states: states.difference(const {WidgetState.selected}),
        label: _words(option),
        checked: _chosen(option),
        start: comicFieldListWords(ComicTheme.of(context), widget.style),
      ),
      // The list starts on the field's face, which the focus lifts toward the start.
      // Two panels, a gutter of paper between them: the list stands a plate's depth clear of the focused field's
      // print, which it touched, the two prints doubling at the end and notching the corner.
      surfaceBuilder: (_, list) => comicListOnLiftedField(
        context,
        Padding(
          padding: EdgeInsets.only(
            // Opened below: the field's print, then a plate's depth of paper.
            top:
                ComicTheme.of(context).focus.width +
                comicRaisedPlate * ComicTheme.of(context).depth,
            // Opened above: the list's own print, a plate's depth of paper, then the field's lift.
            bottom:
                (2 * comicRaisedPlate + comicFocusLift) *
                ComicTheme.of(context).depth,
          ),
          child: ComicRaisedFrame(style: widget.style, child: list),
        ),
      ),
      emptyBuilder: (context) => comicSearchNote(
        context,
        RawWidgetsLocalizations.of(context).noResultsLabel,
        widget.style,
      ),
      // The search's states, when an app searches (Comic's own match over the options never waits).
      loadingBuilder: widget.search == null
          ? null
          : (context) => comicSearchNote(
              context,
              RawWidgetsLocalizations.of(context).loadingLabel,
              widget.style,
            ),
      errorBuilder: widget.search == null
          ? null
          : (context, failure) =>
                comicSearchFailed(context, failure, widget.style),
    ),
  );
}

/// A line in a field's list that is no option, in the secondary ink where the options' words start: nothing matches,
/// a search is looking, or it failed.
Widget comicSearchNote(
  BuildContext context,
  String words, [
  ComicStyle? style,
]) {
  final t = ComicTheme.of(context);
  return SizedBox(
    width: double.infinity,
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: comicFieldListWords(t, style),
        vertical: 10,
      ),
      child: Text(
        words,
        style: t.type.body.copyWith(color: t.colors.textSecondary),
      ),
    ),
  );
}

/// A field's list after its search threw ([failure]): that it failed, and Try again as a menu row, lit while the keys
/// are on it or the pointer is over it.
Widget comicSearchFailed(
  BuildContext context,
  RawSearchError failure, [
  ComicStyle? style,
]) {
  final words = RawWidgetsLocalizations.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // The list's own node says it as it appears.
      ExcludeSemantics(
        child: comicSearchNote(context, words.searchFailedMessage, style),
      ),
      RawButton(
        onPressed: failure.retry,
        semanticLabel: words.retryButtonLabel,
        builder: (context, states, _) => ComicMenuRowFace(
          states: {
            if (failure.focused || states.contains(WidgetState.hovered))
              WidgetState.focused,
          },
          label: words.retryButtonLabel,
          start: comicFieldListWords(ComicTheme.of(context), style),
        ),
      ),
    ],
  );
}

/// The page behind a modal, screened back in Ben-Day dots of [ink]: the dots cover as much of the page as [ink]'s alpha
/// would darken it (0x40, a quarter), so the page recedes while its colours between the dots stay its own. The dots
/// swell in with the route and shrink away with it.
///
/// By day the dots only darken what lies under them, so a dot that lands on a letter darker than it leaves it whole.
/// Under a night [ComicTheme] the page is first dimmed under an overprint of its own ground ink, as process inks
/// overprint, and the dots only lighten what lies under them: the page behind sits darker than the panel open over it,
/// and a dot that lands on dimmed lettering leaves it whole.
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

  /// The route progress, from a clear page to the full screen.
  final Animation<double> animation;

  /// The screen's ink: the dots print it solid, its alpha the share of the page they cover.
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final colors = ComicTheme.maybeOf(context)?.colors;
    final ground = colors != null && colors.brightness == Brightness.dark
        ? colors.background
        : null;
    // Staggered rows half a pitch apart put two dots in each pitch square: they cover 2 pi r^2 / pitch^2 of it.
    final full = comicScrimPitch * math.sqrt(ink.a / (2 * math.pi));
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => SizedBox.expand(
          child: CustomPaint(
            // The night's dots blend with the page under them: a cached picture of them alone would lose it.
            willChange: ground != null,
            painter: _ScrimPainter(
              ink.withValues(alpha: 1),
              ComicScreenGrid(
                comicScrimPitch,
                // The tone grows with the dots' area, so evenly with the route.
                full * math.sqrt(animation.value.clamp(0.0, 1.0)),
                dpr,
              ),
              ground?.withValues(
                alpha: _nightDim * animation.value.clamp(0.0, 1.0),
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

// How much of the night page the ground's overprint takes back.
const double _nightDim = .65;

class _ScrimPainter extends CustomPainter {
  const _ScrimPainter(this.ink, this.grid, [this.dim]);
  final Color ink;
  final ComicScreenGrid grid;

  // The night's overprint of the page's ground, under the dots; null by day.
  final Color? dim;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final dim = this.dim;
    if (dim == null) {
      if (grid.radius <= 0) return;
      // By day the dots only darken: where the page is darker than they are, on a letter, it stays as it is.
      canvas.saveLayer(rect, Paint()..blendMode = BlendMode.darken);
      grid.paint(canvas, rect, ink);
      canvas.restore();
      return;
    }
    canvas.drawRect(rect, Paint()..color = dim);
    if (grid.radius <= 0) return;
    // The dots only lighten: where the dimmed page is lighter than they are, on a letter, it stays as it is.
    canvas.saveLayer(rect, Paint()..blendMode = BlendMode.lighten);
    grid.paint(canvas, rect, ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.ink != ink ||
      old.dim != dim ||
      old.grid.radius != grid.radius ||
      old.grid.pitch != grid.pitch;
}

/// A modal route whose page behind is screened in Ben-Day dots (and, at night, dimmed under them): a [ComicScreenScrim]
/// of [screenInk] under its barrier, which still takes the presses. Give the route no barrier colour of its own.
///
/// ```dart
/// class IssueRoute<T> extends RawDialogRoute<T> with ComicScreenedRoute<T> { IssueRoute({required super.pageBuilder}) : super(barrierColor: null, barrierLabel: 'Close'); @override Color? get screenInk => const Color(0x99000000); }
/// ```
mixin ComicScreenedRoute<T> on ModalRoute<T> {
  /// The screen's ink; null leaves the page as it is.
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

/// The modal screen's dot pitch, and the dot radius of a screen a quarter of the page in ink, for artwork that
/// matches it.
const double comicScrimPitch = 6, comicScrimRadius = 1.25;

// The rule at a lit row's start, inside the row's outline.
class _LitRule extends CustomPainter {
  _LitRule(this.ink, this.outline, this.direction);

  final Color ink;
  final OutlinedBorder outline;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final whole = Offset.zero & size;
    final rule = direction == TextDirection.rtl
        ? Rect.fromLTRB(
            size.width - comicRaisedPlate,
            0,
            size.width,
            size.height,
          )
        : Rect.fromLTRB(0, 0, comicRaisedPlate, size.height);
    canvas
      ..save()
      ..clipPath(outline.getOuterPath(whole, textDirection: direction))
      ..drawRect(rule, Paint()..color = ink)
      ..restore();
  }

  @override
  bool shouldRepaint(_LitRule oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.outline != outline ||
      oldDelegate.direction != direction;
}
