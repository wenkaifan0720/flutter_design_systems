import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/css_shadow.dart';
import '../../theme.dart';
import '../brand/brand.dart';
import '../engravings/engravings.dart';
import '../seal/seal.dart';

/// Which stock a [LedgerCardFace] is printed on: the [credit] card's ink
/// (its light print on the dark), the [debit] card's paper.
enum LedgerCardStock {
  /// The credit card's ink, its print light on the dark.
  credit,

  /// The debit card's paper.
  debit,
}

/// How large a [LedgerCardFace] stands: [regular] across its column, 216
/// tall (400 by 252 on the desktop), or [small] (264 by 166; 280 by 176).
enum LedgerCardSize {
  /// Across its column, 216 tall (400 by 252 on the desktop).
  regular,

  /// 264 by 166 (280 by 176 on the desktop).
  small,
}

/// A payment card's face, printed like a banknote (`.card-face`): its
/// stock, a guilloche rosette off its corner, the brand mark and [brand]
/// in the serif with the card's [kind], the engraved chip and the
/// contactless mark, the [number] masked to its last group, the [holder]
/// and the [account] at its foot. [frozen] lays a frost of hatched paper
/// over it, drops the account and presses the [seal] (the ink's Frozen)
/// across its corner. Read as its kind and last four.
///
/// ```dart
/// LedgerCardFace(brand: 'Keel', kind: 'Credit', number: const ['4242', '4242', '4242', '7730'], holder: 'MAREN HOLT', account: 'Keel Card')
/// ```
class LedgerCardFace extends StatelessWidget {
  /// The face of a card from [brand], numbered [number], held by [holder].
  const LedgerCardFace({
    required this.brand,
    required this.kind,
    required this.number,
    required this.holder,
    this.account,
    this.stock = LedgerCardStock.credit,
    this.size = LedgerCardSize.regular,
    this.frozen = false,
    this.seal,
    super.key,
  });

  /// The bank's name, beside its mark.
  final String brand;

  /// The card's kind (Credit, Debit).
  final String kind;

  /// The number's groups; all but the last are masked.
  final List<String> number;

  /// The holder's name, at the card's foot.
  final String holder;

  /// The account it draws on, at the card's foot; left out when frozen.
  final String? account;

  /// The stock it is printed on.
  final LedgerCardStock stock;

  /// How large it stands.
  final LedgerCardSize size;

  /// Whether the card is frozen, frosted over with its [seal] pressed.
  final bool frozen;

  /// Pressed across the frozen card's corner.
  final LedgerSeal? seal;

  // The ink stock's own print, as the source's stylesheet sets it.
  static const Color _inkStock = Color(0xFF141A1F);
  static const Color _inkStockLit = Color(0xFF28333C);
  static const Color _print = Color(0xFFEFE9DD);
  static const Color _rosetteOnInk = Color(0xFF7FAF97);
  static const Color _markOnInk = Color(0xFFA8CDB9);
  static const Color _paperStock = Color(0xFFFBF9F4);
  static const Color _paperStockLow = Color(0xFFEFE8DA);
  static const Color _frost = Color(0xFFF2EDE3);

  /// The day book of [night]'s preset (Ledger's own for a theme made
  /// [LedgerThemeData.from] colours).
  static LedgerThemeData _dayOf(LedgerThemeData night) =>
      LedgerThemeData.presets.contains(night.id)
      ? LedgerThemeData.preset(night.id, Brightness.light)
      : LedgerThemeData.light();

