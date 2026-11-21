// Popup surfaces share one route and overlay policy: a square window, captured
// theme and direction, keyboard dismissal, and instant motion by default.
import 'internal/marks.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'behavior.dart';
import 'component_themes.dart';
import 'acts.dart';
import 'localizations.dart';
import 'layout.dart';
import 'press.dart';
import 'theme.dart';
import 'shapes.dart';
import 'tone.dart';
import 'internal/face.dart';
import 'internal/caps.dart';
import 'tokens.dart';
import 'internal/parts.dart' show RetroDesktopLastInput, retroDesktopHeldGround;
import 'glyphs.dart' show RetroDesktopGlyphs;
import 'internal/modal.dart';
import 'internal/actions.dart';
import 'frames.dart' show retroDesktopTitleBar, retroDesktopWindowFrame;

class _WordsDelegate extends LocalizationsDelegate<RetroDesktopLocalizations> {
  const _WordsDelegate(this.words);
  final RetroDesktopLocalizations words;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<RetroDesktopLocalizations> load(Locale locale) =>
      SynchronousFuture(words);
  @override
  bool shouldReload(_WordsDelegate old) => words != old.words;
}

class _SharedWordsDelegate
    extends LocalizationsDelegate<RawWidgetsLocalizations> {
  const _SharedWordsDelegate(this.words);
  final RawWidgetsLocalizations words;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<RawWidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(words);
  @override
  bool shouldReload(_SharedWordsDelegate old) => words != old.words;
}

class _Carried {
  _Carried(BuildContext context, BuildContext destination)
    : theme = RetroDesktopTheme.of(context)
          .copyWith(colors: RetroDesktopTheme.of(context).page),
      motion = RetroDesktopMotion.of(context),
      direction = Directionality.of(context),
      words = RetroDesktopLocalizations.of(context),
      shared = RawWidgetsLocalizations.of(context),
      locale = Localizations.maybeLocaleOf(context) ?? const Locale('en'),
      media = MediaQuery.of(context),
      scroll = ScrollConfiguration.of(context),
      themes = InheritedTheme.capture(from: context, to: destination);
  final RetroDesktopThemeData theme;
  final RetroDesktopMotion motion;
  final TextDirection direction;
  final RetroDesktopLocalizations words;
  final RawWidgetsLocalizations shared;
  final Locale locale;
  final MediaQueryData media;
  final ScrollBehavior scroll;
  final CapturedThemes themes;

  Widget wrap(Widget child) => Builder(
    builder: (context) => MediaQuery(
      // Keep overlay geometry live while carrying local accessibility choices.
      data: MediaQuery.of(context).copyWith(
        textScaler: media.textScaler,
        disableAnimations: media.disableAnimations,
        accessibleNavigation: media.accessibleNavigation,
        boldText: media.boldText,
        highContrast: media.highContrast,
        invertColors: media.invertColors,
        alwaysUse24HourFormat: media.alwaysUse24HourFormat,
        onOffSwitchLabels: media.onOffSwitchLabels,
      ),
      child: themes.wrap(
        ScrollConfiguration(
          behavior: scroll,
          child: Directionality(
            textDirection: direction,
            child: RetroDesktopTheme(
              data: theme,
              child: Builder(
                builder: (context) => Localizations.override(
                  context: context,
                  locale: locale,
                  delegates: [
                    _WordsDelegate(words),
                    _SharedWordsDelegate(shared),
                  ],
                  child: Directionality(textDirection: direction, child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _EscapeLayer {
  _EscapeLayer(this.close, {this.active}) {
    if (_layers.isEmpty) FocusManager.instance.addEarlyKeyEventHandler(_key);
    _layers.add(this);
  }
  final VoidCallback close;
  final bool Function()? active;
  static final List<_EscapeLayer> _layers = [];
  static KeyEventResult _key(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    for (final layer in _layers.reversed.toList()) {
      if (layer.active?.call() ?? true) {
        layer.close();
        // Stop the enclosing route's DismissIntent from handling the same key.
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void dispose() {
    _layers.remove(this);
    if (_layers.isEmpty) FocusManager.instance.removeEarlyKeyEventHandler(_key);
  }
}

mixin _EscapeCloses<T> on PopupRoute<T> {
  bool get escapeDismissible => barrierDismissible;
  late final _EscapeLayer _escape;
  @override
  void install() {
    super.install();
    _escape = _EscapeLayer(() {
      if (escapeDismissible) navigator?.maybePop();
    }, active: () => isCurrent);
  }

  @override
  void dispose() {
    _escape.dispose();
    super.dispose();
  }
}

// The look's menus and its bottom sheet: timed by the theme's raise and leave (zero, at once).
class _RaisedRoute<T> extends PopupRoute<T>
    with _EscapeCloses<T>, RetroDesktopModalRoute<T> {
  _RaisedRoute({
    required this.carried,
    required this.builder,
    required this.dismissible,
    required this.escapeDismissible,
    required this.label,
    this.sheet = false,
    this.modal = true,
  }) : super(
         requestFocus: true,
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
       );
  final _Carried carried;
  final WidgetBuilder builder;
  final bool dismissible, sheet;

  /// A window that takes the front from the one under it (an alert, a dialog, a sheet); a menu leaves it active.
  final bool modal;
  @override
  bool get listsAsModal => modal;
  @override
  final bool escapeDismissible;
  final String label;
  CurvedAnimation? _curve;
  @override
  void dispose() {
    _curve?.dispose();
    super.dispose();
  }

  @override
  bool get barrierDismissible => dismissible;
  @override
  String get barrierLabel => label;
  // Nothing behind a window is dimmed: no window of the period dimmed the
  // desktop. The window in front is the active one and blocks the rest.
  @override
  Color? get barrierColor => null;
  @override
  Duration get transitionDuration => carried.motion.raise;
  @override
  Duration get reverseTransitionDuration => carried.motion.leave;
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => carried.wrap(FocusTraversalGroup(child: Builder(builder: builder)));
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final eased = _curve ??= CurvedAnimation(
      parent: animation,
      curve: carried.motion.enter,
      reverseCurve: carried.motion.exit,
    );
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, sheet ? .15 : .02),
          end: Offset.zero,
        ).animate(eased),
        child: child,
      ),
    );
  }
}

// A dialog the look raises (showRetroDesktopDialog), on ui_core's DesignDialogRoute: its focus taken and given back,
// Tab kept inside, a screen reader's dialog. It stands at once while the theme's raise is zero (the default and Reduce
// Motion), else fades and rises its 2 % on ui_core's spring within that time. Nothing behind it is dimmed; Escape
// closes it when [escapeDismissible] says so, apart from a press outside ([barrierDismissible]).
class _RaisedDialogRoute<T> extends DesignDialogRoute<T>
    with
        _EscapeCloses<T>,
        RetroDesktopModalRoute<T>,
        RetroDesktopRouteStill<T> {
  _RaisedDialogRoute({
    required _Carried carried,
    required WidgetBuilder builder,
    required super.barrierDismissible,
    required this.escapeDismissible,
    required super.barrierLabel,
  }) : retroDesktopTime = carried.motion.raise,
       super(
         barrierColor: const Color(0x00000000),
         stiffness: retroDesktopRouteStiffness(carried.motion.raise),
         builder: (context, details) {
           final page = carried.wrap(
             FocusTraversalGroup(child: Builder(builder: builder)),
           );
           if (carried.motion.raise == Duration.zero) return page;
           return FadeTransition(
             opacity: details.animation,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: const Offset(0, .02),
                 end: Offset.zero,
               ).animate(details.animation),
               child: page,
             ),
           );
         },
       );

  @override
  final Duration retroDesktopTime;

  @override
  final bool escapeDismissible;
}

// Whether [context] stands in a window the look raised on its own (a dialog, a bottom sheet), not one a page draws.
bool _inRaisedWindow(BuildContext context) => switch (ModalRoute.of(context)) {
  _RaisedRoute() || _RaisedDialogRoute() => true,
  _ => false,
};

Future<T?> _show<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool root = true,
  bool dismissible = true,
  bool? escapeDismissible,
  bool sheet = false,
  bool modal = true,
  String? label,
}) async {
  final navigator = Navigator.of(context, rootNavigator: root);
  final focus = FocusManager.instance.primaryFocus;
  final carried = _Carried(context, navigator.context);
  final RetroDesktopModalRoute<T> route = modal && !sheet
      ? _RaisedDialogRoute<T>(
          carried: carried,
          builder: builder,
          barrierDismissible: dismissible,
          escapeDismissible: escapeDismissible ?? dismissible,
          barrierLabel: label ?? carried.shared.closeButtonLabel,
        )
      : _RaisedRoute<T>(
          carried: carried,
          builder: builder,
          dismissible: dismissible,
          escapeDismissible: escapeDismissible ?? dismissible,
          sheet: sheet,
          modal: modal,
          label: label ?? carried.shared.closeButtonLabel,
        );
  try {
    return await navigator.push<T>(route);
  } finally {
    // A menu an alert closed leaves the focus in the alert.
    if (!route.closedByModal &&
        focus?.context != null &&
        focus!.canRequestFocus) {
      focus.requestFocus();
    }
  }
}

class _RaisedSurface extends StatelessWidget {
  const _RaisedSurface({
    required this.child,
    required this.componentTheme,
    this.style,
    this.padding = const EdgeInsets.all(RetroDesktopSpacing.s16),
    this.scale = RetroDesktopFaceScale.surface,
    this.atFoot = false,
  });
  final Widget child;
  final RetroDesktopStyle componentTheme;
  final RetroDesktopStyle? style;
  final EdgeInsetsGeometry padding;
  final RetroDesktopFaceScale scale;

  /// Set on the screen's foot: square bottom corners unless a theme or
  /// style names the shape.
  final bool atFoot;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return retroDesktopFace(
      shadows: [
        BoxShadow(
          color: t.colors.shade.withValues(alpha: t.colors.dark ? .95 : .8),
          offset: const Offset(2, 2),
        ),
      ],
      states: const {},
      component: componentTheme.over(
        RetroDesktopStyle(
          fill: WidgetStatePropertyAll(t.colors.platinum),
          shape: atFoot
              ? WidgetStatePropertyAll(
                  RetroDesktopShapes.topOnly(
                    t.shapes.large,
                    textDirection: Directionality.of(context),
                  ),
                )
              : null,
        ),
      ),
      style: style,
      padding: padding,
      scale: scale,
      child: child,
    );
  }
}

// A window centred in its room, as Center stands it, but its top at least [least] down: below the menu bar. A window
// taller than what is left below it gets that much, and scrolls.
class _BelowBar extends SingleChildLayoutDelegate {
  const _BelowBar(this.least);
  final double least;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: constraints.maxWidth,
        maxHeight: math.max(0.0, constraints.maxHeight - least),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
    (size.width - childSize.width) / 2,
    math.max((size.height - childSize.height) / 2, least),
  );

  @override
  bool shouldRelayout(_BelowBar oldDelegate) => oldDelegate.least != least;
}

/// Opens a dialog, returning the value supplied to Navigator.pop.
/// [escapeDismissible] defaults to [barrierDismissible]; set it independently
/// when the keyboard may dismiss a dialog a press outside cannot.
Future<T?> showRetroDesktopDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool? escapeDismissible,
  bool useRootNavigator = true,
  String? closeLabel,
}) => _show<T>(
  context,
  builder,
  root: useRootNavigator,
  dismissible: barrierDismissible,
  escapeDismissible: escapeDismissible,
  label: closeLabel,
);

