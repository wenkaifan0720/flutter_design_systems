import 'package:flutter/widgets.dart';

import '../../theme.dart';
import '../marks/marks.dart';
import '../receipt/receipt.dart';
import '../seal/seal.dart';
import '../structure/structure.dart';

/// The account holder's certificate (`.member`), printed on a
/// [LedgerSlip]: the guilloche band, its [kind] and [since] in the mono,
/// then the holder's [initials] inked on a disc beside the [seal] (from
/// 1024 the [name] between them), the [name] in the serif 40 over its
/// [subtitle], an ink rule, and the [details] (key and value lines). The
/// profile's head.
///
/// ```dart
/// LedgerMemberCard(kind: 'Keel · Account holder', since: 'Since Mar 2023', name: 'Maren Holt', initials: 'MH', subtitle: 'Member since March 2023', seal: const LedgerSeal(kicker: 'Keel', value: 'Member', foot: 'Since 2023'), details: const [LedgerKeyValue('Email', 'maren.holt@example.com')])
/// ```
class LedgerMemberCard extends StatelessWidget {
  /// The certificate of [name], holding [details].
  const LedgerMemberCard({
    required this.kind,
    required this.since,
    required this.name,
    required this.initials,
    required this.subtitle,
    required this.seal,
    required this.details,
    super.key,
  });

  /// The slip's kind, at its head's start ("Keel · Account holder").
  final String kind;

  /// The head's end ("Since Mar 2023").
  final String since;

  /// The holder's name, in the serif.
  final String name;

  /// The holder's initials, on the inked disc.
  final String initials;

  /// The line under the name ("Member since March 2023").
  final String subtitle;

  /// The membership's seal; pressed at the member card's size.
  final LedgerSeal seal;

  /// The lines under the rule, usually [LedgerKeyValue]s.
  final List<Widget> details;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final side = wide ? _deskSide : _side;
    final disc = LedgerMonogram(
      name,
      initials: initials,
      tone: LedgerMonogramTone.inked,
      size: LedgerMonogramSize.member,
    );
    final stamp = LedgerSeal(
      kicker: seal.kicker,
      value: seal.value,
      foot: seal.foot,
      tone: seal.tone,
      size: LedgerSealSize.member,
    );
    final id = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            name,
            style: t.title
                .sized(wide ? _deskName : _name)
                .line(wide ? _deskNameLine : _nameLine)
                .tracked(_nameTracking),
          ),
        ),
        const SizedBox(height: _subTop),
        Text(subtitle, style: t.bodySmall.colored(t.textTertiary)),
      ],
    );
    // `.member-top`: "mg . seal" over "id id id", 14 16 apart, 6 0 20; from
    // 1024 "mg id seal", 0 22 apart, 10 0 24.
    final top = wide
        ? Row(
            spacing: _deskGap,
            children: [
              disc,
              Expanded(child: id),
              stamp,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: _rowGap,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: _colGap,
                children: [disc, stamp],
              ),
              id,
            ],
          );
    return LedgerSlip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LedgerSlipBand(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              side,
              0,
              side,
              wide ? _deskFoot : _foot,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LedgerSlipHead(kind, since),
                Container(
                  padding: EdgeInsets.only(
                    top: wide ? _deskTopPad : _topPad,
                    bottom: wide ? _deskBottomPad : _bottomPad,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.headRule)),
                  ),
                  child: top,
                ),
                // `.member .kvs { padding-top: 2px }`.
                Padding(
                  padding: const EdgeInsets.only(top: _kvsTop),
                  child: LedgerRows(children: details),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // `.member`: 0 20 6 (0 32 8 from 1024); `.member-name` 400 40/42 serif,
  // −.01em (44/46); `.member-since` 4 under it.
  static const double _side = 20;
  static const double _deskSide = 32;
  static const double _foot = 6;
  static const double _deskFoot = 8;
  static const double _topPad = 6;
  static const double _bottomPad = 20;
  static const double _deskTopPad = 10;
  static const double _deskBottomPad = 24;
  static const double _rowGap = 14;
  static const double _colGap = 16;
  static const double _deskGap = 22;
  static const double _name = 40;
  static const double _nameLine = 42;
  static const double _deskName = 44;
  static const double _deskNameLine = 46;
  static const double _nameTracking = -.01;
  static const double _subTop = 4;
  static const double _kvsTop = 2;
}
