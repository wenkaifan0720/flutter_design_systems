import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/menu_row.dart';
import '../../internal/paint.dart';
import '../../theme.dart';
import '../text-field/text_field.dart';

// A palette's caller gives its commands.
export 'package:ui_core/ui_core.dart' show RawCommand;

/// Opens a palette over the page that finds a page or an action of the
/// service by its words: a text field ([labelText]: "Find a page or
/// action" by default) over the [commands] that match what is typed, in
/// their groups, each worded, its shortcut at its end. The panel is the
/// dialog's card floating on its hairline and soft shadow, at most 560
/// wide: ui_core's [showDesignCommandPalette], Civic's painting.
///
/// The field takes the focus; Up and Down move the yellow plate through the
/// results, Enter runs the lit one, a press runs any; the palette closes,
/// the focus goes back, then the command runs. Escape and a press on the
/// scrim close it. A screen reader hears how many results there are as
/// they change.
///
/// It is a short way to what is already in plain sight: every command is
/// also a page's link or button (the service's navigation, a page's
/// action), never only here. Name its keys on the page with [CivicKbd]
/// where it has some ("Press Ctrl K to find a page").
///
/// Reads [CivicStyle]'s fill and edge (the panel), foreground, padding and
/// textStyle (the rows), by state: its `style:`, then
/// [CivicThemeData.commandPaletteStyle].
///
/// ```dart
/// showCivicCommandPalette(
///   context: context,
///   commands: [
///     RawCommand(label: 'Your applications', group: 'Pages', onPressed: () {}),
///     RawCommand(label: 'Apply for a permit', group: 'Actions', onPressed: () {}),
///   ],
/// );
/// ```
Future<void> showCivicCommandPalette({
  required BuildContext context,
  required List<RawCommand> commands,
  String labelText = 'Find a page or action',
  String? hintText,
  CivicStyle? style,
}) {
  final t = CivicTheme.of(context);
  return showDesignCommandPalette(
    context: context,
    barrierColor: t.isDark
        ? const Color(0xFF000000).withValues(alpha: 0.85)
        : const Color(0xFF0C1116).withValues(alpha: 0.6),
    // Its top stays put while the results change under the typing.
    alignment: Alignment.topCenter,
    palette: (run) => RawCommandPalette(
      commands: commands,
      onSelected: run,
      // Seven and a half rows: a longer list shows it goes on.
      maxHeight: 7.5 * CivicMetrics.controlHeight,
      fieldBuilder: (context, field) => Padding(
        padding: const EdgeInsets.all(CivicSpacing.s16),
        child: CivicTextField(
          controller: field.controller,
          focusNode: field.focusNode,
          labelText: labelText,
          hintText: hintText,
          textInputAction: TextInputAction.go,
          // Enter runs the lit command and the field keeps its input:
          // taken in onEditingComplete, with no onSubmitted.
          onEditingComplete: field.submit,
        ),
      ),
      groupBuilder: (context, group) {
        final c = context.civicTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            CivicSpacing.s16,
            CivicSpacing.s12,
            CivicSpacing.s16,
            CivicSpacing.s4,
          ),
          child: Semantics(
            header: true,
            child: Text(
              group,
              style: context.civicText.label.copyWith(color: c.textSecondary),
            ),
          ),
        );
      },
      itemBuilder: (context, command, states) => CivicMenuRow(
        label: command.label,
        states: {...states, if (!command.enabled) WidgetState.disabled},
        icon: command.data is IconData ? command.data! as IconData : null,
        glyphColumn: commands.any((c) => c.data is IconData),
        trailing: command.shortcut,
        style: style,
      ),
      emptyBuilder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          CivicSpacing.s16,
          CivicSpacing.s8,
          CivicSpacing.s16,
          CivicSpacing.s16,
        ),
        child: Text(
          RawWidgetsLocalizations.of(context).noResultsLabel,
          style: context.civicText.body.copyWith(
            color: context.civicTheme.textSecondary,
          ),
        ),
      ),
    ),
    surfaceBuilder: (context, palette) => CivicTheme(
      data: t,
      child: Builder(
        builder: (context) {
          final so = DesignStyleOf([style, t.commandPaletteStyle], const {});
          final top = (MediaQuery.sizeOf(context).height * 0.1).clamp(
            CivicSpacing.s16,
            CivicSpacing.s64 + CivicSpacing.s32,
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(
              CivicSpacing.s16,
              top,
              CivicSpacing.s16,
              CivicSpacing.s16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: DecoratedBox(
                decoration: civicFloating(
                  face: so.fill ?? t.background,
                  hairline: so.edge ?? t.rule,
                  dark: t.isDark,
                  radius: CivicMetrics.cardCorner,
                ),
                // The rows' faces stop inside the hairline.
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      CivicMetrics.cardCorner - 1,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: CivicSpacing.s8),
                      child: palette,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