/// A dialog window in the family's window shape with a title, message, arbitrary content and actions.
///
/// ```dart
/// RetroDesktopDialog(title: 'Save changes?', message: 'Your document has changed.', actions: [RetroDesktopDialogAction('Save', value: true, isDefaultAction: true)])
/// ```
class RetroDesktopDialog extends StatelessWidget {
  /// Creates a [RetroDesktopDialog].
  const RetroDesktopDialog({
    super.key,
    required this.title,
    this.message,
    this.content = const [],
    this.actions = const [],
    this.tone,
    this.style,
  });

  /// The heading displayed above the content.
  final String title;

  /// The message displayed to the user.
  final String? message;

  /// What kind of alert this is, drawn at its start as the period's alert boxes were: the note, the caution
  /// triangle or the stop sign. Null draws no picture, for a dialog that asks for input rather than warns.
  final RetroDesktopTone? tone;

  /// The content displayed inside the raised surface.
  final List<Widget> content;

  /// The actions displayed after the content, in reading order, the default one last. They stand in one row at the
  /// trailing end; when they don't fit (long words on a phone, large text), in one column at the trailing end, each as
  /// wide as the widest, the default one on top.
  final List<Widget> actions;

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    // Where the window's room starts down the screen (its route stands on the whole screen): it stands centred in that
    // room, but never over the menu bar (at twice the text size on a phone, a tall alert cut the bar's last row).
    // Only a window raised on its own (showRetroDesktopDialog): one written into a page stands where the page puts it.
    final raised = _inRaisedWindow(context);
    final top =
        MediaQuery.paddingOf(context).top +
        MediaQuery.viewInsetsOf(context).top +
        RetroDesktopSpacing.s20;
    return SafeArea(
      child: Padding(
        padding:
            MediaQuery.viewInsetsOf(context) +
            const EdgeInsets.all(RetroDesktopSpacing.s20),
        child: ValueListenableBuilder<double>(
          valueListenable: retroDesktopBarFoot,
          // One kind of parent for the window's life, so a bar that moves keeps its focus and scroll.
          builder: (context, foot, window) => raised
              ? CustomSingleChildLayout(
                  delegate: _BelowBar(
                    foot > 0
                        ? math.max(0.0, foot + RetroDesktopSpacing.s8 - top)
                        : 0.0,
                  ),
                  child: window,
                )
              : Center(child: window),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            // A window taller than the screen (twice the text size on a phone) scrolls whole, its frame with it, as a
            // page does: scrolled inside its frame, its buttons' row stood off its own line in a short window.
            child: SingleChildScrollView(
              child: Semantics(
                scopesRoute: true,
                explicitChildNodes: true,
                child: _RaisedSurface(
                  componentTheme: t.dialogTheme,
                  scale: RetroDesktopFaceScale.window,
                  style: style,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // The alert picture stands beside the words, as the
                          // period's alert boxes had it; in a window too narrow
                          // for both side by side it stands above them.
                          LayoutBuilder(
                            builder: (context, box) {
                              final words = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Semantics(
                                    // Its own node: never merged with a
                                    // neighbour's label.
                                    container: true,
                                    header: true,
                                    namesRoute: true,
                                    child: retroDesktopWholeWords(
                                      title,
                                      t.type.head,
                                      Text(title, style: t.type.head),
                                    ),
                                  ),
                                  if (message != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: RetroDesktopSpacing.s12,
                                      ),
                                      child: Text(message!),
                                    ),
                                ],
                              );
                              if (tone == null) return words;
                              final art = retroDesktopAlertArt(t, tone!);
                              if (box.maxWidth < 200) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    art,
                                    const SizedBox(
                                      height: RetroDesktopSpacing.s12,
                                    ),
                                    words,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  art,
                                  const SizedBox(
                                    width: RetroDesktopSpacing.s16,
                                  ),
                                  Expanded(child: words),
                                ],
                              );
                            },
                          ),
                          for (final item in content)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: RetroDesktopSpacing.s12,
                              ),
                              child: item,
                            ),
                        ],
                      ),
                      if (actions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: RetroDesktopSpacing.s16,
                          ),
                          child: RetroDesktopActionBar(
                            spacing: RetroDesktopSpacing.s8,
                            children: actions,
                          ),
                        ),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('message', message, defaultValue: null))
      ..add(EnumProperty<RetroDesktopTone>('tone', tone, defaultValue: null))
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