  @override
  Widget build(BuildContext context) {
    final page = context.ledgerTheme;
    final paper = stock == LedgerCardStock.debit;
    // The debit card's cream is printed plastic, the same by lamplight: its
    // inks are the day book's, never the night's light inks on cream.
    final t = paper && page.isDark ? _dayOf(page) : page;
    final wide = LedgerLayout.isWide(context);
    final small = size == LedgerCardSize.small;
    final ({
      double w,
      double h,
      EdgeInsets pad,
      double r,
      double brandSize,
      double mark,
      double brandGap,
      Size chip,
      double nfc,
      double num,
      double numGap,
      double foot,
      double rosTop,
      double rosRight,
      double ros,
    })
    m = small
        ? (
            w: wide ? 280 : 264,
            h: wide ? 176 : 166,
            pad: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            r: 12,
            brandSize: 21,
            mark: 20,
            brandGap: 7,
            chip: const Size(34, 26),
            nfc: 18,
            num: 12.5,
            numGap: 9,
            foot: 9,
            rosTop: -80,
            rosRight: -100,
            ros: 250,
          )
        : wide
        ? (
            w: 400,
            h: 252,
            pad: const EdgeInsets.fromLTRB(24, 22, 24, 20),
            r: 16,
            brandSize: 30,
            mark: 28,
            brandGap: 8,
            chip: const Size(46, 35),
            nfc: 22,
            num: 17,
            numGap: 14,
            foot: 11,
            rosTop: -110,
            rosRight: -130,
            ros: 370,
          )
        : (
            w: double.infinity,
            h: 216,
            pad: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            r: 14,
            brandSize: 26,
            mark: 24,
            brandGap: 8,
            chip: const Size(42, 32),
            nfc: 22,
            num: 15,
            numGap: 12,
            foot: 10.5,
            rosTop: -96,
            rosRight: -118,
            ros: 320,
          );
    final ink = paper ? t.textPrimary : _print;
    Color print(double a) =>
        paper ? t.textTertiary : _print.withValues(alpha: a);
    final mono = t.amount.tracked(0);
    final kindStyle = mono
        .sized(11)
        .line(14)
        .tracked(.18)
        .colored(paper ? t.textTertiary : print(.72));
    final footStyle = mono
        .sized(m.foot)
        .line(14)
        .tracked(.16)
        .colored(paper ? t.textTertiary : print(.78));
    final numStyle = mono.sized(m.num).line(20).tracked(.1);
    final radius = BorderRadius.circular(m.r);
    final face = Container(
      width: m.w,
      height: m.h,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: paper ? _paperStockLow : _inkStock,
        boxShadow: paper
            ? [
                ledgerShadow(color: const Color(0x0F141A1F), y: 1, blur: 1),
                ledgerShadow(
                  color: const Color(0x73141A1F),
                  y: 20,
                  blur: 32,
                  spread: -22,
                ),
              ]
            : [
                ledgerShadow(color: const Color(0x2E141A1F), y: 1, blur: 1),
                ledgerShadow(
                  color: const Color(0xB3141A1F),
                  y: 26,
                  blur: 40,
                  spread: -24,
                ),
              ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        // The inset 1px ring.
        border: Border.all(
          color: paper ? t.border : _print.withValues(alpha: .07),
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: paper ? _PaperStockPainter() : _InkStockPainter(),
              ),
            ),
            Positioned(
              top: m.rosTop,
              right: m.rosRight,
              child: Opacity(
                opacity: paper ? .2 : .3,
                child: LedgerGuilloche(
                  size: m.ros,
                  color: paper ? t.accent : _rosetteOnInk,
                ),
              ),
            ),
            Padding(
              padding: m.pad,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: m.brandGap,
                        children: [
                          LedgerBrandMark(
                            size: m.mark,
                            color: paper ? t.accent : _markOnInk,
                          ),
                          Text(
                            brand,
                            style: t.figureSmall
                                .sized(m.brandSize)
                                .line(m.brandSize)
                                .tracked(-.01)
                                .colored(ink),
                          ),
                        ],
                      ),
                      Text(kind.toUpperCase(), style: kindStyle),
                    ],
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      LedgerCardChip(
                        width: m.chip.width,
                        height: m.chip.height,
                        color: paper
                            ? t.textSecondary
                            : _print.withValues(alpha: .82),
                      ),
                      Icon(
                        LucideIcons.nfc,
                        size: m.nfc,
                        color: paper
                            ? t.textTertiary
                            : _print.withValues(alpha: .6),
                      ),
                    ],
                  ),
                  Row(
                    spacing: m.numGap,
                    children: [
                      for (var i = 0; i < number.length; i++)
                        Text(
                          i == number.length - 1 ? number[i] : '••••',
                          style: numStyle.colored(
                            i == number.length - 1
                                ? ink
                                : (paper
                                      ? t.textFaint
                                      : _print.withValues(alpha: .5)),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 12,
                    children: [
                      Flexible(
                        child: Text(
                          holder.toUpperCase(),
                          maxLines: 1,
                          style: footStyle,
                        ),
                      ),
                      if (!frozen && account != null)
                        Text(account!.toUpperCase(), style: footStyle),
                    ],
                  ),
                ],
              ),
            ),
            if (frozen) const Positioned.fill(child: _Frost(_frost)),
          ],
        ),
      ),
    );
    // A picture of the plastic: its lettering is printed at its size, as
    // the card's is, and the label says it (the details, shown, follow the
    // reader's text size).
    final named = Semantics(
      label: '$kind card ending ${number.last}${frozen ? ', frozen' : ''}',
      excludeSemantics: true,
      child: MediaQuery.withNoTextScaling(child: face),
    );
    // `.card-seal`: right −4, bottom −38 (−18, −44 from 1024).
    // A card is printed: it reads left to right in any page, its seal at
    // its right.
    final sealed = Directionality(
      textDirection: TextDirection.ltr,
      child: !frozen || seal == null
          ? named
          : Stack(
              clipBehavior: Clip.none,
              children: [
                named,
                Positioned(
                  right: wide ? -18 : -4,
                  bottom: wide ? -44 : -38,
                  // Pressed on paper of its own across the corner, as a sent
                  // cheque's seal is: the card's edge, shadow and frost break
                  // round it, ink never over ink.
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.ledgerTheme.background,
                      shape: BoxShape.circle,
                    ),
                    child: seal!,
                  ),
                ),
              ],
            ),
    );
    if (m.w.isInfinite) return sealed;
    // A face of its own width (`.card-sm` 264, `.card-face` 400 from 1024)
    // stands at its room's start as the source's flex item does (`flex:
    // none`), never stretched across a column that holds it tight.
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: sealed,
    );
  }
}

