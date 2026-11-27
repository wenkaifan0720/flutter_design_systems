// Each name ledger_ui 0.8.0 renamed, used once; dart fix renames it (ledger_ui_080.dart.expect).
import 'package:ledger_ui/ledger_parts.dart';

dynamic d;

void constructors() {
  LedgerPressable(onTap: d, child: d, label: d);
  LedgerRadioPress<Object>(value: d, enabled: d, child: d, label: d);
  LedgerMoreLink(d, onTap: d, label: d);
  LedgerAvatarStack(names: d, label: d);
  LedgerAvatar(initials: d, label: d);
  LedgerBadge(child: d, label: d);
  LedgerCheck(value: d, label: d);
  LedgerChipRow(children: d, label: d);
  LedgerFilters<Object>(options: d, value: d, label: d);
  LedgerWeekStrip(days: d, label: d);
  LedgerNavigationFrame(
    destinations: d,
    selectedIndex: d,
    onDestinationSelected: d,
    body: d,
  );
  LedgerThemeData.contrast(d, d);
}

void fields(
  LedgerPressable a0,
  LedgerRadioPress<Object> a1,
  LedgerMoreLink a2,
  LedgerAvatarStack a3,
  LedgerAvatar a4,
  LedgerBadge a5,
  LedgerCheck a6,
  LedgerChipRow a7,
  LedgerFilters<Object> a8,
  LedgerToggleGroup<Object> a9,
  LedgerWeekStrip a10,
) {
  a0.label;
  a1.label;
  a2.label;
  a3.label;
  a4.label;
  a5.label;
  a6.label;
  a7.label;
  a8.label;
  a9.label;
  a10.label;
}
