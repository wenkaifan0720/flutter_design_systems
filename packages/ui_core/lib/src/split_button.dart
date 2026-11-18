/// A split button, headless: a main action and, beside it, a toggle that
/// opens a menu of the others (a [DesignAnchoredOverlay] with arrow keys).
/// Both halves are tab stops; Down (with Alt or without) on either half
/// opens the menu at its first item; Escape closes it and focus goes back
/// to the half that opened it.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'anchored_overlay.dart';
import 'internal/menu_items.dart';
import 'localizations.dart';
import 'pressable.dart';

/// An action in a split button's menu.
@immutable
class DesignSplitAction {
  /// An action [label]led, that [onPressed] runs; null disables it.
  const DesignSplitAction({
    required this.label,
    required this.onPressed,
    this.data,
  });

  /// Its name.
  final String label;

  /// Runs it, after the menu closed; null disables it.
  final VoidCallback? onPressed;

  /// Whether it can be pressed: it has [onPressed].
  bool get enabled {
    return onPressed != null;
  }

  /// Anything the look needs to paint it (an icon).
  final Object? data;
}

/// Which part of a split button a builder paints.
enum DesignSplitPart {
  /// The main action.
  main,

  /// The toggle that opens the menu.
  toggle,
}

/// A main action with a menu of [actions] beside it.
///
/// ```dart
/// DesignSplitButton(label: 'Save', onPressed: () {}, actions: [DesignSplitAction(label: 'Save as', onPressed: () {})], buttonBuilder: (context, part, states, open) => Text(part.name), itemBuilder: (context, action, states) => Text(action.label), surfaceBuilder: (context, info, items) => Column(mainAxisSize: MainAxisSize.min, children: items))
/// ```
class DesignSplitButton extends StatelessWidget {
  /// A split button whose main action is [onPressed].
  const DesignSplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.actions,
    required this.buttonBuilder,
    required this.itemBuilder,
    required this.surfaceBuilder,
    this.menuLabel,
    this.layoutBuilder,
    this.minimumSize = const Size(44, 44),
    this.controller,
    this.placement = const DesignOverlayPlacement(),
    this.highlightFollowsPointer = true,
  });

  /// The main action's name.
  final String label;

  /// The main action. Null disables the main half, which leaves the focus
  /// order and reads as disabled; the menu half stays.
  final VoidCallback? onPressed;

  /// The menu's actions.
  final List<DesignSplitAction> actions;

  /// Paints a half; `open` while the menu shows.
  final Widget Function(
    BuildContext context,
    DesignSplitPart part,
    Set<WidgetState> states,
    bool open,
  )
  buttonBuilder;

  /// Paints a menu item.
  final Widget Function(
    BuildContext context,
    DesignSplitAction action,
    Set<WidgetState> states,
  )
  itemBuilder;

  /// Paints the menu's panel around its `items`.
  final Widget Function(
    BuildContext context,
    DesignOverlayInfo info,
    List<Widget> items,
  )
  surfaceBuilder;

  /// What a screen reader calls the toggle; null:
  /// [DesignLocalizations.splitButtonMenuLabel].
  final String? menuLabel;

  /// Lays out the two halves; null: a row.
  final Widget Function(BuildContext context, Widget main, Widget toggle)?
  layoutBuilder;

  /// Each half's least target.
  final Size minimumSize;

  /// The menu's controller; null: its own.
  final MenuController? controller;

  /// Where the menu opens relative to both halves of the button. Its leading
  /// edge aligns with the button by default. The menu is at least as wide
  /// as the button when the screen has room.
  final DesignOverlayPlacement placement;

  /// Whether a pointer over a menu item moves the keys there; true by
  /// default, as `DesignMenuBar.highlightFollowsPointer`: one item lit, the
  /// current one (hovered when the pointer moved last, focused when the keys
  /// did), and none once the pointer leaves the menu. A menu a click opened
  /// lights none until the pointer or a key picks one.
  final bool highlightFollowsPointer;

  @override
  Widget build(BuildContext context) {
    return DesignAnchoredOverlay(
      controller: controller,
      trigger: DesignOverlayTrigger.manual,
      arrowKeyNavigation: true,
      semanticLabel:
          menuLabel ?? DesignLocalizations.of(context).splitButtonMenuLabel,
      placement: placement,
      anchorBuilder: (context, anchor) {
        KeyEventResult open(FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowDown &&
              !anchor.isOpen) {
            anchor.open();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }

        final main = DesignPressable(
          onPressed: onPressed,
          onKeyEvent: open,
          minimumSize: minimumSize,
          semanticLabel: label,
          excludeSemantics: true,
          builder: (context, states, _) => buttonBuilder(
            context,
            DesignSplitPart.main,
            states,
            anchor.isOpen,
          ),
        );
        final toggle = DesignPressable(
          onPressed: actions.isEmpty ? null : anchor.toggle,
          onKeyEvent: open,
          minimumSize: minimumSize,
          selected: anchor.isOpen,
          expanded: anchor.isOpen,
          semanticLabel:
              menuLabel ?? DesignLocalizations.of(context).splitButtonMenuLabel,
          excludeSemantics: true,
          builder: (context, states, _) => buttonBuilder(
            context,
            DesignSplitPart.toggle,
            states,
            anchor.isOpen,
          ),
        );
        return layoutBuilder?.call(context, main, toggle) ??
            Row(mainAxisSize: MainAxisSize.min, children: [main, toggle]);
      },
      overlayBuilder: (context, info) => ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: info.anchorRect.width.clamp(0.0, info.maxSize.width),
        ),
        child: surfaceBuilder(context, info, [
          for (final a in actions)
            DesignMenuRow(
              highlightFollowsPointer: highlightFollowsPointer,
              onPressed: a.enabled
                  ? () {
                      info.close();
                      a.onPressed?.call();
                    }
                  : null,
              semanticLabel: a.label,
              builder: (context, states) => itemBuilder(context, a, states),
            ),
        ]),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(IterableProperty<DesignSplitAction>('actions', actions))
      ..add(
        ObjectFlagProperty<
          Widget Function(
            BuildContext context,
            DesignSplitPart part,
            Set<WidgetState> states,
            bool open,
          )
        >.has('buttonBuilder', buttonBuilder),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(
            BuildContext context,
            DesignSplitAction action,
            Set<WidgetState> states,
          )
        >.has('itemBuilder', itemBuilder),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(
            BuildContext context,
            DesignOverlayInfo info,
            List<Widget> items,
          )
        >.has('surfaceBuilder', surfaceBuilder),
      )
      ..add(StringProperty('menuLabel', menuLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<DesignOverlayPlacement>(
          'placement',
          placement,
          defaultValue: const DesignOverlayPlacement(),
        ),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, Widget main, Widget toggle)
        >.has('layoutBuilder', layoutBuilder),
      )
      ..add(
        DiagnosticsProperty<Size>(
          'minimumSize',
          minimumSize,
          defaultValue: const Size(44, 44),
        ),
      )
      ..add(
        DiagnosticsProperty<MenuController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'highlightFollowsPointer',
          value: highlightFollowsPointer,
          ifFalse: 'highlight stays with the keys',
        ),
      );
  }
}