/// The ink stock's light: `radial-gradient(120% 140% at 100% 0%, #28333C
/// 0%, #141A1F 62%)`, an ellipse from the top end corner.
class _InkStockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rx = size.width * 1.2, ry = size.height * 1.4;
    canvas
      ..save()
      ..translate(size.width, 0)
      ..scale(1, ry / rx)
      ..drawRect(
        Rect.fromLTWH(-size.width, 0, size.width, size.height * rx / ry),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            rx,
            const [LedgerCardFace._inkStockLit, LedgerCardFace._inkStock],
            const [0, .62],
          ),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_InkStockPainter old) => false;
}

/// A CSS `linear-gradient([deg], …)` over [size]: its line through the
/// centre at that angle, as long as the box reaches along it.
Shader _cssLinear(Size size, double deg, List<Color> colors) {
  final a = deg * math.pi / 180;
  final dir = Offset(math.sin(a), -math.cos(a));
  final half = (size.width * dir.dx.abs() + size.height * dir.dy.abs()) / 2;
  final c = size.center(Offset.zero);
  return ui.Gradient.linear(c - dir * half, c + dir * half, colors);
}

/// The debit card's paper stock: `linear-gradient(155deg, #FBF9F4,
/// #EFE8DA)`.
class _PaperStockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = _cssLinear(size, 155, const [
        LedgerCardFace._paperStock,
        LedgerCardFace._paperStockLow,
      ]),
  );

  @override
  bool shouldRepaint(_PaperStockPainter old) => false;
}

/// The frost over a frozen card (`.card-frost`): a wash of the page's
/// paper (.66 to .5 at 160°) and over it a hatch of it at .26, a line 1
/// wide every 7 across 135°.
class _Frost extends StatelessWidget {
  const _Frost(this.paper);

  final Color paper;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _FrostPainter(paper));
}

class _FrostPainter extends CustomPainter {
  _FrostPainter(this.paper);

  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final c = box.center;
    canvas.drawRect(
      box,
      Paint()
        ..shader = _cssLinear(size, 160, [
          paper.withValues(alpha: .66),
          paper.withValues(alpha: .5),
        ]),
    );
    // repeating-linear-gradient(135deg, 0 0 6px, .26 6px 7px): bands 1
    // wide every 7 along the 135° line, running across it.
    final b = 135 * math.pi / 180;
    final along = Offset(math.sin(b), -math.cos(b));
    final reach =
        (size.width * along.dx.abs() + size.height * along.dy.abs()) / 2;
    final start = c - along * reach;
    final across = Offset(-along.dy, along.dx);
    final line = Paint()
      ..color = paper.withValues(alpha: .26)
      ..strokeWidth = 1;
    final span = size.longestSide * 2;
    for (var d = 6.5; d < reach * 2; d += 7) {
      final p = start + along * d;
      canvas.drawLine(p - across * span, p + across * span, line);
    }
  }

  @override
  bool shouldRepaint(_FrostPainter old) => old.paper != paper;
}

