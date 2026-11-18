// The routes' words: Flutter's own Material words in every locale, a tab's
// place in the locale's digits.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

void main() {
  DesignLocalizations l(String language) =>
      DesignLocalizations.forLocale(Locale(language));

  test('English, the defaults', () {
    const en = DefaultDesignLocalizations();
    expect(en.dialogLabel, 'Dialog');
    expect(en.alertDialogLabel, 'Alert');
    expect(en.bottomSheetLabel, 'Bottom Sheet');
    expect(en.drawerLabel, 'Navigation menu');
    expect(en.tabLabel(tabIndex: 2, tabCount: 5), 'Tab 2 of 5');
    expect(en.dragHandleLabel, 'Drag handle');
  });

  test('Flutter\'s own words in each locale', () {
    expect(l('de').dialogLabel, 'Dialogfeld');
    expect(l('de').alertDialogLabel, 'Benachrichtigung');
    expect(l('de').bottomSheetLabel, 'Ansicht am unteren Rand');
    expect(l('de').drawerLabel, 'Navigationsmenü');
    expect(l('ja').dialogLabel, 'ダイアログ');
    expect(l('ar').alertDialogLabel, 'تنبيه');
  });

  test('ui_core\'s own word for a drag handle, in each locale', () {
    expect(l('de').dragHandleLabel, 'Ziehpunkt');
    expect(l('ja').dragHandleLabel, 'ドラッグ ハンドル');
    expect(l('zh').dragHandleLabel, '拖动手柄');
    expect(
      DesignLocalizations.forLocale(const Locale('zh', 'TW')).dragHandleLabel,
      '拖曳控點',
    );
  });

  test('a tab\'s place takes its values, in the locale\'s digits', () {
    expect(l('de').tabLabel(tabIndex: 1, tabCount: 3), 'Tab 1 von 3');
    expect(l('ja').tabLabel(tabIndex: 1, tabCount: 3), 'タブ: 1/3');
    expect(l('ar').tabLabel(tabIndex: 2, tabCount: 4), 'علامة التبويب ٢ من ٤');
  });
}