/// Opens a bottom sheet; on a desk the same panel opens as a window a third of
/// the way down the display, as an alert does.
/// [escapeDismissible] defaults to [barrierDismissible] and may be overridden
/// independently when only presses outside must be ignored.
Future<T?> showRetroDesktopBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool? escapeDismissible,
  bool useRootNavigator = true,
  String? closeLabel,
}) => _show<T>(
  context,
  builder,
  root: useRootNavigator,
  dismissible: barrierDismissible,
  escapeDismissible: escapeDismissible,
  sheet: true,
  label: closeLabel,
);

/// A scrollable sheet window: its title bar carries [title] and the close box, as a side sheet's does; raised with
/// [showRetroDesktopBottomSheet] and given a [title] but no [onClose], its close box closes it. Given neither, it is
/// a raised panel without a title bar, as an action sheet is, its own choices its way out.
///
/// ```dart
/// RetroDesktopBottomSheet(title: 'Details', child: const Text('Document details'))
/// ```
class RetroDesktopBottomSheet extends StatelessWidget {
  /// Creates a [RetroDesktopBottomSheet].
  const RetroDesktopBottomSheet({
    super.key,
    this.title,
    this.child,
    this.slivers,
    this.controller,
    this.actions = const [],
    this.onClose,
    this.closeLabel,
    this.inPlace = false,
    this.style,
  }) : assert(
         (child == null) != (slivers == null),
         'Provide child or slivers.',
       );

  /// The heading displayed above the content.
  final String? title;

  /// Overrides the accessible name of the close action.
  final String? closeLabel;

  /// The widget displayed inside this part.
  final Widget? child;

  /// Scrollable slivers displayed inside the sheet.
  final List<Widget>? slivers;

  /// {@macro retro_desktop.controller}
  final ScrollController? controller;

  /// The actions displayed after the content.
  final List<Widget> actions;

  /// Called when the close action is activated.
  final VoidCallback? onClose;

  /// An external presenter owns the height, keyboard and safe-area insets.
  final bool inPlace;

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final media = MediaQuery.of(context);
    // Raised, a sheet with a title always has a way to close it that shows: given no onClose, its close box closes
    // its route. Built anywhere else (a page that draws it), it has no route of its own to close; untitled (an action
    // sheet), it is a panel whose own choices, Cancel among them, are its way out.
    final close =
        onClose ??
        (title != null && !inPlace && _inRaisedWindow(context)
            ? () => Navigator.maybePop(context)
            : null);
    // A sheet with a title or a close is a window, as the side sheet is, at every width: its title bar carries both,
    // the close box at its start and the stripes while it is the front window. One with neither (an action sheet
    // shown in place) is a raised panel, its own choices its way out.
    final framed = title != null || close != null;

    // A sheet's actions stand as a dialog's do: at the trailing end, in
    // reading order, the confirming one last; stacked when they don't fit.
    final footer = Padding(
      padding: const EdgeInsets.only(top: RetroDesktopSpacing.s16),
      child: RetroDesktopActionBar(
        spacing: RetroDesktopSpacing.s8,
        children: actions,
      ),
    );
    final bodySlivers = slivers ?? [SliverToBoxAdapter(child: child)];
    // On a desk a sheet opens as a window in the alert's place, a third of the
    // way down the display, framed all round: docked to the display's foot it
    // stood over its own button with its shadow off screen.
    final floating = !inPlace && t.desk;
    final inner = LayoutBuilder(
      builder: (context, room) {
        // Placed in a scrolling page (a kit screen's body), the sheet has
        // no height to fill: it takes its content's, and the page scrolls.
        final bounded = room.hasBoundedHeight;
        // A narrow action can be taller than the sheet itself.
        // Keep every part reachable in one scroll view in that case.
        if (room.maxWidth < 240) {
          return CustomScrollView(
            controller: controller,
            shrinkWrap: !inPlace || !bounded,
            slivers: [
              ...bodySlivers,
              if (actions.isNotEmpty) SliverToBoxAdapter(child: footer),
            ],
          );
        }
        return _SheetLayout(
          room: room,
          inPlace: inPlace,
          controller: controller,
          heading: null,
          flowHeading: null,
          bodySlivers: bodySlivers,
          // A list's footer (a composer) stays where the hand is; only a
          // single body, a form or a page, may scroll with its ends.
          mayFlow: slivers == null,
          footer: actions.isNotEmpty ? footer : null,
        );
      },
    );
    final panel = Semantics(
      scopesRoute: !inPlace,
      explicitChildNodes: !inPlace,
      namesRoute: !inPlace,
      label: inPlace ? null : title,
      child: _RaisedSurface(
        componentTheme: t.sheetTheme,
        scale: RetroDesktopFaceScale.window,
        // A sheet at the foot stands on the foot: on a phone across it, from
        // 600 up a column of at most 560 in its middle.
        atFoot: !floating,
        style: style,
        padding: framed
            ? retroDesktopWindowFrame(t)
            : const EdgeInsets.all(RetroDesktopSpacing.s16),
        child: !framed
            ? inner
            : LayoutBuilder(
                builder: (context, room) {
                  final bar = retroDesktopTitleBar(
                    title: title ?? '',
                    onClose: close,
                    closeLabel: closeLabel,
                  );
                  // Where the body is narrow, the title wraps tall beside the boxes: the bar scrolls with the body
                  // and the actions, as one, so it never pushes them out of reach.
                  if (room.maxWidth - 2 * RetroDesktopSpacing.s12 < 240) {
                    return CustomScrollView(
                      controller: controller,
                      shrinkWrap: !inPlace || !room.hasBoundedHeight,
                      slivers: [
                        SliverToBoxAdapter(child: bar),
                        SliverPadding(
                          padding: const EdgeInsets.all(
                            RetroDesktopSpacing.s12,
                          ),
                          sliver: SliverMainAxisGroup(
                            slivers: [
                              ...bodySlivers,
                              if (actions.isNotEmpty)
                                SliverToBoxAdapter(child: footer),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  // The title bar at its own height; the body, 12 in as a window's, takes what is left.
                  final body = Padding(
                    padding: const EdgeInsets.all(RetroDesktopSpacing.s12),
                    child: inner,
                  );
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      bar,
                      if (room.hasBoundedHeight)
                        Flexible(child: body)
                      else
                        body,
                    ],
                  );
                },
              ),
      ),
    );
    if (inPlace) return panel;
    return SafeArea(
      child: Padding(
        padding: floating
            ? EdgeInsets.fromLTRB(
                RetroDesktopSpacing.s16,
                RetroDesktopSpacing.s16,
                RetroDesktopSpacing.s16,
                16 + media.viewInsets.bottom,
              )
            : EdgeInsets.only(bottom: media.viewInsets.bottom),
        // On whole pixels: a third of the way down fell between two, and the sheet's hard shadow drew a half-toned
        // row at its foot.
        // (In an unbounded column, such as a page that shows it in place, it sits as an Align would.)
        child: _WholeAligned(
          floating ? const Alignment(0, -1 / 3) : Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: math.max(
                0,
                media.size.height * .9 - media.viewInsets.bottom,
              ),
            ),
            child: panel,
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
      ..add(StringProperty('closeLabel', closeLabel, defaultValue: null))
      ..add(IterableProperty<Widget>('slivers', slivers, defaultValue: null))
      ..add(
        DiagnosticsProperty<ScrollController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onClose', onClose))
      ..add(FlagProperty('inPlace', value: inPlace, ifTrue: 'inPlace'))
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

// Aligns its child as an Align does, on whole logical pixels where its room is bounded.
class _WholeAligned extends StatelessWidget {
  const _WholeAligned(this.alignment, {required this.child});
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => box.hasBoundedWidth && box.hasBoundedHeight
        ? CustomSingleChildLayout(
            delegate: _WholeAlign(alignment),
            child: child,
          )
        : Align(alignment: alignment, child: child),
  );
}

class _WholeAlign extends SingleChildLayoutDelegate {
  const _WholeAlign(this.alignment);
  final Alignment alignment;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final at = alignment.alongOffset(
      Offset(size.width - childSize.width, size.height - childSize.height),
    );
    return Offset(at.dx.roundToDouble(), at.dy.roundToDouble());
  }

  @override
  bool shouldRelayout(_WholeAlign oldDelegate) =>
      oldDelegate.alignment != alignment;
}

/// A sheet's heading, body and footer: the heading and footer pinned and the
/// body scrolling between them. A single body ([mayFlow]: a form, a page)
/// that they would leave under a third of the sheet (large type, a short
/// screen) scrolls with them as one, so it is never squeezed to a slit; a
/// list keeps its footer (a composer) pinned.
class _SheetLayout extends StatefulWidget {
  const _SheetLayout({
    required this.room,
    required this.inPlace,
    required this.controller,
    required this.heading,
    required this.flowHeading,
    required this.bodySlivers,
    required this.footer,
    required this.mayFlow,
  });

  final BoxConstraints room;
  final bool inPlace, mayFlow;
  final ScrollController? controller;
  final Widget? heading, flowHeading, footer;
  final List<Widget> bodySlivers;

  @override
  State<_SheetLayout> createState() => _SheetLayoutState();
}

class _SheetLayoutState extends State<_SheetLayout> {
  bool _flow = false;
  double _pinned = 0;
  bool _checking = false;

  @override
  void didUpdateWidget(_SheetLayout old) {
    super.didUpdateWidget(old);
    // A new room (a turned screen, the keyboard) measures afresh, pinned.
    if (old.room != widget.room) _flow = false;
  }

  void _measured(double pinned) {
    _pinned = pinned;
    if (_flow || _checking || !widget.mayFlow) return;
    _checking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checking = false;
      if (!mounted || _flow) return;
      final height = widget.room.maxHeight;
      if (height - _pinned < height / 3) setState(() => _flow = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bounded = widget.room.hasBoundedHeight;
    final heading = widget.heading == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: RetroDesktopSpacing.s12),
            child: widget.heading,
          );
    final footer = widget.footer;
    if (_flow) {
      return CustomScrollView(
        controller: widget.controller,
        shrinkWrap: !widget.inPlace,
        slivers: [
          if (widget.flowHeading case final flowHeading?)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: RetroDesktopSpacing.s12),
                child: flowHeading,
              ),
            ),
          ...widget.bodySlivers,
          if (footer != null) SliverToBoxAdapter(child: footer),
        ],
      );
    }
    final body = CustomScrollView(
      controller: widget.controller,
      shrinkWrap: !widget.inPlace || !bounded,
      slivers: widget.bodySlivers,
    );
    if (!bounded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [?heading, body, ?footer],
      );
    }
    return _Pinned(
      fill: widget.inPlace,
      onPinned: _measured,
      children: [
        heading ?? const SizedBox.shrink(),
        body,
        footer ?? const SizedBox.shrink(),
      ],
    );
  }
}

/// A heading, a body and a footer, the heading and footer at their own height
/// and the body taking what they leave (all of it where [fill], else up to
/// it); never an overflow: past the room it clips. Tells [onPinned] the
/// heading's and footer's height after each layout.
class _Pinned extends MultiChildRenderObjectWidget {
  const _Pinned({
    required this.fill,
    required this.onPinned,
    required super.children,
  });

