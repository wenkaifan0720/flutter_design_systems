/// A short list of acts raised from the bottom of the screen, in Ledger's
/// hand.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';
import '../button/button.dart';
import '../pressable/pressable.dart';
import '../sheet.dart';

/// One act of a [LedgerActionSheet]: its [label], the [value] it answers
/// with, a glyph, and whether it cannot be taken back.
@immutable
class LedgerSheetAct<T> {
  /// An act worded [label] answering [value].
  const LedgerSheetAct(
    this.label, {
    required this.value,
    this.icon,
    this.isDestructiveAction = false,
  });

  /// Its words.
  final String label;

  /// What choosing it answers.
  final T value;

  /// A glyph before its words.
  final IconData? icon;

  /// Whether it cannot be taken back: set in the vermilion.
  final bool isDestructiveAction;
}

/// The acts of an action sheet (what to do with a receipt: Replace the
/// photo, Download, Delete), drawn in place: [message] in the second ink
/// over them, then each act a line 52 tall under a hairline, its glyph and
/// its words in the medium, the vermilion for one that cannot be taken
/// back, the darker paper under a pointer or a press. [onSelected] gets the
/// act's value. [showLedgerActionSheet] raises them on a sheet with Cancel at
/// its foot.
///
/// ```dart
/// LedgerActionSheet<String>(acts: const [LedgerSheetAct('Download', value: 'download')], onSelected: (v) {})
/// ```
class LedgerActionSheet<T> extends StatelessWidget {
  /// The [acts], each answering [onSelected].
  const LedgerActionSheet({
    required this.acts,
    required this.onSelected,
    this.message,
    super.key,
  });

  /// The acts, in order; the one that cannot be taken back last.
  final List<LedgerSheetAct<T>> acts;

  /// Called with the act chosen.
  final ValueChanged<T> onSelected;

  /// The words over the acts.
  final String? message;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<LedgerSheetAct<T>>('acts', acts))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(StringProperty('message', message, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message case final m?)
          Padding(
            padding: const EdgeInsets.only(bottom: LedgerSpacing.s12),
            child: Text(m, style: t.bodySmall.colored(t.textSecondary)),
          ),
        for (final a in acts)
          LedgerPressable(
            onTap: () => onSelected(a.value),
            label: a.label,
            child: Builder(
              builder: (context) {
                final hot = LedgerPressStates.isHot(context);
                final ink = a.isDestructiveAction ? t.danger : t.textPrimary;
                return Container(
                  constraints: BoxConstraints(
                    minHeight: t.density.height(_line),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: LedgerSpacing.s8,
                  ),
                  decoration: BoxDecoration(
                    color: hot ? t.selectedFill : null,
                    border: Border(top: BorderSide(color: t.hairline)),
                  ),
                  child: Row(
                    spacing: LedgerSpacing.s12,
                    children: [
                      if (a.icon case final icon?)
                        Icon(icon, size: LedgerIconSize.i18, color: ink),
                      Expanded(
                        child: Text(a.label, style: t.rowTitle.colored(ink)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  static const double _line = 52;
}

/// Raises [acts] on a sheet titled [title] (on a phone off the bottom edge,
/// at desktop width as a dialog) with Cancel at its foot. Completes with the
/// value of the act chosen; null when it is cancelled or dismissed.
///
/// ```dart
/// final act = await showLedgerActionSheet<String>(context, title: 'Receipt', acts: const [LedgerSheetAct('Delete', value: 'delete', isDestructiveAction: true)]);
/// ```
Future<T?> showLedgerActionSheet<T>(
  BuildContext context, {
  required String title,
  required List<LedgerSheetAct<T>> acts,
  String? message,
  String? cancelLabel,
}) => LedgerSheet.show<T>(
  context,
  title: title,
  close: false,
  builder: (sheetContext) => [
    LedgerActionSheet<T>(
      acts: acts,
      message: message,
      onSelected: (v) => Navigator.of(sheetContext).pop(v),
    ),
  ],
  foot: (footContext) => [
    LedgerButton(
      cancelLabel ?? RawWidgetsLocalizations.of(footContext).cancelButtonLabel,
      onPressed: () => Navigator.of(footContext).pop(),
    ),
  ],
);
