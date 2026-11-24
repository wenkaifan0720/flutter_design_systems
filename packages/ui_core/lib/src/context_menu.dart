/// A context menu, headless: a menu of [RawMenuEntry]s over a region,
/// opened at the pointer by a right click (a secondary tap) or a long press,
/// at the focused widget by Shift+F10 or the Menu key, and by a screen
/// reader's "Show menu". Its rows are a menubar's: commands, submenus,
/// dividers, checks, typed letters, the highlight following the pointer.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'anchored_overlay.dart';
import 'haptics.dart';
import 'internal/browser_menu.dart';
import 'internal/menu_items.dart';
import 'internal/surface_focus.dart';
import 'localizations.dart';
import 'menubar.dart';

/// A menu of [menuChildren] that opens over [child], where the user asks
/// for it.
///
/// - A right click (a secondary tap: a two-finger click on a trackpad)
///   opens it at the pointer, and so does a long press of a finger or a
///   stylus, with the long press's haptic ([RawHaptics.longPress]) when
///   [enableFeedback]. The menu opens below the point from its start in
///   reading order, above it or towards its other end where there is no
///   room, and never under it. No row is lit until the pointer or a key
///   picks one.
/// - Shift+F10, or the Menu key, opens it at the focused widget's leading
///   bottom corner, while the focus is inside [child], its first row lit.
/// - A screen reader finds "Show menu" ([RawWidgetsLocalizations.showMenuTooltip])
///   among the region's actions, and a long press (Android's double tap and
///   hold) says it.
/// - On the web, the browser's own menu stays shut while a pointer is over
///   the region or pressed in it, focus is in it, or its menu is open; it
///   works as before elsewhere, and an app that turned it off itself keeps
///   it off.
/// - A context menu inside another's region opens alone: the innermost
///   wins.
///
/// Escape, a tap outside it or Android's back closes it, and the focus goes
/// back to where it was. A command closes it, then runs.
///
/// ```dart
/// RawContextMenu(menuChildren: [RawMenuEntry(label: 'Copy', onPressed: () {})], itemBuilder: (context, entry, level, states) => Text(entry.label), surfaceBuilder: (context, info, items) => Column(mainAxisSize: MainAxisSize.min, children: items), child: const Text('Report.pdf'))
/// ```
class RawContextMenu extends StatefulWidget {
  /// A menu of [menuChildren] over [child].
  const RawContextMenu({
    super.key,
    required this.menuChildren,
    required this.itemBuilder,
    required this.surfaceBuilder,
    required this.child,
    this.dividerBuilder,
    this.controller,
    this.onOpenChanged,
    this.semanticLabel,
    this.highlightFollowsPointer = true,
    this.enableFeedback = true,
    this.useRootOverlay = false,
    this.dampingRatio = 1,
    this.stiffness = 1400,
  }) : assert(dampingRatio > 0 && stiffness > 0);

  /// The menu's rows: commands, submenus and dividers. Empty: no menu, no
  /// action for a screen reader, and the browser's own menu on the web.
  final List<RawMenuEntry> menuChildren;

  /// Paints a row ([RawMenuLevel.menu]).
  final RawMenuItemBuilder itemBuilder;

  /// Paints the menu's panel round its rows (scroll them when
  /// [RawPopoverInfo.maxSize] is short). [RawPopoverInfo.position] is
  /// the point it opened at.
  final RawMenuBarOverlayBuilder surfaceBuilder;

  /// The region that opens it.
  final Widget child;

  /// Paints a divider; null: a 1 px gap.
  final WidgetBuilder? dividerBuilder;

  /// Opens it at a point of [child] from outside (`open(position:)`) and
  /// closes it; null: it makes its own. The caller disposes nothing: a
  /// [MenuController] holds no resources.
  final MenuController? controller;

  /// Told when it opens (true) and when it has closed (false).
  final ValueChanged<bool>? onOpenChanged;

  /// What a screen reader calls the menu; null: none.
  final String? semanticLabel;

  /// Whether a pointer over a row moves the keys there; true by default, as
  /// [RawMenuBar.highlightFollowsPointer].
  final bool highlightFollowsPointer;

  /// Whether a long press that opens it plays [RawHaptics.longPress];
  /// true by default.
  final bool enableFeedback;

  /// Whether it opens in the root overlay, over every navigator; false by
  /// default: the nearest overlay.
  final bool useRootOverlay;

  /// The open and close spring's damping ratio (`DesignMotion`); 1 by
  /// default, critically damped.
  final double dampingRatio;

  /// The open and close spring's stiffness; 1400 by default.
  final double stiffness;

  @override
  State<RawContextMenu> createState() => _DesignContextMenuState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RawMenuEntry>('menuChildren', menuChildren))
      ..add(
        ObjectFlagProperty<RawMenuItemBuilder>.has('itemBuilder', itemBuilder),
      )
      ..add(
        ObjectFlagProperty<RawMenuBarOverlayBuilder>.has(
          'surfaceBuilder',
          surfaceBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<WidgetBuilder>.has('dividerBuilder', dividerBuilder),
      )
      ..add(
        DiagnosticsProperty<MenuController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<bool>>.has(
          'onOpenChanged',
          onOpenChanged,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'highlightFollowsPointer',
          value: highlightFollowsPointer,
          ifFalse: 'highlight stays with the keys',
        ),
      )
      ..add(
        FlagProperty(
          'enableFeedback',
          value: enableFeedback,
          ifFalse: 'no haptic',
        ),
      )
      ..add(
        FlagProperty(
          'useRootOverlay',
          value: useRootOverlay,
          ifTrue: 'root overlay',
        ),
      )
      ..add(DoubleProperty('dampingRatio', dampingRatio, defaultValue: 1))
      ..add(DoubleProperty('stiffness', stiffness, defaultValue: 1400));
  }
}