  final bool fill;
  final ValueChanged<double> onPinned;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPinned(fill, onPinned: onPinned);

  @override
  void updateRenderObject(BuildContext context, _RenderPinned renderObject) {
    renderObject
      ..fill = fill
      ..onPinned = onPinned;
  }
}

class _PinnedParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderPinned extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PinnedParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PinnedParentData> {
  _RenderPinned(this._fill, {required this.onPinned});

  bool _fill;
  set fill(bool value) {
    if (_fill == value) return;
    _fill = value;
    markNeedsLayout();
  }

  ValueChanged<double> onPinned;
  bool _clipped = false;

  // The least of its body a short sheet shows: a finger's line.
  static const double _bodyLine = 48;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _PinnedParentData) {
      child.parentData = _PinnedParentData();
    }
  }

  @override
  void performLayout() {
    final heading = firstChild!;
    final body = childAfter(heading)!;
    final footer = childAfter(body)!;
    final width = constraints.maxWidth;
    final across = BoxConstraints(minWidth: width, maxWidth: width);
    heading.layout(across, parentUsesSize: true);
    footer.layout(across, parentUsesSize: true);
    final pinned = heading.size.height + footer.size.height;
    final room = constraints.maxHeight;
    // A sheet shorter than its ends and a line (opening, or a short screen with the keyboard up) keeps a finger's line of
    // its body: the heading gives way at the top, and the footer stays where the hand is.
    final rest = room.isFinite ? math.max(_bodyLine, room - pinned) : room;
    body.layout(
      _fill
          ? BoxConstraints.tightFor(width: width, height: rest)
          : across.copyWith(maxHeight: rest),
      parentUsesSize: true,
    );
    final whole = pinned + body.size.height;
    final gives = room.isFinite && whole > room
        ? math.min(whole - room, heading.size.height)
        : 0.0;
    (heading.parentData! as _PinnedParentData).offset = Offset(0, -gives);
    (body.parentData! as _PinnedParentData).offset = Offset(
      0,
      heading.size.height - gives,
    );
    (footer.parentData! as _PinnedParentData).offset = Offset(
      0,
      heading.size.height - gives + body.size.height,
    );
    size = constraints.constrain(Size(width, _fill ? room : whole - gives));
    _clipped = gives > 0 || whole - gives > size.height;
    onPinned(pinned);
  }

  final _clip = LayerHandle<ClipRectLayer>();

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_clipped) {
      _clip.layer = null;
      defaultPaint(context, offset);
      return;
    }
    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      defaultPaint,
      oldLayer: _clip.layer,
    );
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A value-bearing menu row. Disabled rows remain visible but cannot be chosen.
@immutable
class RetroDesktopMenuItem<T> {
  /// Creates a [RetroDesktopMenuItem].
  const RetroDesktopMenuItem(
    this.value,
    this.label, {
    this.icon,
    this.enabled = true,
    this.selected = false,
  });

  /// The current value to display or edit.
  final T value;

  /// The visible or accessible name of this part.
  final String label;

  /// The glyph shown with the content.
  final IconData? icon;

  /// Whether the part accepts user interaction.
  final bool enabled;

  /// Whether the part represents the current selection.
  final bool selected;
}

/// A keyboard menu: arrows skip disabled rows, Home and End reach its ends.
///
/// ```dart
/// RetroDesktopMenu(label: 'Document actions', items: const [RetroDesktopMenuItem('open', 'Open'), RetroDesktopMenuItem('rename', 'Rename')], onSelected: (_) {})
/// ```
class RetroDesktopMenu<T> extends StatefulWidget {
  /// Creates a [RetroDesktopMenu].
  const RetroDesktopMenu({
    super.key,
    required this.items,
    this.onSelected,
    this.label,
    this.style,
  });

  /// The items displayed in their supplied order.
  final List<RetroDesktopMenuItem<T>> items;

  /// Reports the selected menu value.
  final ValueChanged<T>? onSelected;