/// A card's details shown on its ink (`.card-details`): under the label its
/// [number] in four groups spread across in the mono at 21, then under a
/// faint rule its [expiry], its [cvc] and the [name] on it, each under its
/// label. Printed as the card is (the ink stock's light from its top end
/// corner), 12 round. The card details sheet's body; 12 under the sheet's
/// head.
///
/// ```dart
/// LedgerCardDetails(number: const ['4242', '4242', '4242', '7730'], expiry: '09/29', cvc: '317', name: 'Maren Holt')
/// ```
class LedgerCardDetails extends StatelessWidget {
  /// A card's [number], [expiry], [cvc] and [name].
  const LedgerCardDetails({
    required this.number,
    required this.expiry,
    required this.cvc,
    required this.name,
    this.numberLabel = 'Card number',
    this.expiryLabel = 'Expires',
    this.cvcLabel = 'CVC',
    this.nameLabel = 'Name on card',
    super.key,
  });

  /// The number's groups, all shown.
  final List<String> number;

  /// The month and year it expires (08/29).
  final String expiry;

  /// The security code on its back.
  final String cvc;

  /// The name on the card, as the owner writes it.
  final String name;

  /// The number's label.
  final String numberLabel;

  /// The expiry's label.
  final String expiryLabel;

  /// The security code's label.
  final String cvcLabel;

  /// The name's label.
  final String nameLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    const print = LedgerCardFace._print;
    // `.card-details .label`: rgba(239, 233, 221, .6).
    final label = t.label.colored(print.withValues(alpha: .6));
    // `.cd-v`: margin-top 4px, 500 16px/22px var(--mono); `.cd-name`: the
    // sans, 500, nowrap.
    final value = t.amount.sized(16).line(22).tracked(0).colored(print);
    // At a large text size the number's groups flow from the start as one
    // number, and the expiry, the code and the name turn under one another
    // when they do not fit one line, the name whole.
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    Widget cell(String key, String v, {bool sans = false}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(key.toUpperCase(), style: label),
        const SizedBox(height: 4),
        Text(
          v,
          softWrap: larger && sans,
          style: sans ? t.body.sized(16).line(22).medium.colored(print) : value,
        ),
      ],
    );
    const radius = BorderRadius.all(Radius.circular(12));
    // The card's details are printed as the card is: left to right in any
    // page.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        // `.card-details`: border-radius 12px, overflow hidden.
        borderRadius: radius,
        child: CustomPaint(
          // background: radial-gradient(120% 140% at 100% 0%, #28333C 0%,
          // #141A1F 62%), #141A1F.
          painter: _InkStockPainter(),
          child: Padding(
            // `.card-details`: padding 18px 18px 16px.
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(numberLabel.toUpperCase(), style: label),
                // `.cd-num`: margin-top 8px, flex, space-between, 500
                // 21px/28px var(--mono), letter-spacing .02em.
                const SizedBox(height: 8),
                Semantics(
                  label: number.join(' '),
                  excludeSemantics: true,
                  // Across the line; at a large text size the groups wrap
                  // whole onto a second, from the start.
                  child: Wrap(
                    alignment: larger
                        ? WrapAlignment.start
                        : WrapAlignment.spaceBetween,
                    spacing: 12,
                    children: [
                      for (final g in number)
                        Text(
                          g,
                          style: t.amount
                              .sized(21)
                              .line(28)
                              .tracked(.02)
                              .colored(print),
                        ),
                    ],
                  ),
                ),
                // `.cd-grid`: margin-top 16px, padding-top 14px, border-top
                // 1px solid rgba(239, 233, 221, .16); columns auto auto
                // minmax(0, 1fr), 28px apart.
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: print.withValues(alpha: .16)),
                    ),
                  ),
                  child: larger
                      ? Wrap(
                          spacing: 28,
                          runSpacing: 14,
                          children: [
                            cell(expiryLabel, expiry),
                            cell(cvcLabel, cvc),
                            cell(nameLabel, name, sans: true),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 28,
                          children: [
                            cell(expiryLabel, expiry),
                            cell(cvcLabel, cvc),
                            Expanded(child: cell(nameLabel, name, sans: true)),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
