/// The example's ordinary screens drawn as a comic's pages: panels in tiers with a caption each, the reader's words in
/// a balloon, one burst where attention already is. A comics reader and shop: Library, Shop, Account and Settings.
library;

import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';

import 'kit.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../demo_art.dart';

/// From this width up a control keeps its own width or a cell of the form's grid (design6 P, width on a wide layout).
const double _controlCap = 320;

/// A select, stepper or lone control: across the column on a phone, at most [_controlCap] from 600 up.
Widget _capped(BuildContext context, Widget child) {
  final wide = ComicTheme.of(context).width >= 600;
  if (!wide) return SizedBox(width: double.infinity, child: child);
  return Align(
    alignment: AlignmentDirectional.centerStart,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: wide ? _controlCap : double.infinity,
      ),
      child: child,
    ),
  );
}

/// The screen's one act: across the content on a phone, its own width from 600 up.
Widget _act(BuildContext context, String label, String done) {
  final phone = ComicTheme.of(context).width < 600;
  return Align(
    alignment: AlignmentDirectional.centerStart,
    child: ComicButton.filled(
      label,
      wide: phone,
      onPressed: () => kitFeedback(context, done),
    ),
  );
}

/// Two fields side by side from 600 up, stacked on a phone unless they are short ([phone]); short ones stack too
/// under large text, where a label wraps and would stand one field's frame below the other's.
Widget _pair(BuildContext context, Widget a, Widget b, {bool phone = false}) {
  final large = MediaQuery.textScalerOf(context).scale(10) > 15;
  if ((!phone || large) && ComicTheme.of(context).width < 600) {
    return ComicColumn(gap: 20, children: [a, b]);
  }
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: a),
      const SizedBox(width: 16),
      Expanded(child: b),
    ],
  );
}

/// A lone control in a form of pairs: from 600 up it takes the first cell of the grid the pairs set, so its edges
/// meet theirs (a [_controlCap] box ends between the grid's columns); across the column on a phone, and where a cell
/// is too narrow for a choice's words (a tablet's panel beside another), so a select never cuts its value short.
Widget _firstCell(BuildContext context, Widget child) {
  if (ComicTheme.of(context).width < 600) {
    return SizedBox(width: double.infinity, child: child);
  }
  // The longest choice's words ('Standard delivery', about 150) with the field's padding and its chevron: about 205.
  final least = MediaQuery.textScalerOf(context).scale(224);
  return LayoutBuilder(
    builder: (context, box) {
      if ((box.maxWidth - 16) / 2 < least) {
        return SizedBox(width: double.infinity, child: child);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child),
          const SizedBox(width: 16),
          const Spacer(),
        ],
      );
    },
  );
}

/// A panel beside a taller one keeps its own height (design6 P, a card in a row hugs its content): a tier shares
/// its height with the column, and the panel stands at the column's top with the page's ground below it.
Widget _hug(Widget panel) => ComicPanelStack(grow: false, children: [panel]);