  /// The visible or accessible name of this part.
  final String? label;

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;
  @override
  State<RetroDesktopMenu<T>> createState() => _MenuState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RetroDesktopMenuItem<T>>('items', items))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

class _MenuState<T> extends State<RetroDesktopMenu<T>> {
  final List<FocusNode> _nodes = [];

  // Whether the keyboard is on one of the rows: then its row is the lit one.
  bool _focusInside = false;

  // Whether the keyboard drives the menu: opened from it, or a key has moved
  // in it since. Otherwise the focused first row stays unlit (lit read as
  // chosen), and the row under the pointer is lit, or the chosen one.
  bool _keyed = false;

  // Whether the pointer is over the rows.
  bool _pointerInside = false;

  // The row the pointer last lit, if it has lit one since the menu opened.
  int? _pointed;

  // The pointer moved over row [i]: it takes the lit row from the keys, and the keys' place, so they go on from it.
  // One current row, as the period's menus had: the pointer resting on one row while the keys lit another lit both.
  void _point(int i) {
    if (!widget.items[i].enabled) return;
    if (_keyed || _pointed != i || !_pointerInside) {
      setState(() {
        _keyed = false;
        _pointed = i;
        _pointerInside = true;
      });
    }
    if (!_nodes[i].hasFocus) _nodes[i].requestFocus();
  }

  void _sync() {
    while (_nodes.length < widget.items.length) {
      _nodes.add(FocusNode());
    }
  }

  @override
  void initState() {
    super.initState();
    // Opened from the keyboard, it lights its focused row; by a click, the row under the pointer.
    _keyed = RetroDesktopLastInput.byKey;
    _sync();
  }

