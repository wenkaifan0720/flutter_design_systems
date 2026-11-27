// The menu a field shows over a selection, in Fluent 2's menu rows, in place of Material's or Cupertino's toolbar. The
// field itself is Flutter's, and so are its gestures, autofill and semantics.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialLocalizations, MaterialType;
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/menu_lead.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../menu/menu.dart';
import '../pressable/pressable.dart';

/// Fluent's Menu over a selection: Cut, Copy, Paste, Select all and what else
/// the platform offers, by a pointer or above the selection on a phone. Each
/// row is the menu's own face; its words are [Fluent2Localizations]'.
///
/// ```dart
/// TextField(contextMenuBuilder: Fluent2FieldContextMenu.editable)
/// ```
class Fluent2FieldContextMenu extends StatelessWidget {
  /// A menu of [items] at [anchors].
  const Fluent2FieldContextMenu({
    super.key,
    required this.anchors,
    required this.items,
  });

  /// Where the selection is: the menu stands above it, or below when there
  /// is no room.
  final TextSelectionToolbarAnchors anchors;

  /// What the menu offers.
  final List<ContextMenuButtonItem> items;

  /// The menu for [state]'s selection, for `contextMenuBuilder`.
  static Widget editable(BuildContext context, EditableTextState state) =>
      Fluent2FieldContextMenu(
        anchors: state.contextMenuAnchors,
        items: state.contextMenuButtonItems,
      );

  /// The words for [item]: its own label, else the word for its kind:
  /// Fluent 2's in English or where the app gives Fluent 2 words of its own,
  /// else Material's in the app's language (the published package carries
  /// Material's translations), so an app in German reads "Kopieren".
  static String labelOf(BuildContext context, ContextMenuButtonItem item) {
    if (item.label != null) return item.label!;
    final w = Fluent2Localizations.of(context);
    final language = Localizations.maybeLocaleOf(context)?.languageCode;
    if (w.runtimeType == Fluent2LocalizationsEn &&
        language != null &&
        language != 'en') {
      final m = MaterialLocalizations.of(context);
      return switch (item.type) {
        ContextMenuButtonType.cut => m.cutButtonLabel,
        ContextMenuButtonType.copy => m.copyButtonLabel,
        ContextMenuButtonType.paste => m.pasteButtonLabel,
        ContextMenuButtonType.selectAll => m.selectAllButtonLabel,
        ContextMenuButtonType.delete => m.deleteButtonTooltip,
        ContextMenuButtonType.lookUp => m.lookUpButtonLabel,
        ContextMenuButtonType.searchWeb => m.searchWebButtonLabel,
        ContextMenuButtonType.share => m.shareButtonLabel,
        ContextMenuButtonType.liveTextInput => m.scanTextButtonLabel,
        _ => '',
      };
    }
    return switch (item.type) {
      ContextMenuButtonType.cut => w.cut,
      ContextMenuButtonType.copy => w.copy,
      ContextMenuButtonType.paste => w.paste,
      ContextMenuButtonType.selectAll => w.selectAll,
      ContextMenuButtonType.delete => w.remove(''),
      ContextMenuButtonType.lookUp => w.lookUp,
      ContextMenuButtonType.searchWeb => w.searchWeb,
      ContextMenuButtonType.share => w.share,
      ContextMenuButtonType.liveTextInput => w.scanText,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final t = context.fluent2Theme;
    final padding = MediaQuery.paddingOf(context);
    const gap = Fluent2Spacing.s;
    final shift = Offset(gap, padding.top + gap);
    return Padding(
      padding: EdgeInsets.fromLTRB(gap, padding.top + gap, gap, gap),
      child: CustomSingleChildLayout(
        delegate: TextSelectionToolbarLayoutDelegate(
          anchorAbove: anchors.primaryAnchor - shift - const Offset(0, gap),
          anchorBelow:
              (anchors.secondaryAnchor ?? anchors.primaryAnchor) -
              shift +
              const Offset(0, gap),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: Fluent2ChromeMetrics.menuMinWidth,
              maxWidth: Fluent2ChromeMetrics.menuMaxWidth,
            ),
            child: IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.all(Fluent2ChromeMetrics.menuPadding),
                decoration: BoxDecoration(
                  color: t.colors.neutralBackground1,
                  borderRadius: BorderRadius.circular(Fluent2Radius.medium),
                  border: Border.all(
                    color: t.isDark
                        ? t.colors.neutralStroke2
                        : t.colors.transparentStroke,
                  ),
                  boxShadow: t.shadows.shadow16,
                ),
                // A pointer opens it, the focus left in the field: no row
                // lights until the pointer moves ([Fluent2MenuLead]).
                child: Fluent2MenuLead(
                  keys: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in items)
                        Fluent2Pressable(
                          onPressed: item.onPressed,
                          semanticLabel: labelOf(context, item),
                          radius: Fluent2Radius.medium,
                          ring: false,
                          builder: (context, states) => Fluent2MenuRowFace(
                            label: labelOf(context, item),
                            states: states,
                            ring: true,
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
      ..add(
        DiagnosticsProperty<TextSelectionToolbarAnchors>('anchors', anchors),
      )
      ..add(IterableProperty<ContextMenuButtonItem>('items', items));
  }
}
