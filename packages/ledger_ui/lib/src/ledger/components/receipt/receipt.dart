import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/narrow.dart';
import '../../internal/on_cheque.dart';
import '../../theme.dart';
import '../engravings/engravings.dart';
import '../money/money.dart';
import '../seal/seal.dart';
import '../structure/structure.dart';

/// A slip of the light paper (`.sheet`): 6 round, lifted off the page by
/// its shadow. What a receipt, a cheque and a memo are printed on.
///
/// ```dart
/// LedgerSlip(child: memo)
/// ```
class LedgerSlip extends StatelessWidget {
  /// A slip holding [child].
  const LedgerSlip({required this.child, this.padding, super.key});

  /// What is printed on the slip.
  final Widget child;

  /// The room round [child]; null takes the slip's own.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    // A card for the keyline check: what is printed on it starts and ends
    // on its side room.
    return DesignKeylineRegion(
      label: 'slip',
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(t.smallRadius),
          boxShadow: t.paperShadow,
        ),
        child: child,
      ),
    );
  }
}

/// The slip's sides: 20 (36 from 1024), as a receipt and a cheque inset
/// their words.
double _side(bool wide) => wide ? 36 : 20;

/// A slip's band of guilloche across its head (`.receipt-band`): 14 tall,
/// the green at .5, its top corners the slip's. It stands first on a
/// [LedgerSlip], edge to edge (outside the slip's side room), over a
/// [LedgerSlipHead]: how a page prints its own slip (a new goal's form, a
/// member's card) as the receipt, the cheque and the statement are
/// printed. It says nothing.
///
/// ```dart
/// LedgerSlip(child: Column(children: [const LedgerSlipBand(), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [const LedgerSlipHead('Keel · New goal', 'Savings'), ...fields]))]))
/// ```
class LedgerSlipBand extends StatelessWidget {
  /// The band across a slip's head.
  const LedgerSlipBand({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    // `.receipt-band`: height 14, color var(--green), opacity .5, radius
    // var(--r-sheet) var(--r-sheet) 0 0.
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(t.smallRadius),
        ),
        child: Opacity(
          opacity: .5,
          child: LedgerGuillocheBand(color: t.accent),
        ),
      ),
    );
  }
}

