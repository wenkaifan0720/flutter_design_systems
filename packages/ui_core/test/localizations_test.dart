import 'package:flutter/cupertino.dart' show CupertinoApp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// An app's own words: Default's English but for the split view's handle.
class _French extends DefaultDesignLocalizations {
  const _French();

  @override
  String get splitViewHandleLabel => 'Redimensionner';
}

class _FrenchDelegate extends LocalizationsDelegate<DesignLocalizations> {
  const _FrenchDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'fr';

  @override
  Future<DesignLocalizations> load(Locale locale) =>
      SynchronousFuture<DesignLocalizations>(const _French());

  @override
  bool shouldReload(_FrenchDelegate old) => false;
}

Widget _split({String? semanticLabel}) => SizedBox(
  width: 400,
  height: 200,
  child: DesignSplitView(
    first: const SizedBox.expand(),
    second: const SizedBox.expand(),
    semanticLabel: semanticLabel,
    dividerBuilder: (context, states, axis) => const SizedBox.expand(),
  ),
);

void main() {
  test('English: every word, and the messages counted', () {
    const en = DefaultDesignLocalizations();
    expect(en.carouselLabel, 'Carousel');
    expect(en.carouselSlideLabel(1, 3), 'Slide 2 of 3');
    expect(en.colorAreaLabel, 'Saturation and brightness');
    expect(DesignColorChannel.values.map(en.colorChannelLabel), [
      'Hue',
      'Saturation',
      'Brightness',
      'Alpha',
    ]);
    expect(en.commandPaletteLabel, 'Commands');
    expect(en.commandPaletteBarrierLabel, 'Close commands');
    expect([0, 1, 4].map(en.commandPaletteResultsMessage), [
      'No results',
      '1 result',
      '4 results',
    ]);
    expect(DesignSortDirection.values.map(en.dataTableSortedHint), [
      'sorted ascending',
      'sorted descending',
    ]);
    expect(en.formatFullDate(DateTime(2025, 3, 3)), 'Monday, 3 March 2025');
    expect(en.formatMonthYear(DateTime(2025, 12)), 'December 2025');
    expect(
      [for (var d = 1; d <= 7; d++) en.formatShortWeekday(d)],
      ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'],
    );
    expect(en.firstDayOfWeek, DateTime.sunday);
    expect(en.requiredHint, 'required');
    expect([1, 2].map(en.formProblemsMessage), [
      '1 field needs attention',
      '2 fields need attention',
    ]);
    expect(en.showPasswordLabel, 'Show password');
    expect(en.hidePasswordLabel, 'Hide password');
    expect(en.menuBarLabel, 'Menu bar');
    expect(en.refreshLabel, 'Refresh');
    expect(en.refreshingMessage, 'Refreshing');
    expect(en.refreshedMessage, 'Refreshed');
    expect(en.rangeSliderStartLabel, 'Minimum');
    expect(en.rangeSliderEndLabel, 'Maximum');
    expect(
      en.reorderableListMovedMessage('Milk', 2, 5),
      'Moved Milk to position 2 of 5',
    );
    expect(en.sideSheetBarrierLabel, 'Close sheet');
    expect(en.splitButtonMenuLabel, 'More options');
    expect(en.splitViewHandleLabel, 'Resize');
    expect(en.tagInputDeleteLabel, 'Remove');
    expect(en.toasterRegionLabel, 'Notifications');
    expect(en.treeLevelHint(2, 1, 4), 'level 2, 1 of 4');
  });

  test('English: the general words a look says by itself', () {
    const en = DefaultDesignLocalizations();
    expect(
      [
        en.cancelButtonLabel,
        en.okButtonLabel,
        en.closeButtonLabel,
        en.clearButtonTooltip,
        en.backButtonTooltip,
        en.deleteButtonTooltip,
        en.moreButtonTooltip,
        en.showMenuTooltip,
        en.searchFieldLabel,
        en.modalBarrierDismissLabel,
        en.currentDateLabel,
        en.previousMonthTooltip,
        en.nextMonthTooltip,
        en.previousPageTooltip,
        en.nextPageTooltip,
        en.collapsedIconTapHint,
        en.expandedIconTapHint,
        en.showMoreLabel,
        en.showLessLabel,
        en.selectedLabel,
        en.loadingLabel,
        en.noResultsLabel,
      ],
      [
        'Cancel',
        'OK',
        'Close',
        'Clear',
        'Back',
        'Delete',
        'More',
        'Show menu',
        'Search',
        'Dismiss',
        'Today',
        'Previous month',
        'Next month',
        'Previous page',
        'Next page',
        'Expand',
        'Collapse',
        'Show more',
        'Show less',
        'Selected',
        'Loading',
        'No results',
      ],
    );
    expect([0, 1, 3].map(en.selectedRowCountTitle), [
      'No items selected',
      '1 item selected',
      '3 items selected',
    ]);
    expect(en.positionLabel(2, 5), '2 of 5');
  });

  testWidgets('under MaterialApp, CupertinoApp and WidgetsApp with nothing '
      'registered, the words are English', (tester) async {
    for (final app in <Widget Function(Widget home)>[
      (home) => MaterialApp(home: home),
      (home) => CupertinoApp(home: home),
      harness,
    ]) {
      DesignLocalizations? words;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) {
              words = DesignLocalizations.of(context);
              return Text(words!.cancelButtonLabel);
            },
          ),
        ),
      );
      expect(words, isA<DefaultDesignLocalizations>());
      expect(find.text('Cancel'), findsOneWidget);
    }
  });

  testWidgets('a translation that extends the English keeps a word it does '
      'not translate in English', (tester) async {
    late DesignLocalizations words;
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: const Locale('fr'),
            delegates: const [_FrenchDelegate()],
            child: Builder(
              builder: (context) {
                words = DesignLocalizations.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(words.splitViewHandleLabel, 'Redimensionner');
    expect(words.cancelButtonLabel, 'Cancel');
  });

  test(
    'the delegate loads English for any locale, and never reloads',
    () async {
      const delegate = DefaultDesignLocalizations.delegate;
      expect(delegate.isSupported(const Locale('ja')), isTrue);
      expect(
        await delegate.load(const Locale('en')),
        isA<DefaultDesignLocalizations>(),
      );
      expect(delegate.shouldReload(delegate), isFalse);
      expect(delegate.toString(), 'DefaultDesignLocalizations.delegate(en)');
    },
  );

  testWidgets('with no DesignLocalizations delegate, a behaviour says '
      'English', (tester) async {
    final semantics = tester.ensureSemantics();
    late DesignLocalizations words;
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) {
            words = DesignLocalizations.of(context);
            return _split();
          },
        ),
      ),
    );
    expect(words, isA<DefaultDesignLocalizations>());
    expect(find.bySemanticsLabel('Resize'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('an app\'s delegate gives a behaviour its words; a word '
      'passed in wins over both', (tester) async {
    final semantics = tester.ensureSemantics();
    Widget app(Widget child) => harness(
      Builder(
        builder: (context) => Localizations.override(
          context: context,
          locale: const Locale('fr'),
          delegates: const [_FrenchDelegate()],
          child: child,
        ),
      ),
    );
    await tester.pumpWidget(app(_split()));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Redimensionner'), findsOneWidget);
    expect(find.bySemanticsLabel('Resize'), findsNothing);

    await tester.pumpWidget(app(_split(semanticLabel: 'Taille')));
    expect(find.bySemanticsLabel('Taille'), findsOneWidget);
    semantics.dispose();
  });
}