// A finger or a stylus: a long press of a mouse opens nothing.
const Set<PointerDeviceKind> _touchKinds = {
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown,
};

class _DesignContextMenuState extends State<RawContextMenu> {
  MenuController? _own;
  final GlobalKey _region = GlobalKey(debugLabel: 'RawContextMenu region');
  final RawBrowserMenuHold _browser = RawBrowserMenuHold();
  bool _hovered = false;
  bool _pressed = false;
  bool _focusedIn = false;
  bool _open = false;

  MenuController get _controller =>
      widget.controller ?? (_own ??= MenuController());

  bool get _enabled => widget.menuChildren.isNotEmpty;

  @override
  void didUpdateWidget(RawContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && _controller.isOpen) {
      // Its rows are gone: closed once this frame is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_enabled && _controller.isOpen) _controller.close();
      });
    }
    _holdBrowser();
  }

  @override
  void dispose() {
    _browser.dispose();
    super.dispose();
  }

  void _holdBrowser() =>
      _browser.hold(_enabled && (_hovered || _pressed || _focusedIn || _open));

  void _openAt(Offset local) {
    if (!_enabled) return;
    _controller.open(position: local);
  }

  void _secondaryTap(TapUpDetails details) => _openAt(details.localPosition);

  void _longPress(LongPressStartDetails details) {
    if (!_enabled) return;
    if (widget.enableFeedback) RawHaptics.of(context).longPress?.call();
    _openAt(details.localPosition);
  }

  RenderBox? get _box {
    final box = _region.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  // A screen reader's "Show menu": at the region's middle.
  void _fromReader() {
    final box = _box;
    if (box != null) _openAt(box.size.center(Offset.zero));
  }

  // The focused widget's leading bottom corner, in the region.
  Offset _focusedCorner(RenderBox box) {
    final rect = FocusManager.instance.primaryFocus?.rect;
    if (rect == null) return box.size.center(Offset.zero);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final local = box.globalToLocal(rtl ? rect.bottomRight : rect.bottomLeft);
    return Offset(
      local.dx.clamp(0.0, box.size.width),
      local.dy.clamp(0.0, box.size.height),
    );
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (!_enabled || event is! KeyDownEvent) return KeyEventResult.ignored;
    final keys = HardwareKeyboard.instance;
    final key = event.logicalKey;
    final shiftF10 =
        key == LogicalKeyboardKey.f10 &&
        keys.isShiftPressed &&
        !keys.isControlPressed &&
        !keys.isAltPressed &&
        !keys.isMetaPressed;
    if (key != LogicalKeyboardKey.contextMenu && !shiftF10) {
      return KeyEventResult.ignored;
    }
    final box = _box;
    if (box == null) return KeyEventResult.ignored;
    _openAt(_focusedCorner(box));
    return KeyEventResult.handled;
  }

  void _down(PointerDownEvent event) {
    _pressed = true;
    _holdBrowser();
    // A press that is not a right click, in the region, closes the menu, as
    // a tap outside it does.
    if (_controller.isOpen && event.buttons & kSecondaryButton == 0) {
      _controller.close();
    }
  }

  void _up(PointerEvent _) {
    _pressed = false;
    _holdBrowser();
  }

  void _openChanged(bool open) {
    _open = open;
    _holdBrowser();
    widget.onOpenChanged?.call(open);
  }

  Widget _regionOf(BuildContext context) {
    final enabled = _enabled;
    Widget region = GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      supportedDevices: _touchKinds,
      onLongPressStart: enabled ? _longPress : null,
      child: widget.child,
    );
    region = GestureDetector(
      key: _region,
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onSecondaryTapUp: enabled ? _secondaryTap : null,
      child: region,
    );
    region = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: MouseRegion(
        onEnter: (_) {
          _hovered = true;
          _holdBrowser();
        },
        onExit: (_) {
          _hovered = false;
          _holdBrowser();
        },
        child: region,
      ),
    );
    region = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _key,
      onFocusChange: (focused) {
        _focusedIn = focused;
        _holdBrowser();
      },
      child: region,
    );
    final words = RawWidgetsLocalizations.of(context);
    return Semantics(
      container: true,
      onLongPress: enabled ? _fromReader : null,
      onLongPressHint: enabled ? words.showMenuTooltip : null,
      customSemanticsActions: enabled
          ? {CustomSemanticsAction(label: words.showMenuTooltip): _fromReader}
          : null,
      child: region,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawPopover(
      // Its anchor is a region, not a control: focus goes back where it
      // was, never to the region's first control.
      key: const RawRegionAnchorKey(),
      controller: _controller,
      trigger: RawPopoverTrigger.manual,
      arrowKeyNavigation: true,
      semanticLabel: widget.semanticLabel,
      // 2 px off the point, so a pointer resting there lights no row.
      placement: const RawPopoverPlacement(gap: 2, matchAnchorWidth: false),
      onOpenChanged: _openChanged,
      useRootOverlay: widget.useRootOverlay,
      dampingRatio: widget.dampingRatio,
      stiffness: widget.stiffness,
      anchorBuilder: (context, anchor) => _regionOf(context),
      overlayBuilder: (context, info) => RawMenuItems(
        info: info,
        entries: widget.menuChildren,
        root: _controller,
        painters: RawMenuPainters(
          itemBuilder: widget.itemBuilder,
          surfaceBuilder: widget.surfaceBuilder,
          dividerBuilder: widget.dividerBuilder,
          highlightFollowsPointer: widget.highlightFollowsPointer,
        ),
      ),
    );
  }
}
