import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

export 'package:ledger_ui/ledger_ui.dart' show ledgerLoadFonts;

Widget wrapLook(Brightness brightness, Widget child) {
  final theme = brightness == Brightness.dark
      ? LedgerThemeData.dark()
      : LedgerThemeData.light();
  return LedgerTheme(
    data: theme,
    child: ColoredBox(
      color: theme.background,
      child: DefaultTextStyle.merge(style: theme.body, child: child),
    ),
  );
}