  @override
  void didUpdateWidget(covariant RetroDesktopMenu<T> old) {
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

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final enabled = [
      for (var i = 0; i < widget.items.length; i++)
        if (widget.items[i].enabled) i,
    ];
    if (enabled.isEmpty) return KeyEventResult.ignored;
    final current = enabled.indexWhere((i) => _nodes[i].hasFocus);
    final key = event.logicalKey;
    int? next;
    if (key == LogicalKeyboardKey.arrowDown) {
      next = (current + 1) % enabled.length;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      next = (current - 1 + enabled.length) % enabled.length;
    }
    if (key == LogicalKeyboardKey.home) next = 0;
    if (key == LogicalKeyboardKey.end) next = enabled.length - 1;
    if (next == null) return KeyEventResult.ignored;
    if (!_keyed) {
      // With no row lit yet, the first key lights the first row (or the last,
      // going up) rather than stepping past the unlit focused one; after the
      // pointer lit one, the keys go on from it.
      final lit =
          _pointed != null ||
          widget.items.any((item) => item.enabled && item.selected);
      if (!lit) {
        next =
            key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.end
            ? enabled.length - 1
            : 0;
      }
      setState(() => _keyed = true);
    }
    final target = _nodes[enabled[next]];
    target.requestFocus();
    final targetContext = target.context;
    if (targetContext != null) {
      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          duration: RetroDesktopMotion.of(context).move,
          curve: RetroDesktopMotion.of(context).standard,
        ),
      );
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final chosen = widget.items.indexWhere(
      (item) => item.enabled && item.selected,
    );
    // The menu opens on the chosen row, or on the first it can act on.
    final first = chosen >= 0
        ? chosen
        : widget.items.indexWhere((item) => item.enabled);
    // A field's list: its rows run from rim to rim, the classic list's bar,
    // and their words start where the field's do (the field's 8 px in).
    final field = _FieldList.of(context);
    // The lit row is the period's bar from rim to rim, square, in a menu as in
    // a field's list (inset 4 with rounded ends, it was a modern chip).
    const OutlinedBorder itemShape = RoundedRectangleBorder();
    // Rows without a glyph keep their words in line with those that have one.
    final glyphs = widget.items.any((item) => item.icon != null);
    // A list with a choice keeps a column at the rows' end for the chosen one's tick.
    final marks = widget.items.any((item) => item.selected);
    return Semantics(
      label: widget.label,
      child: _RaisedSurface(
        componentTheme: t.menuTheme,
        style: widget.style,
        padding: const EdgeInsets.symmetric(vertical: RetroDesktopSpacing.s4),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onKeyEvent: _key,
          onFocusChange: (inside) => setState(() => _focusInside = inside),
          child: MouseRegion(
            opaque: false,
            // Only the pointer's move takes the lit row from the keys (_point): a menu opened from the keys under a
            // resting pointer keeps its keys' row.
            onEnter: (_) => setState(() => _pointerInside = true),
            onExit: (_) => setState(() => _pointerInside = false),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.items.length; i++)
                    MouseRegion(
                      opaque: false,
                      onHover: (_) => _point(i),
                      child: RetroDesktopPressable(
                        focusShape: itemShape,
                        ringInside: true,
                        focusNode: _nodes[i],
                        autofocus: i == first,
                        label: widget.items[i].label,
                        selected: widget.items[i].selected,
                        onPressed:
                            widget.items[i].enabled && widget.onSelected != null
                            ? () => widget.onSelected!(widget.items[i].value)
                            : null,
                        // The keyboard's row is lit, as the period's menus lit it, and the lit row is the focus
                        // feedback: no ring round it. Driven by the pointer, the row under it is lit, or with
                        // the pointer off the rows the chosen one.
                        // Claimed from inside the press (a Builder's context, as
                        // the slider's thumb claims): from the builder's own
                        // context the claim missed, and the press drew its ring
                        // round the row too, hidden in the lit fill until a row
                        // stood focused and unlit.
                        builder: (context, states) => Builder(
                          builder: (context) {
                            RetroDesktopHighlightClaim.maybeOf(context)
                                ?.claim(context, states);
                            final chosen = widget.items[i].selected;
                            final lit = _keyed
                                ? states.contains(WidgetState.focused) ||
                                      (chosen && !_focusInside)
                                : _pointerInside
                                ? states.contains(WidgetState.hovered) &&
                                      widget.items[i].enabled
                                : chosen;
                            final ink = lit
                                ? t.colors.onHighlight
                                : t.colors.text;
                            // The chosen row, unlit, stands in the look's held well, as a chosen toggle does, its
                            // words on the list's line and its tick at the end: seen at a glance while the pointer
                            // or the keyboard lights another row in the highlight's bar, which no well resembles.
                            return retroDesktopHeldGround(
                              t,
                              held: chosen && !lit,
                              sink: false,
                              child: DecoratedBox(
                                decoration: ShapeDecoration(
                                  shape: itemShape,
                                  color: lit ? t.colors.highlight : null,
                                ),
                                // A menu's rows in the chrome's face, as its bar's
                                // titles and its button's words are; a field's list
                                // in the field's.
                                child: DefaultTextStyle.merge(
                                  style:
                                      (field
                                              ? const TextStyle()
                                              : t.type.chrome)
                                          .copyWith(
                                            color: lit
                                                ? t.colors.onHighlight
                                                : t.colors.text,
                                          ),
                                  child: Padding(
                                    // A field's words start 8 px in at its density.
                                    padding: field
                                        ? EdgeInsetsDirectional.fromSTEB(
                                            8 * t.density.horizontal,
                                            10,
                                            12,
                                            10,
                                          )
                                        : const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                    child: Row(
                                      children: [
                                        if (widget.items[i].icon != null) ...[
                                          Icon(
                                            widget.items[i].icon,
                                            size: 18,
                                            color: lit
                                                ? t.colors.onHighlight
                                                : t.colors.text,
                                          ),
                                          const SizedBox(
                                            width: RetroDesktopSpacing.s8,
                                          ),
                                        ] else if (glyphs)
                                          // The glyph column's room: a glyph (18) and its gap.
                                          const SizedBox(
                                            width: 18 + RetroDesktopSpacing.s8,
                                          ),
                                        Expanded(
                                          child: RetroDesktopCaps(
                                            Text(widget.items[i].label),
                                          ),
                                        ),
                                        if (marks)
                                          SizedBox(
                                            width: 20,
                                            child: chosen
                                                ? Align(
                                                    alignment:
                                                        AlignmentDirectional
                                                            .centerEnd,
                                                    child: Icon(
                                                      RetroDesktopGlyphs.check,
                                                      size: 14,
                                                      color: ink,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Marks a menu as a field's list (a select's), opened by showRetroDesktopMenu
// with matchWidth.
class _FieldList extends InheritedWidget {
  const _FieldList({required this.on, required super.child});
  final bool on;
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FieldList>()?.on ?? false;
  @override
  bool updateShouldNotify(_FieldList old) => on != old.on;
}

class _AnchorLayout extends SingleChildLayoutDelegate {
  const _AnchorLayout(
    this.anchor,
    this.direction, {
    this.width,
    this.least,
    this.tooltip = false,
  });
  final Rect anchor;
  final TextDirection direction;
  final double? width;
  // The least width, when the menu may grow past it to [width].
  final double? least;
  final bool tooltip;

  // A menu is never taller than this: a long list scrolls inside it, beside
  // its anchor, rather than running the screen's height.
  static const double tallest = 400;

  // The room beside the anchor, below it and above it, inside the screen's
  // 8 px margin and the 4 px gap.
  double _below(double height) => height - 8 - (anchor.bottom + 4);
  double _above() => anchor.top - 4 - 8;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final room = math.max(0.0, constraints.maxWidth - 16);
    final w = math.min(width ?? (tooltip ? 320 : 280), room);
    final screen = math.max(0.0, constraints.maxHeight - 16);
    // A menu fits the larger side of its anchor, so it opens beside it.
    final side = math.max(_below(constraints.maxHeight), _above());
    return BoxConstraints(
      minWidth: tooltip ? 0 : math.min(least ?? w, w),
      maxWidth: w,
      maxHeight: tooltip
          ? screen
          : math.max(0, math.min(tallest, math.min(screen, side))),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final left = tooltip
        ? anchor.center.dx - childSize.width / 2
        : direction == TextDirection.rtl
        ? anchor.right - childSize.width
        : anchor.left;
    // A menu hangs from its button, touching it; a tooltip stands 4 off what it names. (The menu stood 4 below the
    // button's target, 7 below its face, detached from it.)
    final gap = tooltip ? 4.0 : 0.0;
    var top = anchor.bottom + gap;
    if (tooltip
        ? anchor.top >= childSize.height + 12 ||
              top + childSize.height > size.height - 8
        // Below while it fits, else on the side with more room.
        : childSize.height > _below(size.height) &&
              _above() > _below(size.height)) {
      top = anchor.top - childSize.height - gap;
    }
    return Offset(
      left.clamp(8, math.max(8, size.width - childSize.width - 8)),
      top.clamp(8, math.max(8, size.height - childSize.height - 8)),
    );
  }

  @override
  bool shouldRelayout(_AnchorLayout old) =>
      anchor != old.anchor ||
      direction != old.direction ||
      width != old.width ||
      least != old.least ||
      tooltip != old.tooltip;
}

Widget _hugIf(bool hug, Widget child) =>
    hug ? IntrinsicWidth(child: child) : child;

/// Opens a menu beside a rectangle in global coordinates. [matchWidth] makes
/// it a field's list: at least the anchor's width, on its leading edge.
Future<T?> showRetroDesktopMenu<T>(
  BuildContext context, {
  required Rect anchor,
  required List<RetroDesktopMenuItem<T>> items,
  double? width,
  bool matchWidth = false,
  bool useRootNavigator = true,
  String? label,
  String? closeLabel,
  RetroDesktopStyle? style,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final origin = navigator.context.findRenderObject() as RenderBox?;
  final local = origin == null
      ? anchor
      : anchor.shift(-origin.localToGlobal(Offset.zero));
  final direction = Directionality.of(context);
  return _show<T>(
    context,
    (context) {
      final media = MediaQuery.of(context);
      final inset =
          media.padding + EdgeInsets.only(bottom: media.viewInsets.bottom);
      return Padding(
        padding: inset,
        child: CustomSingleChildLayout(
          // A field's list: at least as wide as the field, on its leading
          // edge, as wide as its longest item up to 320.
          delegate: _AnchorLayout(
            local.shift(-Offset(inset.left, inset.top)),
            direction,
            width: matchWidth ? math.max(anchor.width, 320) : width,
            least: matchWidth ? anchor.width : null,
          ),
          child: _hugIf(
            matchWidth,
            _FieldList(
              on: matchWidth,
              child: RetroDesktopMenu<T>(
                items: items,
                label: label,
                style: style,
                onSelected: (value) => Navigator.pop(context, value),
              ),
            ),
          ),
        ),
      );
    },
    root: useRootNavigator,
    // A menu leaves the window it drops from active.
    modal: false,
    label: closeLabel,
  );
}

/// A handle to a tooltip or notice; dismissal is safe to call more than once.
abstract class RetroDesktopRaised {
  /// Closes this raised surface and restores focus.
  void dismiss();

  /// Completes when this raised surface has been removed.
  Future<void> get closed;
}

class _OverlayHandle implements RetroDesktopRaised {
  _OverlayHandle(this.overlay, {bool Function()? active}) {
    _escape = _EscapeLayer(dismiss, active: active);
  }
  late final _EscapeLayer _escape;
  final OverlayState overlay;
  OverlayEntry? entry;
  VoidCallback? leave, beforeDismiss;
  final _closed = Completer<void>();
  bool _leaving = false;
  @override
  Future<void> get closed => _closed.future;
  @override
  void dismiss() {
    if (_leaving) return;
    _leaving = true;
    _escape.dispose();
    beforeDismiss?.call();
    if (leave == null) {
      remove();
    } else {
      leave!();
    }
  }

  void remove() {
    _leaving = true;
    _escape.dispose();
    final held = entry;
    entry = null;
    if (held != null) {
      held.remove();
      held.dispose();
    }
    if (!_closed.isCompleted) _closed.complete();
  }

  void unmounted() => remove();
}

class _OverlayTransition extends StatefulWidget {
  const _OverlayTransition({
    required this.handle,
    required this.motion,
    required this.child,
  });
  final _OverlayHandle handle;
  final RetroDesktopMotion motion;
  final Widget child;
  @override
  State<_OverlayTransition> createState() => _OverlayTransitionState();
}

class _OverlayTransitionState extends State<_OverlayTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: widget.motion.raise,
    reverseDuration: widget.motion.leave,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _animation,
    curve: widget.motion.enter,
    reverseCurve: widget.motion.exit,
  );
  @override
  void initState() {
    super.initState();
    widget.handle.leave = () {
      if (!mounted || widget.motion.leave == Duration.zero) {
        widget.handle.remove();
      } else {
        _animation.reverse().whenComplete(widget.handle.remove);
      }
    };
    _animation.forward();
  }

  @override
  void dispose() {
    widget.handle.leave = null;
    widget.handle.unmounted();
    _curve.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _curve, child: widget.child);
}

/// The tooltip's paper label, in the family's control shape. Usually shown by [RetroDesktopTooltip].
///
/// ```dart
/// RetroDesktopTooltipFace(message: 'Save this document')
/// ```
class RetroDesktopTooltipFace extends StatelessWidget {
  /// Creates a [RetroDesktopTooltipFace].
  const RetroDesktopTooltipFace({super.key, required this.message, this.style});

  /// The message displayed to the user.
  final String message;

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;
  @override
  // A label as wide as its words, at its column's start, wherever it is set: stretched across a window it read as a
  // text field.
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    widthFactor: 1,
    heightFactor: 1,
    child: _RaisedSurface(
      componentTheme: RetroDesktopTheme.of(context).tooltipTheme,
      scale: RetroDesktopFaceScale.control,
      style: style,
      padding: const EdgeInsets.symmetric(
        horizontal: RetroDesktopSpacing.s10,
        vertical: RetroDesktopSpacing.s6,
      ),
      child: Text(message),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

/// Opens a tooltip near a global rectangle without taking keyboard focus.
RetroDesktopRaised showRetroDesktopTooltip(
  BuildContext context, {
  required String message,
  required Rect anchor,
  RetroDesktopStyle? style,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final box = overlay.context.findRenderObject() as RenderBox;
  final local = anchor.shift(-box.localToGlobal(Offset.zero));
  final carried = _Carried(context, overlay.context);
  final route = ModalRoute.of(context);
  final handle = _OverlayHandle(
    overlay,
    active: () => route?.isCurrent ?? true,
  );
  handle.entry = OverlayEntry(
    builder: (context) => carried.wrap(
      IgnorePointer(
        child: ExcludeSemantics(
          child: _OverlayTransition(
            handle: handle,
            motion: carried.motion,
            child: Builder(
              builder: (context) {
                final media = MediaQuery.of(context);
                final inset =
                    media.padding +
                    EdgeInsets.only(bottom: media.viewInsets.bottom);
                return Padding(
                  padding: inset,
                  child: CustomSingleChildLayout(
                    delegate: _AnchorLayout(
                      local.shift(-Offset(inset.left, inset.top)),
                      carried.direction,
                      tooltip: true,
                    ),
                    child: RetroDesktopTooltipFace(
                      message: message,
                      style: style,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(handle.entry!);
  return handle;
}

/// Pointer hover, keyboard focus and long press reveal the same tooltip: Flutter's [RawTooltip] (the pointer may rest
/// on the tip, Escape hides it, and a screen reader hears the message as the control's tooltip), drawn as the look's
/// paper label. It stands at once and goes at once, as the look's windows do; with a raise or a leave set in the
/// theme's motion it fades on ui_core's spring.
///
/// ```dart
/// RetroDesktopTooltip(message: 'Save this document', child: RetroDesktopButton('Save', isDefaultAction: true, onPressed: () {}))
/// ```
class RetroDesktopTooltip extends StatelessWidget {
  /// Creates a [RetroDesktopTooltip].
  const RetroDesktopTooltip({
    super.key,
    required this.message,
    required this.child,
    this.wait = const Duration(milliseconds: 400),
    this.style,
  });

  /// The message displayed to the user.
  final String message;

  /// The widget displayed inside this part.
  final Widget child;

  /// The delay before the tooltip opens.
  final Duration wait;

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    // ui_core's placement: above the control, centred on it, below where there is no room.
    child: RawTooltipPlacement(
      builder: (context, positionDelegate) => RawTooltip(
        semanticsTooltip: message,
        hoverDelay: wait,
        positionDelegate: positionDelegate,
        animationStyle: _TipSpring.life,
        tooltipBuilder: (context, animation) => ExcludeSemantics(
          child: _TipSpring(
            showing: animation,
            builder: (context, presence) => _RaisedPresence(
              presence: presence,
              child: RetroDesktopTooltipFace(message: message, style: style),
            ),
          ),
        ),
        // Shows the tip while the control has the keys' focus, as a hover does.
        child: RawTooltipFocusFix(child: child),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(
        DiagnosticsProperty<Duration>(
          'wait',
          wait,
          defaultValue: const Duration(milliseconds: 400),
        ),
      )
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

// A tooltip's presence on ui_core's effects spring (critically damped, k 1600; under Reduce Motion a short fade),
// following the way [showing], the RawTooltip's animation, runs: forward springs it to 1, reverse to 0.
class _TipSpring extends StatefulWidget {
  const _TipSpring({required this.showing, required this.builder});

  // How long the RawTooltip keeps a hidden tip in the overlay: longer than the spring takes to fade it out (about
  // 230 ms).
  static const AnimationStyle life = AnimationStyle(
    duration: Duration(milliseconds: 150),
    reverseDuration: Duration(milliseconds: 300),
  );

  final Animation<double> showing;
  final Widget Function(BuildContext context, Animation<double> presence)
  builder;

  @override
  State<_TipSpring> createState() => _TipSpringState();
}

class _TipSpringState extends State<_TipSpring>
    with SingleTickerProviderStateMixin {
  late final AnimationController _presence = AnimationController(vsync: this);
  bool? _shown;

  @override
  void initState() {
    super.initState();
    widget.showing.addStatusListener(_follow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _follow(widget.showing.status);
  }

  @override
  void didUpdateWidget(_TipSpring old) {
    super.didUpdateWidget(old);
    if (old.showing != widget.showing) {
      old.showing.removeStatusListener(_follow);
      widget.showing.addStatusListener(_follow);
      _follow(widget.showing.status);
    }
  }

  @override
  void dispose() {
    widget.showing.removeStatusListener(_follow);
    _presence.dispose();
    super.dispose();
  }

  void _follow(AnimationStatus status) {
    final shown = status.isForwardOrCompleted;
    if (shown == _shown) return;
    _shown = shown;
    _presence.springTo(
      shown ? 1 : 0,
      DesignMotionPolicy.of(context).effects(dampingRatio: 1, stiffness: 1600),
    );
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _presence);
}

// A surface ui_core shows and hides on its own spring ([presence]), as the look raises it: whole from the moment it
// shows and gone from the moment it hides while the theme's raise and leave are zero (the default and Reduce Motion),
// else fading with the spring. Gone, it takes no pointer.
class _RaisedPresence extends StatelessWidget {
  const _RaisedPresence({required this.presence, required this.child});

  final Animation<double> presence;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = RetroDesktopMotion.of(context);
    if (motion.raise != Duration.zero || motion.leave != Duration.zero) {
      return FadeTransition(opacity: presence, child: child);
    }
    return AnimatedBuilder(
      animation: presence,
      child: child,
      builder: (context, child) {
        final shown =
            presence.status == AnimationStatus.forward ||
            presence.status == AnimationStatus.completed;
        return IgnorePointer(
          ignoring: !shown,
          child: Opacity(opacity: shown ? 1 : 0, child: child),
        );
      },
    );
  }
}

/// A notice window with optional action and dismissal controls.
///
/// ```dart
/// RetroDesktopSnackBar('Document saved', actionLabel: 'Undo', onAction: () {})
/// ```
class RetroDesktopSnackBar extends StatelessWidget {
  /// Creates a [RetroDesktopSnackBar].
  const RetroDesktopSnackBar(
    this.message, {
    super.key,
    this.title,
    this.tone = RetroDesktopTone.info,
    this.actionLabel,
    this.onAction,
    this.onDismissed,
    this.dismissLabel,
    this.style,
  });

  /// The message displayed to the user.
  final String message;

  /// The meaning conveyed by the notice and its identifying mark.
  final RetroDesktopTone tone;

  /// The heading displayed above the content.
  final String? title;

  /// The label of the message's action.
  final String? actionLabel;

  /// Overrides the accessible name of the dismiss action.
  final String? dismissLabel;

  /// Called when the message's action is activated.
  final VoidCallback? onAction;

  /// Called when the user dismisses it with its dismiss button.
  final VoidCallback? onDismissed;

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return Semantics(
      liveRegion: true,
      child: _RaisedSurface(
        componentTheme: t.snackBarTheme,
        style: style,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!, style: t.type.sub),
              const SizedBox(height: RetroDesktopSpacing.s6),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // On the message's first line at any text size.
                RetroDesktopOnCaps(
                  child: SizedBox.square(
                    dimension: 20,
                    child: Center(
                      child: retroDesktopAlertArt(t, tone, size: 16),
                    ),
                  ),
                ),
                const SizedBox(width: RetroDesktopSpacing.s10),
                Expanded(child: Text(message)),
              ],
            ),
            if (actionLabel != null || onDismissed != null)
              Padding(
                padding: const EdgeInsets.only(top: RetroDesktopSpacing.s8),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: RetroDesktopSpacing.s8,
                  runSpacing: RetroDesktopSpacing.s8,
                  children: [
                    if (actionLabel != null)
                      RetroDesktopButton(actionLabel!, onPressed: onAction),
                    if (onDismissed != null)
                      RetroDesktopButton(
                        dismissLabel ??
                            RawWidgetsLocalizations.of(context)
                                .modalBarrierDismissLabel,
                        onPressed: onDismissed,
                      ),
                  ],
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
      ..add(
        EnumProperty<RetroDesktopTone>(
          'tone',
          tone,
          defaultValue: RetroDesktopTone.info,
        ),
      )
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(StringProperty('actionLabel', actionLabel, defaultValue: null))
      ..add(StringProperty('dismissLabel', dismissLabel, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onAction', onAction))
      ..add(ObjectFlagProperty<VoidCallback>.has('onDismissed', onDismissed))
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

final _notices = Expando<_OverlayHandle>('retro-desktop-notice');

/// Shows one notice per overlay. Hover, focus and accessible actions pause expiry.
RetroDesktopRaised showRetroDesktopSnackBar(
  BuildContext context,
  String message, {
  String? title,
  RetroDesktopTone tone = RetroDesktopTone.info,
  String? actionLabel,
  VoidCallback? onAction,
  String? dismissLabel,
  Duration duration = const Duration(seconds: 5),
  double bottom = 0,
  RetroDesktopStyle? style,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  _notices[overlay]?.dismiss();
  final route = ModalRoute.of(context);
  final handle = _OverlayHandle(
    overlay,
    active: () => route?.isCurrent ?? true,
  );
  _notices[overlay] = handle;
  final carried = _Carried(context, overlay.context);
  final back = FocusManager.instance.primaryFocus;
  void close() => handle.dismiss();
  handle.closed.whenComplete(() {
    if (identical(_notices[overlay], handle)) _notices[overlay] = null;
  });
  handle.entry = OverlayEntry(
    builder: (context) => carried.wrap(
      _SnackBarHost(
        handle: handle,
        motion: carried.motion,
        duration: duration,
        bottom: bottom,
        pauseForAccess: carried.media.accessibleNavigation && onAction != null,
        onClose: close,
        backFocus: back,
        child: RetroDesktopSnackBar(
          message,
          title: title,
          tone: tone,
          actionLabel: actionLabel,
          dismissLabel: dismissLabel,
          style: style,
          onDismissed: close,
          onAction: onAction == null
              ? null
              : () {
                  try {
                    onAction();
                  } finally {
                    close();
                  }
                },
        ),
      ),
    ),
  );
  overlay.insert(handle.entry!);
  return handle;
}

class _SnackBarHost extends StatefulWidget {
  const _SnackBarHost({
    required this.handle,
    required this.motion,
    required this.duration,
    required this.bottom,
    required this.pauseForAccess,
    required this.onClose,
    required this.backFocus,
    required this.child,
  });
  final _OverlayHandle handle;
  final RetroDesktopMotion motion;
  final Duration duration;
  final double bottom;
  final bool pauseForAccess;
  final VoidCallback onClose;
  final FocusNode? backFocus;
  final Widget child;
  @override
  State<_SnackBarHost> createState() => _SnackBarHostState();
}

class _SnackBarHostState extends State<_SnackBarHost> {
  final _scope = FocusScopeNode();
  Timer? _timer;
  bool _hovered = false, _focused = false;
  void _wait() {
    _timer?.cancel();
    if (!widget.pauseForAccess && !_hovered && !_focused) {
      _timer = Timer(widget.duration, widget.onClose);
    }
  }

  @override
  void initState() {
    super.initState();
    _wait();
    widget.handle.beforeDismiss = () {
      final back = widget.backFocus;
      if (_scope.hasFocus && back?.context != null && back!.canRequestFocus) {
        back.requestFocus();
      }
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.handle.beforeDismiss = null;
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + widget.bottom + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _OverlayTransition(
            handle: widget.handle,
            motion: widget.motion,
            child: FocusScope(
              node: _scope,
              onFocusChange: (value) {
                _focused = value;
                _wait();
              },
              child: MouseRegion(
                onEnter: (_) {
                  _hovered = true;
                  _wait();
                },
                onExit: (_) {
                  _hovered = false;
                  _wait();
                },
                child: SingleChildScrollView(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Connects a button builder to a menu anchored at that button's bounds.
///
/// ```dart
/// RetroDesktopMenuAnchor(items: const [RetroDesktopMenuItem('open', 'Open')], builder: (context, open) => RetroDesktopButton('Actions', onPressed: open), onSelected: (_) {})
/// ```
class RetroDesktopMenuAnchor<T> extends StatefulWidget {
  /// Creates a [RetroDesktopMenuAnchor].
  const RetroDesktopMenuAnchor({
    super.key,
    required this.items,
    required this.builder,
    this.onSelected,
    this.style,
  });

  /// The items displayed in their supplied order.
  final List<RetroDesktopMenuItem<T>> items;

  /// Builds the content with the current context and state.
  final Widget Function(BuildContext, VoidCallback?) builder;

  /// Reports the selected menu value; null disables the anchor, so the
  /// builder's open callback is null.
  final ValueChanged<T>? onSelected;

  /// {@macro retro_desktop.style}
  final RetroDesktopStyle? style;
  @override
  State<RetroDesktopMenuAnchor<T>> createState() => _MenuAnchorState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RetroDesktopMenuItem<T>>('items', items))
      ..add(
        ObjectFlagProperty<Widget Function(BuildContext, VoidCallback?)>.has(
          'builder',
          builder,
        ),
      )
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

class _MenuAnchorState<T> extends State<RetroDesktopMenuAnchor<T>> {
  bool _opening = false;
  Future<void> _show() async {
    if (_opening || widget.onSelected == null || widget.items.isEmpty) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    _opening = true;
    try {
      final value = await showRetroDesktopMenu<T>(
        context,
        anchor: box.localToGlobal(Offset.zero) & box.size,
        items: widget.items,
        style: widget.style,
      );
      if (mounted && value != null) widget.onSelected?.call(value);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    widget.onSelected != null && widget.items.isNotEmpty ? _show : null,
  );
}

/// A dialog action closes the route with [value], then runs its optional side effect.
///
/// ```dart
/// RetroDesktopDialogAction('Save', value: true, isDefaultAction: true)
/// ```
class RetroDesktopDialogAction<T> extends StatelessWidget {
  /// Creates a [RetroDesktopDialogAction].
  const RetroDesktopDialogAction(
    this.label, {
    super.key,
    this.value,
    this.onPressed,
    this.enabled = true,
    this.isDefaultAction = false,
  });

  /// The visible or accessible name of this part.
  final String label;

  /// The current value to display or edit.
  final T? value;

  /// {@macro retro_desktop.onPressed}
  final VoidCallback? onPressed;

  /// Whether the part accepts user interaction.
  final bool enabled;

  /// Whether this action receives the primary emphasis.
  final bool isDefaultAction;
  @override
  Widget build(BuildContext context) {
    final action = enabled
        ? () {
            Navigator.of(context).pop<T>(value);
            onPressed?.call();
          }
        : null;
    return isDefaultAction
        ? RetroDesktopButton(label, isDefaultAction: true, onPressed: action)
        : RetroDesktopButton(label, onPressed: action);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        FlagProperty(
          'isDefaultAction',
          value: isDefaultAction,
          ifTrue: 'isDefaultAction',
        ),
      );
  }
}
