/// Every act of the app found by typing, in Ledger's hand, over ui_core's
/// [RawCommandPalette].
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/option_paper.dart';
import '../../theme.dart';
import '../kbd/kbd.dart';
import '../text-field/text_field.dart';

/// One act a palette offers: ui_core's [RawCommand] (its label, what it
/// runs, its group, its shortcut's keys).
typedef LedgerCommand = RawCommand;

/// Every act of the app found by typing (New entry, Export October, Go to
/// Budgets): a field on its rule with the search glyph, and under it the
/// acts matching what is typed on the select's raised paper, gathered under
/// their groups' small capitals, each 48 a line with its shortcut's keys at
/// its end. Up and down walk the list, Enter runs the line, Escape closes
/// it; with nothing matching the paper says so, and a screen reader hears
/// how many match. Open it over a page with [showLedgerCommandPalette], or
/// stand it on a page (a desk's side search).
///
/// ```dart
/// LedgerCommandPalette(commands: const [LedgerCommand(label: 'New entry', group: 'Entries', shortcut: 'N')])
/// ```
class LedgerCommandPalette extends StatelessWidget {
  /// A palette of [commands].
  const LedgerCommandPalette({
    required this.commands,
    this.onSelected,
    this.hint = 'Type an act or a place',
    this.autofocus = false,
    super.key,
  });

  /// The acts it offers.
  final List<LedgerCommand> commands;

  /// Takes the chosen act; null runs its own.
  final ValueChanged<LedgerCommand>? onSelected;

  /// The field's words while it is empty.
  final String hint;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<LedgerCommand>('commands', commands))
      ..add(
        ObjectFlagProperty<ValueChanged<LedgerCommand>>.has(
          'onSelected',
          onSelected,
        ),
      )
      ..add(StringProperty('hint', hint))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }

  @override
  Widget build(BuildContext context) => toDesign();

  /// The palette as ui_core's [RawCommandPalette], drawn in Ledger's hand
  /// (what [showLedgerCommandPalette] opens).
  RawCommandPalette toDesign() => RawCommandPalette(
    commands: commands,
    onSelected: onSelected,
    autofocus: autofocus,
    maxHeight: _paper,
    fieldBuilder: (context, field) {
      final t = context.ledgerTheme;
      final words = LedgerTextField.wordsOf(t);
      // The line's ground: a press beside the words (the glyph, the line's
      // height) writes in the field, so a tap reaches its whole box.
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: field.focusNode.requestFocus,
        child: Container(
          constraints: BoxConstraints(minHeight: LedgerTextField.heightOf(t)),
          padding: const EdgeInsets.symmetric(horizontal: LedgerSpacing.s16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.headRule)),
          ),
          child: Row(
            spacing: LedgerSpacing.s12,
            children: [
              ExcludeSemantics(
                child: Icon(
                  LucideIcons.search,
                  size: _glyph,
                  color: t.textSecondary,
                ),
              ),
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: field.controller,
                    builder: (context, value, child) => Stack(
                      alignment: AlignmentDirectional.centerStart,
                      children: [
                        if (value.text.isEmpty)
                          ExcludeSemantics(
                            child: Text(
                              hint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: words
                                  .copyWith(fontWeight: FontWeight.w400)
                                  .colored(t.textTertiary),
                            ),
                          ),
                        child!,
                      ],
                    ),
                    child: Semantics(
                      hint: hint,
                      child: TextField(
                        controller: field.controller,
                        focusNode: field.focusNode,
                        decoration: null,
                        maxLines: 1,
                        style: words.colored(t.textPrimary),
                        cursorColor: t.textPrimary,
                        cursorWidth: 1.5,
                        // Enter runs the lit act and the search keeps the
                        // focus: in onEditingComplete, never onSubmitted,
                        // whose submit restarts the text input of a field
                        // that keeps the focus (a browser's then takes no
                        // typing).
                        onEditingComplete: field.submit,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
    groupBuilder: (context, group) => Padding(
      padding: const EdgeInsets.fromLTRB(
        LedgerSpacing.s16,
        LedgerSpacing.s12,
        LedgerSpacing.s16,
        LedgerSpacing.s4,
      ),
      child: Semantics(
        header: true,
        child: Text(
          group.toUpperCase(),
          style: context.ledgerTheme.label.colored(
            context.ledgerTheme.textTertiary,
          ),
        ),
      ),
    ),
    itemBuilder: (context, command, states) => Row(
      children: [
        Expanded(
          child: LedgerOptionRow(label: command.label, states: states),
        ),
        if (command.shortcut case final keys?)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: LedgerSpacing.s16),
            child: LedgerKbd(keys.split('+')),
          ),
      ],
    ),
    emptyBuilder: (context) =>
        LedgerNoOption(RawWidgetsLocalizations.of(context).noResultsLabel),
  );

  static const double _paper = 6 * 48 + 8;
  static const double _glyph = 18;
}

/// Opens a [LedgerCommandPalette] of [commands] over the page on its raised
/// paper, 560 wide at most; an act runs once the palette has closed.
Future<void> showLedgerCommandPalette(
  BuildContext context, {
  required List<LedgerCommand> commands,
  String hint = 'Type an act or a place',
}) => showDesignCommandPalette(
  context: context,
  palette: (run) => LedgerCommandPalette(
    commands: commands,
    hint: hint,
    autofocus: true,
    onSelected: run,
  ).toDesign(),
  surfaceBuilder: (context, palette) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: LedgerSpacing.s16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _paletteMeasure),
      child: ledgerOptionPaper(context, palette),
    ),
  ),
);

/// The opened palette's widest.
const double _paletteMeasure = 560;