/// The tear line across a slip (`.stub`): a half-round notch cut from
/// each edge (9 by 18, the page's paper showing) and the perforation
/// between them, 14 in from each (22 from 1024). It says nothing.
///
/// ```dart
/// LedgerStub()
/// ```
class LedgerStub extends StatelessWidget {
  /// The tear line across a slip.
  const LedgerStub({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    return ExcludeSemantics(
      child: SizedBox(
        height: 18,
        child: Row(
          children: [
            CustomPaint(
              size: const Size(9, 18),
              painter: _NotchPainter(t, start: true),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 22 : 14),
                child: const LedgerPerforation(),
              ),
            ),
            CustomPaint(
              size: const Size(9, 18),
              painter: _NotchPainter(t, start: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotchPainter extends CustomPainter {
  _NotchPainter(this.t, {required this.start});

  final LedgerThemeData t;
  final bool start;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    // The cut reaches over the slip's 1 px edge, so the edge stops at the
    // notch rather than running across its mouth.
    final shape = RRect.fromRectAndCorners(
      Rect.fromLTWH(start ? -1 : 0, 0, size.width + 1, size.height),
      topRight: start ? r : Radius.zero,
      bottomRight: start ? r : Radius.zero,
      topLeft: start ? Radius.zero : r,
      bottomLeft: start ? Radius.zero : r,
    );
    canvas.drawRRect(shape, Paint()..color = t.background);
    // `inset ∓1px 0 0 rgba(20, 26, 31, .08)`: a hair along its round edge.
    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRRect(
        shape.shift(Offset(start ? -1 : 1, 0)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0x14141A1F),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_NotchPainter old) => old.t != t || old.start != start;
}

/// A slip's head (`.receipt-head`): what the slip is ([start]: its kind)
/// and its number, date or class at the far side ([end]), in the mono
/// capitals at 10; 12 under the [LedgerSlipBand] (16 from 1024), 18 over
/// what follows (26). Inside the slip's side room.
///
/// ```dart
/// LedgerSlipHead('Keel · New goal', 'Savings')
/// ```
class LedgerSlipHead extends StatelessWidget {
  /// A slip's head: [start] and [end].
  const LedgerSlipHead(this.start, this.end, {super.key});

  /// The slip's kind (Keel · Transaction), at its start.
  final String start;

  /// Its number, date or class (No. T280812BLUE, Savings), at its end.
  final String end;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    // `.receipt-head .meta`: 10 in the source, set 11 here (no words under
    // 11 px), on the meta's 16px line (`.meta`: 11px/16px);
    // `.receipt-head`: padding 12px 0 18px (16px 0 26px from 1024), gap 12px.
    final style = t.meta.sized(11).line(16);
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    return Padding(
      padding: EdgeInsets.only(top: wide ? 16 : 12, bottom: wide ? 26 : 18),
      // At a large text size the end turns under the start when the two do
      // not fit one line, rather than squeeze the kind's words apart.
      child: larger
          ? Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 2,
              children: [
                Text(start.toUpperCase(), style: style),
                Text(end.toUpperCase(), style: style),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 12,
              children: [
                Flexible(child: Text(start.toUpperCase(), style: style)),
                Text(end.toUpperCase(), style: style),
              ],
            ),
    );
  }
}

/// A transaction's receipt (`.receipt`), printed on a [LedgerSlip]: the
/// guilloche band, its [kind] and [number], the [leading] beside the [name]
/// in the serif and its [subtitle], the engraved [figure] with the [seal]
/// pressed at its end (both sized for a receipt), the tear line, then its
/// [details] (key and value lines).
///
/// ```dart
/// LedgerReceipt(kind: 'Keel · Transaction', number: 'No. T280812BLUE', leading: const LedgerMonogram('Blue Fern Café', size: LedgerMonogramSize.record), name: 'Blue Fern Café', subtitle: 'Dining out · Keel Card ··7730', figure: const LedgerFigure(-6.75), seal: const LedgerSeal(kicker: 'Keel Card', value: 'Pending', foot: 'Oct 28', tone: LedgerSealTone.plain), details: const [LedgerKeyValue('Status', 'Pending')])
/// ```
class LedgerReceipt extends StatelessWidget {
  /// A receipt for [name]: [figure], [seal] and [details].
  const LedgerReceipt({
    required this.kind,
    required this.number,
    required this.leading,
    required this.name,
    required this.subtitle,
    required this.figure,
    required this.seal,
    required this.details,
    super.key,
  });

  /// What the slip is (Keel · Transaction).
  final String kind;

  /// The receipt's number (No. T280812BLUE).
  final String number;

  /// The mark beside the name, usually a [LedgerMonogram].
  final Widget leading;

  /// The merchant or the payer, in the serif.
  final String name;

  /// A line under the name (the category and the account).
  final String subtitle;

  /// The sum; printed at the receipt's size.
  final LedgerFigure figure;

  /// The verdict; pressed at the receipt's size.
  final LedgerSeal seal;

  /// The lines under the tear, usually [LedgerKeyValue]s.
  final List<Widget> details;

  /// The narrowest a receipt is set in its desktop form: in a narrower
  /// slot (a column beside a form) it takes the phone's.
  static const double _deskFrom = 520;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) =>
        LedgerLayout.isWide(context) && box.maxWidth < _deskFrom
        ? LedgerNarrowScope(child: Builder(builder: _build))
        : _build(context),
  );

  Widget _build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final side = _side(wide);
    final size = wide
        ? LedgerSealSize.receipt.desk
        : LedgerSealSize.receipt.phone;
    final stamp = LedgerSeal(
      kicker: seal.kicker,
      value: seal.value,
      foot: seal.foot,
      tone: seal.tone,
      size: LedgerSealSize.receipt,
    );
    // `.receipt .seal`: margin 0 -4px -6px 0 (0 4px 0 0 from 1024). Its
    // ring ends on the slip's side room here, as the details' values do:
    // the source's 4 past it on a phone (4 short from 1024) read as nearly
    // aligned, not as stamped. It still sinks 6 into the stub's room.
    final pressed = wide
        ? SizedBox.square(dimension: size, child: stamp)
        : SizedBox(
            width: size,
            height: size - 6,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: size,
              maxWidth: size,
              minHeight: size,
              maxHeight: size,
              child: stamp,
            ),
          );
    final name0 = wide ? t.title.sized(40).line(42) : t.title.line(32);
    return LedgerSlip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LedgerSlipBand(),
          Padding(
            padding: EdgeInsets.fromLTRB(side, 0, side, wide ? 8 : 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LedgerSlipHead(kind, number),
                Row(
                  spacing: 14,
                  children: [
                    leading,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(name, style: name0),
                          ),
                          const SizedBox(height: 3),
                          Text(subtitle, style: t.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: wide ? 36 : 28,
                    bottom: wide ? 30 : 22,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 12,
                    children: [
                      // The figure stands whole (`white-space: nowrap`);
                      // when it and the seal overrun the row, as a
                      // paycheck's +$3,412.50 does on a phone, the seal
                      // gives way into the slip's side (`.seal { flex:
                      // none }` overflowing), its round pressed in full.
                      LedgerFigure(
                        figure.amount,
                        size: LedgerFigureSize.receipt,
                        tone: figure.tone,
                        showSign: figure.showSign,
                        showCents: figure.showCents,
                      ),
                      Flexible(child: pressed),
                    ],
                  ),
                ),
                _Bleed(side: side, child: const LedgerStub()),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: LedgerRows(children: details),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A child stood across the slip's sides (CSS's negative side margins).
class _Bleed extends StatelessWidget {
  const _Bleed({required this.side, required this.child});

  final double side;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => OverflowBox(
      alignment: Alignment.center,
      minWidth: box.maxWidth + 2 * side,
      maxWidth: box.maxWidth + 2 * side,
      // Its own height is the child's: in a column (unbounded) the box
      // would otherwise try to be infinitely tall.
      fit: OverflowBoxFit.deferToChild,
      child: child,
    ),
  );
}

/// A transfer drawn as a cheque (`.cheque`), printed on a [LedgerSlip]:
/// the guilloche band, its [kind] and [date], its [lines] (the pick lines,
/// the amount, the note), the tear line and the [micr] line at its foot
/// in the spaced mono. A sent cheque carries its [stamp], pressed across
/// it at the stamp's size (`.seal-stamp`: 132 down and 14 in from its end;
/// 136 and 40 from 1024, clear of the amount's box); at a large text size,
/// under its lines at their end.
///
/// ```dart
/// LedgerCheque(kind: 'Keel · Transfer', date: 'Wed, Oct 28, 2026', micr: '··0119 ··4821 ··9015', lines: [LedgerPickLine(label: 'From', icon: LucideIcons.wallet, name: 'Checking', mask: '··4821'), LedgerChequeAmount(label: 'Amount', words: 'Two hundred and 00/100', unit: 'dollars', amount: 200)])
/// ```
///
/// ```dart
/// LedgerCheque(kind: 'Keel · Transfer', date: 'Wed, Oct 28, 2026', micr: '··0119 ··4821 ··9015', lines: lines, stamp: const LedgerSeal(kicker: 'Keel · Transfer', value: 'Sent', foot: 'Oct 28'))
/// ```
class LedgerCheque extends StatelessWidget {
  /// A cheque dated [date] carrying its [lines].
  const LedgerCheque({
    required this.kind,
    required this.date,
    required this.lines,
    required this.micr,
    this.stamp,
    super.key,
  });

  /// What the slip is (Keel · Transfer).
  final String kind;

  /// The cheque's date, at its head's end.
  final String date;

  /// The cheque's lines: the pick lines, the amount, the note.
  final List<Widget> lines;

  /// The line at its foot, in the spaced mono.
  final String micr;

  /// The verdict pressed across a sent cheque; at the stamp's size.
  final LedgerSeal? stamp;

  @override
  Widget build(BuildContext context) {
    final wide = LedgerLayout.isWide(context);
    final seal = stamp;
    if (seal == null) return _slip(context, wide);
    final pressed = LedgerSeal(
      kicker: seal.kicker,
      value: seal.value,
      foot: seal.foot,
      tone: seal.tone,
      size: LedgerSealSize.stamp,
    );
    // At a large text size the lines' words reach across the slip, where
    // the stamp would cover them: it is pressed under the lines instead,
    // in a room of its own at their end.
    if (MediaQuery.textScalerOf(context).scale(1) > 1) {
      return _slip(context, wide, pressed: pressed);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _slip(context, wide),
        PositionedDirectional(
          // From 1024 the source's 150 put the seal's foot 8 into the
          // amount's box, cutting its frame; 136 stands it clear.
          top: wide ? 136 : 132,
          end: wide ? 40 : 14,
          // Pressed on the slip's own paper, as the empty page's seal is:
          // the rules under it break round it, ink never over ink.
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.ledgerTheme.surface,
              shape: BoxShape.circle,
            ),
            child: pressed,
          ),
        ),
      ],
    );
  }

  Widget _slip(BuildContext context, bool wide, {Widget? pressed}) {
    final t = context.ledgerTheme;
    final side = _side(wide);
    return LedgerSlip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LedgerSlipBand(),
          Padding(
            padding: EdgeInsets.fromLTRB(side, 0, side, wide ? 6 : 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LedgerSlipHead(kind, date),
                // On a cheque a field's rule is the faint ink (`.cheque
                // .field-box`).
                for (final line in lines) LedgerOnCheque(child: line),
                if (pressed != null)
                  Padding(
                    padding: const EdgeInsets.only(top: _pressedTop),
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: pressed,
                    ),
                  ),
                _Bleed(side: side, child: const LedgerStub()),
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    // The foot line is printing, left to right in either
                    // direction, as a card face's is.
                    child: Text(
                      micr,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: t.amount
                          .sized(12)
                          .line(16)
                          .tracked(.32)
                          .colored(t.textTertiary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // A stamp pressed under the lines stands 16 clear of the last.
  static const double _pressedTop = 16;
}