/// Account: where the shop sends things, as one captioned panel, and what it has on file beside it.
Widget gateAccount() => kitState(
  'standard',
  (context, delivery, deliver) => kitState(true, (context, updates, update) {
    String say(String en) => kitSay(context, en);
    final form = ComicPanel(
      caption: say('Where do we send it?'),
      child: ComicColumn(
        gap: 20,
        children: [
          _pair(
            context,
            ComicTextField(
              label: say('Full name'),
              initialValue: say('Alex Morgan'),
            ),
            ComicTextField(
              label: say('Email address'),
              initialValue: 'alex@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          ComicTextField(
            label: say('Street and number'),
            initialValue: say('12 Harbour Lane'),
          ),
          _pair(
            context,
            ComicTextField(label: say('Town'), initialValue: say('Brighton')),
            ComicTextField(label: say('Postcode'), initialValue: 'BN1 4AA'),
          ),
          _firstCell(
            context,
            ComicSelect<String>(
              label: say('Delivery'),
              value: delivery,
              options: [
                ComicSelectOption('standard', say('Standard delivery')),
                ComicSelectOption('express', say('Express delivery')),
                ComicSelectOption('collect', say('Collect in store')),
              ],
              onChanged: deliver,
            ),
          ),
          ComicCheckRow(
            label: say('Email me delivery updates'),
            value: updates,
            onChanged: update,
          ),
          _act(context, say('Save details'), say('Delivery details saved.')),
        ],
      ),
    );
    final help = ComicPanel(
      caption: say('On file'),
      child: ComicColumn(
        gap: 20,
        children: [
          ComicKvRow(say('Member since'), say('March 2024'), isFirst: true),
          ComicKvRow(say('Orders'), '7'),
          ComicKvRow(say('Plan'), say('Monthly, 4 issues')),
          // The screen tells this; no one says it: a narrator's caption, not a balloon.
          ComicCaption(
            say(
              'We only use your address for this order and the ones after it.',
            ),
            free: true,
          ),
        ],
      ),
    );
    return ComicTier(
      spans: const [7, 5],
      phone: ComicTierLayout.stack,
      children: [form, _hug(help)],
    );
  }),
);

/// Settings: two panels of switches, and the app's one remark in a narrator's caption.
Widget gateSettings() => Builder(
  builder: (context) {
    String say(String en) => kitSay(context, en);
    Widget rows(List<(String, String, bool)> items) => ComicColumn(
      gap: 0,
      children: [
        for (final (i, (label, note, initial)) in items.indexed)
          kitState(
            initial,
            (context, value, change) => ComicSwitchRow(
              label: say(label),
              note: say(note),
              value: value,
              isFirst: i == 0,
              onChanged: change,
            ),
          ),
      ],
    );
    return ComicColumn(
      gap: 20,
      children: [
        ComicTier(
          spans: const [6, 6],
          phone: ComicTierLayout.stack,
          children: [
            ComicPanel(
              caption: say('Tell me when'),
              child: rows(const [
                ('A new issue is out', 'On the morning it comes out', true),
                ('My order ships', 'With its tracking number', true),
                ('Weekly summary', 'What you read, every Monday', false),
              ]),
            ),
            ComicPanel(
              caption: say('Reading'),
              child: rows(const [
                ('Download new issues', 'On Wi-Fi only', true),
                ('Panel by panel', 'One panel at a time on a phone', false),
                ('Night pages', 'Dark paper after sunset', true),
              ]),
            ),
          ],
        ),
        // The screen tells this; no one says it: a narrator's caption, not a balloon. On a desktop it takes the first
        // panel's column, so its edges stand on the tier's; on a phone, the column.
        if (ComicTheme.of(context).desk)
          ComicTier(
            spans: const [6, 6],
            children: [
              ComicCaption(say(_settingsRemark), free: true),
              const SizedBox.shrink(),
            ],
          )
        else
          ComicCaption(say(_settingsRemark), free: true),
      ],
    );
  },
);

const _settingsRemark =
    'You can change these any time. Messages about your account and orders always come through.';

/// Library: the reader's issues as a tier of covers, each with its state as a tag; how many wait to be read is the burst.
Widget gateLibrary() => kitState(0, (context, tab, change) {
  final t = ComicTheme.of(context);
  String say(String en) => kitSay(context, en);
  const issues = [
    ('The first issue', 1, 'Ready to read', ComicMarks.peak),
    ('A small adventure', 2, 'Ready to read', ComicMarks.tent),
    ('Making time', 3, 'Saved', ComicMarks.moon),
    ('The everyday issue', 4, 'Finished', ComicMarks.mug),
  ];
  final ready = issues.where((i) => i.$3 == 'Ready to read').length;
  final shown = [
    for (final issue in issues)
      if (tab == 0 ||
          (tab == 1 && issue.$3 == 'Saved') ||
          (tab == 2 && issue.$3 == 'Finished'))
        issue,
  ];
  final perRow = t.desk ? 4 : 2;
  final covers = <Widget>[
    for (final (title, number, state, mark) in shown)
      ComicPictureCard(
        slotId: 'library-$number',
        // Ground 4 is the navy issue by day too: its mark is inked for a dark ground, so the cup's steam reads (r4).
        image: ComicArtBand(
          ground: number,
          leading: ComicMark(mark, onNight: number == 4),
        ),
        title: say(title),
        subtitle: '${say('Issue')} $number',
        // Each state its own ink: the warm lamp waits to be read, the second print colour is kept, paper is done.
        trailing: ComicTag(
          say(state),
          tone: switch (state) {
            'Ready to read' => ComicSpeaker.narrator,
            'Saved' => ComicSpeaker.group,
            _ => null,
          },
        ),
        onPressed: () => kitFeedback(context, '${say(title)} opened.'),
      ),
  ];
  while (covers.length % perRow != 0) {
    covers.add(const SizedBox.shrink());
  }
  return ComicColumn(
    gap: 20,
    children: [
      Row(
        children: [
          // The band's head, lettered, with its line under it: a lone line of body floated halfway down the burst's
          // height (r3).
          Expanded(
            child: ComicColumn(
              gap: 4,
              children: [
                Text(say('YOUR SHELF'), style: t.type.panel),
                Text(say('Your issues, on every device.'), style: t.type.body),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ComicBurst(
            number: '$ready',
            over: say('Ready'),
            under: say('to read!'),
          ),
        ],
      ),
      _capped(
        context,
        ComicTabBar(
          tabs: [say('All'), say('Saved'), say('Finished')],
          selectedIndex: tab,
          onChanged: change,
        ),
      ),
      ComicTier(phone: ComicTierLayout.pairs, children: covers),
    ],
  );
});

/// Shop: the order beside delivery and payment; the total set large under its caption.
Widget gateShop() => kitState(
  'Card',
  (context, pay, choose) => kitState('Standard', (context, delivery, deliver) {
    String say(String en) => kitSay(context, en);
    ComicChoice choice(String label, String note) =>
        ComicChoice(say(label), value: label, note: say(note));
    final shipping = switch (delivery) {
      'Express' => 6,
      'Collect' => 0,
      _ => 3,
    };
    final total = 18 + shipping;
    final order = ComicPanel(
      caption: say('Your order'),
      child: ComicColumn(
        gap: 0,
        children: [
          ComicLedgerRow(
            title: say('The first issue'),
            subtitle: say('Print, one copy'),
            value: '€12',
            isFirst: true,
          ),
          ComicLedgerRow(
            title: say('Bookmarks'),
            subtitle: say('A set of three'),
            value: '€6',
          ),
          ComicLedgerRow(
            title: say('Delivery'),
            subtitle: say(delivery),
            value: shipping == 0 ? say('Free') : '€$shipping',
          ),
          ComicTotalRow(say('To pay'), '€$total', note: say('VAT included')),
        ],
      ),
    );
    final payment = ComicPanel(
      caption: say('Delivery and payment'),
      child: ComicColumn(
        gap: 20,
        children: [
          ComicFormField(
            say('Delivery'),
            child: ComicChoices(
              options: [
                choice('Standard', '3 to 5 days, €3'),
                choice('Express', 'Next day, €6'),
                choice('Collect', 'In store, free'),
              ],
              value: delivery,
              onChanged: deliver,
            ),
          ),
          ComicFormField(
            say('Pay with'),
            child: ComicChoices(
              options: [
                choice('Card', 'Visa, Mastercard'),
                choice('Phone wallet', 'On this device'),
                choice('Invoice', 'Within 14 days'),
              ],
              value: pay,
              onChanged: choose,
            ),
          ),
          if (pay == 'Card') ...[
            ComicTextField(
              label: say('Name on the card'),
              initialValue: say('Alex Morgan'),
            ),
            ComicTextField(
              label: say('Card number'),
              initialValue: '4242 4242 4242 4242',
              keyboardType: TextInputType.number,
              // A card's numbers read left to right in a right-to-left app too.
              textDirection: TextDirection.ltr,
            ),
            _pair(
              context,
              ComicTextField(
                label: say('Expiry'),
                initialValue: '08 / 28',
                textDirection: TextDirection.ltr,
              ),
              ComicTextField(
                label: say('Security code'),
                initialValue: '123',
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
              ),
              phone: true,
            ),
          ],
          _act(
            context,
            '${say('Pay')} €$total',
            say('Order placed. Thank you!'),
          ),
        ],
      ),
    );
    return ComicTier(
      spans: const [5, 7],
      phone: ComicTierLayout.stack,
      children: [_hug(order), payment],
    );
  }),
);
