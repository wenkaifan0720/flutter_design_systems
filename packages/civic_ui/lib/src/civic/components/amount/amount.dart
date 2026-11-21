import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../format.dart';

/// A currency an amount is in: its [symbol] on the page, and its names
/// for a screen reader, so "€62.50" is read whole as "62 euros 50 cents".
@immutable
class CivicCurrency {
  /// A currency shown as [symbol] and read as [one] or [many], its
  /// hundredth as [minorOne] or [minorMany].
  const CivicCurrency({
    required this.symbol,
    required this.one,
    required this.many,
    required this.minorOne,
    required this.minorMany,
  });

  /// The euro.
  static const euro = CivicCurrency(
    symbol: '€',
    one: 'euro',
    many: 'euros',
    minorOne: 'cent',
    minorMany: 'cents',
  );

  /// The pound sterling.
  static const pound = CivicCurrency(
    symbol: '£',
    one: 'pound',
    many: 'pounds',
    minorOne: 'penny',
    minorMany: 'pence',
  );

  /// The dollar.
  static const dollar = CivicCurrency(
    symbol: r'$',
    one: 'dollar',
    many: 'dollars',
    minorOne: 'cent',
    minorMany: 'cents',
  );

  /// Its sign on the page: "€".
  final String symbol;

  /// One of it, read: "euro".
  final String one;

  /// More than one, read: "euros".
  final String many;

  /// One hundredth of it, read: "cent".
  final String minorOne;

  /// More than one hundredth, read: "cents".
  final String minorMany;

  /// [minorUnits] as a screen reader should hear it: "62 euros 50 cents",
  /// "minus 5 euros".
  String read(int minorUnits) {
    final whole = minorUnits.abs() ~/ 100;
    final part = minorUnits.abs() % 100;
    final words = [
      if (whole > 0 || part == 0) CivicFormat.plural(whole, one, many),
      if (part > 0) CivicFormat.plural(part, minorOne, minorMany),
    ].join(' ');
    return minorUnits < 0 ? 'minus $words' : words;
  }

  @override
  bool operator ==(Object other) =>
      other is CivicCurrency &&
      other.symbol == symbol &&
      other.one == one &&
      other.many == many &&
      other.minorOne == minorOne &&
      other.minorMany == minorMany;

  @override
  int get hashCode => Object.hash(symbol, one, many, minorOne, minorMany);
}

/// An amount of money in words' place: [minorUnits] in [currency], in
/// tabular figures so amounts in a column line up ("€62.50", "−€5"), read
/// whole by a screen reader ("62 euros 50 cents"). Its figures are the
/// reader's digits and separators (Arabic's "€٦٢٫٥٠"), kept in their order
/// inside right-to-left words.
///
/// Its style is the words' around it; [textStyle] over that.
///
/// ```dart
/// CivicAmount(6250)
/// ```
class CivicAmount extends StatelessWidget {
  /// [minorUnits] (cents) in [currency].
  const CivicAmount(
    this.minorUnits, {
    super.key,
    this.currency = CivicCurrency.euro,
    this.cents = false,
    this.textStyle,
  });

  /// The amount in hundredths: 6250 is €62.50.
  final int minorUnits;

  /// Its currency.
  final CivicCurrency currency;

  /// Whether a whole amount still shows its cents: "€60.00".
  final bool cents;

  /// The figures' style, over the words' around it.
  final TextStyle? textStyle;

  /// [minorUnits] as the page shows it: "€62.50", "−€5"; with [words], in
  /// the reader's digits and separators.
  static String show(
    int minorUnits, {
    CivicCurrency currency = CivicCurrency.euro,
    bool cents = false,
    RawWidgetsLocalizations? words,
  }) {
    final magnitude = minorUnits.abs();
    final String shown;
    if (words == null) {
      shown = CivicFormat.money(
        magnitude,
        symbol: currency.symbol,
        cents: cents,
      );
    } else {
      final places = cents || magnitude % 100 != 0 ? 2 : 0;
      final figure = words.formatDecimal(
        magnitude / 100,
        fractionDigits: places,
      );
      shown = '${currency.symbol}$figure';
    }
    return minorUnits < 0 ? '−$shown' : shown;
  }

  @override
  Widget build(BuildContext context) {
    final shown = show(
      minorUnits,
      currency: currency,
      cents: cents,
      words: RawWidgetsLocalizations.of(context),
    );
    return Semantics(
      label: currency.read(minorUnits),
      excludeSemantics: true,
      child: Text(
        // Isolated, so the sign, the symbol and the figure keep their
        // order in right-to-left words.
        '\u2068$shown\u2069',
        style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])
            .merge(textStyle),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('minorUnits', minorUnits))
      ..add(StringProperty('currency', currency.symbol))
      ..add(FlagProperty('cents', value: cents, ifTrue: 'cents'));
  }
}
