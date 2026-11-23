/// Larder's Basket and Checkout: the lines with their steppers, the totals
/// in a display window, the question before a line leaves, and the
/// checkout's delivery, address and card.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'larder.dart';

/// The basket.
class LarderBasket extends StatefulWidget {
  /// The basket; [askRemove] asks about its first line at once.
  const LarderBasket({super.key, this.askRemove = false});

  /// Whether the remove question opens over it at first.
  final bool askRemove;

  @override
  State<LarderBasket> createState() => _LarderBasketState();
}

class _LarderBasketState extends State<LarderBasket> {
  @override
  void initState() {
    super.initState();
    if (widget.askRemove) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final frame = LarderFrame.of(context);
        if (mounted && frame.basket.isNotEmpty) _remove(frame.basket.first);
      });
    }
  }

  Future<void> _remove(LarderLine line) async {
    final frame = LarderFrame.of(context);
    final sure = await showApplianceDialog<bool>(
      context: context,
      builder: (context) => ApplianceDialog(
        title: 'Remove from the basket?',
        content: Text(
          '${line.product.name} goes back on the shelf. You can add it '
          'again from Shop.',
        ),
        actions: [
          ApplianceButton(
            'Keep it',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ApplianceButton.filled(
            'Remove',
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final at = frame.basket.indexOf(line);
    frame.changeBasket((lines) => lines.remove(line));
    if (!mounted) return;
    showApplianceToast(
      context,
      '${line.product.name} removed',
      actionLabel: 'Undo',
      onAction: () => frame.changeBasket(
        (lines) => lines.insert(at.clamp(0, lines.length), line),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = LarderFrame.of(context);
    return ListenableBuilder(
      listenable: frame.basketChanges,
      builder: (context, _) => _build(context, frame),
    );
  }

  Widget _build(BuildContext context, LarderFrameState frame) {
    final lines = frame.basket;
    final subtotal = lines.fold(0, (n, l) => n + l.pence);
    final delivery = larderDelivery(subtotal);
    if (lines.isEmpty) {
      return LarderPage(
        title: 'Basket',
        children: [
          ApplianceEmptyState(
            title: 'The basket is empty',
            message: 'Whatever you add from Shop waits here.',
            reading: '0',
            action: ApplianceButton.filled(
              'Go to Shop',
              icon: const Icon(LucideIcons.layoutGrid),
              onPressed: () => frame.go(LarderPlace.shop),
            ),
          ),
          if (frame.orders.isNotEmpty) ...[
            larderGroupGap,
            ApplianceListGroup(
              header: 'Bought before',
              children: [
                for (final o in frame.orders.where((o) => !o.current).take(2))
                  ApplianceListTile(
                    leading: const Icon(LucideIcons.rotateCcw),
                    title: 'Order ${o.number}',
                    subtitle: [for (final l in o.lines) l.product.name]
                        .join(', '),
                    trailingText: 'Buy again',
                    onTap: () {
                      for (final l in o.lines) {
                        frame.add(l.product, finish: l.finish, count: l.count);
                      }
                    },
                  ),
              ],
            ),
          ],
        ],
      );
    }
    final checkout = ApplianceButton.filled(
      'Checkout · ${larderPrice(subtotal + delivery)}',
      onPressed: () => frame.push(const LarderCheckoutPage()),
    );
    final cards = [
      for (final (i, line) in lines.indexed) ...[
        if (i > 0) const SizedBox(height: ApplianceSpacing.medium),
        _LineCard(
          line: line,
          onCount: (n) => frame.changeBasket(
            (all) => all[all.indexOf(line)] = LarderLine(
              line.product,
              n,
              finish: line.finish,
            ),
          ),
          onRemove: () => _remove(line),
        ),
      ],
    ];
    final totals = LarderTotals(
      subtotal: subtotal,
      netSubtotal: frame.basketNetPence,
      delivery: delivery,
    );
    // On a desk the lines and, beside them, the totals with the checkout key
    // under them: the key stays by the sum it pays.
    if (MediaQuery.sizeOf(context).width >= 1024) {
      return LarderPage(
        title: 'Basket',
        maxWidth: larderDeskWidth,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: cards,
                ),
              ),
              const SizedBox(width: ApplianceSpacing.large),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    totals,
                    const SizedBox(height: ApplianceSpacing.regular),
                    checkout,
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
    return LarderPage(
      title: 'Basket',
      bottom: LarderFootBar(
        label: 'Total',
        amount: larderPrice(subtotal + delivery),
        action: ApplianceButton.filled(
          'Checkout',
          onPressed: () => frame.push(const LarderCheckoutPage()),
        ),
      ),
      children: [
        ...cards,
        const SizedBox(height: ApplianceSpacing.large),
        totals,
      ],
    );
  }
}

/// A phone's foot strip: what the order comes to at its start, the key that
/// moves it on at its end.
class LarderFootBar extends StatelessWidget {
  /// [label] over [amount], beside [action].
  const LarderFootBar({
    super.key,
    required this.label,
    required this.amount,
    required this.action,
  });

  /// What the figure is ("Total").
  final String label;

  /// The figure.
  final String amount;

  /// The key.
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final t = context.applianceTheme.textTheme;
    return Row(
      children: [
        Expanded(
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: t.secondary),
                Text(amount, style: t.figure),
              ],
            ),
          ),
        ),
        const SizedBox(width: ApplianceSpacing.medium),
        action,
      ],
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.line,
    required this.onCount,
    required this.onRemove,
  });

  final LarderLine line;
  final ValueChanged<int> onCount;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = context.applianceTheme;
    final t = theme.textTheme;
    final p = line.product;
    return AppliancePanel(
      padding: const EdgeInsets.all(ApplianceSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 72, child: LarderPicture(product: p, height: 72)),
              const SizedBox(width: ApplianceSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: t.body.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${line.finish} · ${LarderPrefs.price(context, p.pence)} each',
                      style: t.secondary,
                    ),
                  ],
                ),
              ),
              ApplianceIconButton(
                icon: const Icon(LucideIcons.trash2),
                semanticLabel: 'Remove ${p.name}',
                onPressed: onRemove,
                style: const ApplianceStyle(
                  minimumSize: WidgetStatePropertyAll(Size.square(40)),
                ),
              ),
            ],
          ),
          const SizedBox(height: ApplianceSpacing.medium),
          Row(
            children: [
              ApplianceStepper(
                value: line.count,
                min: 1,
                max: 9,
                semanticLabel: 'How many ${p.name}',
                onChanged: onCount,
              ),
              const Spacer(),
              Text(
                larderPrice(
                  LarderPrefs.pricesWithTax(context)
                      ? line.pence
                      : line.netPence,
                ),
                style: t.figure,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The order's totals: the subtotal and delivery on a faceplate, the total
/// lit in a display window.
class LarderTotals extends StatelessWidget {
  /// Totals for [subtotal] and [delivery], in pence.
  const LarderTotals({
    super.key,
    required this.subtotal,
    required this.netSubtotal,
    required this.delivery,
  });

  /// The goods' total.
  final int subtotal;

  /// The goods' total using the displayed unit prices before tax.
  final int netSubtotal;

  /// Delivery's price.
  final int delivery;

  @override
  Widget build(BuildContext context) {
    final theme = context.applianceTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: t.body)),
          Text(value, style: t.figure.copyWith(fontWeight: FontWeight.w400)),
        ],
      ),
    );
    return AppliancePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(
            'Subtotal',
            larderPrice(
              LarderPrefs.pricesWithTax(context) ? subtotal : netSubtotal,
            ),
          ),
          if (!LarderPrefs.pricesWithTax(context))
            line('Tax', larderPrice(subtotal - netSubtotal)),
          line('Delivery', delivery == 0 ? 'Free' : larderPrice(delivery)),
          const SizedBox(height: ApplianceSpacing.medium),
          Semantics(
            label: 'Total',
            value: larderPrice(subtotal + delivery),
            excludeSemantics: true,
            child: ApplianceSurface(
              face: ApplianceFace.well(c, fill: c.display, radius: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ApplianceSpacing.regular,
                  vertical: ApplianceSpacing.medium,
                ),
                child: Row(
                  children: [
                    Text('TOTAL', style: t.legend.copyWith(color: c.onDisplay)),
                    const Spacer(),
                    Text(
                      larderPrice(subtotal + delivery),
                      style: t.figure.copyWith(
                        fontSize: 22,
                        height: 28 / 22,
                        color: c.onDisplay,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The checkout: how it comes, where to, and the card.
class LarderCheckoutPage extends StatefulWidget {
  /// The checkout.
  const LarderCheckoutPage({super.key});

  @override
  State<LarderCheckoutPage> createState() => _LarderCheckoutPageState();
}

class _LarderCheckoutPageState extends State<LarderCheckoutPage> {
  String _delivery = 'standard';
  bool _gift = false;
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _postcode = TextEditingController();
  LarderDetails? _initial;
  bool _submitted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final account = LarderPrefs.of(context).account;
    if (account != null && _initial == null) {
      _initial = account;
      _name.text = account.name;
      _address.text = account.address;
      _postcode.text = account.postcode;
    }
  }

  final _card = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _postcode.dispose();
    _card.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = LarderFrame.of(context);
    final prefs = LarderPrefs.of(context);
    final account = prefs.account;
    if (account == null) {
      return LarderPage(
        title: 'Checkout',
        children: [
          ApplianceEmptyState(
            title: 'Sign in to check out',
            message: 'Use the demo account to place an order.',
            action: ApplianceButton(
              'Sign in to demo account',
              onPressed: prefs.signIn,
            ),
          ),
        ],
      );
    }
    final subtotal = frame.basket.fold(0, (n, l) => n + l.pence);
    final delivery = _delivery == 'next' ? 650 : larderDelivery(subtotal);
    const gap = SizedBox(height: ApplianceSpacing.large);
    final method = _delivery == 'next' ? 'Next day' : 'Standard';
    final digits = _card.text.trim();
    final invalidCard =
        digits.isNotEmpty && (digits.length < 12 || digits.length > 19);
    void placeOrder() {
      if (_name.text.trim().isEmpty ||
          _address.text.trim().isEmpty ||
          _postcode.text.trim().isEmpty ||
          invalidCard) {
        setState(() => _submitted = true);
        return;
      }
      final details = LarderDetails(
        name: _name.text.trim(),
        address: _address.text.trim(),
        postcode: _postcode.text.trim().toUpperCase(),
        cardLast4: digits.isEmpty
            ? account.cardLast4
            : digits.substring(digits.length - 4),
      );
      if (frame.tryPayment()) {
        frame.placeOrder(
          delivery: delivery,
          method: method,
          details: details,
          gift: _gift,
        );
      } else {
        frame.push(
          LarderPaymentFailedPage(
            delivery: delivery,
            method: method,
            details: details,
            gift: _gift,
          ),
        );
      }
    }

    final pay = ApplianceButton.filled(
      'Pay ${larderPrice(subtotal + delivery)}',
      icon: const Icon(LucideIcons.creditCard),
      onPressed: placeOrder,
    );
    final form = <Widget>[
      RadioGroup<String>(
        groupValue: _delivery,
        onChanged: (v) => setState(() => _delivery = v!),
        child: ApplianceListGroup(
          header: 'Delivery',
          children: [
            for (final (value, title, note) in const [
              ('standard', 'Standard', '3 to 5 days, free over £40'),
              ('next', 'Next day', 'Order by 8 pm, £6.50'),
            ])
              ApplianceListTile(
                title: title,
                subtitle: note,
                trailing: ApplianceRadio<String>(
                  value: value,
                  semanticLabel: '$title, $note',
                ),
              ),
          ],
        ),
      ),
      gap,
      const ApplianceSectionHeader('Address'),
      AppliancePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ApplianceTextField(
              labelText: 'Full name',
              controller: _name,
              errorText: _submitted && _name.text.trim().isEmpty
                  ? 'Enter the recipient’s name.'
                  : null,
              onChanged: (_) {
                if (_submitted) setState(() {});
              },
              autofillHints: const [AutofillHints.name],
            ),
            gap,
            ApplianceTextField(
              labelText: 'Address',
              controller: _address,
              errorText: _submitted && _address.text.trim().isEmpty
                  ? 'Enter a street address.'
                  : null,
              onChanged: (_) {
                if (_submitted) setState(() {});
              },
              autofillHints: const [AutofillHints.streetAddressLine1],
            ),
            gap,
            ApplianceTextField(
              labelText: 'Postcode',
              controller: _postcode,
              errorText: _submitted && _postcode.text.trim().isEmpty
                  ? 'Enter a postcode.'
                  : null,
              onChanged: (_) {
                if (_submitted) setState(() {});
              },
              autofillHints: const [AutofillHints.postalCode],
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
      ),
      gap,
      const ApplianceSectionHeader('Card'),
      AppliancePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ApplianceTextField(
              labelText: 'Card number',
              hintText: 'Use saved card ending ${account.cardLast4}',
              errorText: _submitted && invalidCard
                  ? 'Enter 12 to 19 digits.'
                  : null,
              onChanged: (_) => setState(() {}),
              controller: _card,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              leading: const Icon(LucideIcons.creditCard),
            ),
            const SizedBox(height: ApplianceSpacing.regular),
            Row(
              children: [
                ApplianceCheckbox(
                  value: _gift,
                  semanticLabel: 'Wrap it as a gift',
                  onChanged: (v) => setState(() => _gift = v ?? false),
                ),
                const SizedBox(width: ApplianceSpacing.medium),
                Expanded(
                  child: Text(
                    'Wrap it as a gift',
                    style: context.applianceTheme.textTheme.body,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
    final totals = LarderTotals(
      subtotal: subtotal,
      netSubtotal: frame.basketNetPence,
      delivery: delivery,
    );
    // On a desk the form and, beside it, the sum with the key that pays it.
    if (MediaQuery.sizeOf(context).width >= 1024) {
      return LarderPage(
        title: 'Checkout',
        maxWidth: larderDeskWidth,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: form,
                ),
              ),
              const SizedBox(width: ApplianceSpacing.large),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ApplianceSectionHeader('Order'),
                    totals,
                    const SizedBox(height: ApplianceSpacing.regular),
                    pay,
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
    return LarderPage(
      title: 'Checkout',
      bottom: LarderFootBar(
        label: 'To pay',
        amount: larderPrice(subtotal + delivery),
        action: ApplianceButton.filled(
          'Pay',
          icon: const Icon(LucideIcons.creditCard),
          onPressed: placeOrder,
        ),
      ),
      children: [...form, gap, totals],
    );
  }
}

/// The page a declined payment opens: what happened, that nothing was
/// taken, and the two ways on: try again, or go back for another card.
class LarderPaymentFailedPage extends StatelessWidget {
  /// The failed payment of the basket with [delivery] by [method].
  const LarderPaymentFailedPage({
    super.key,
    required this.delivery,
    this.method = 'Standard',
    this.details = larderShopper,
    this.gift = false,
  });

  /// What delivery adds, in pence.
  final int delivery;

  /// How the order would come.
  final String method;

  final LarderDetails details;
  final bool gift;

  @override
  Widget build(BuildContext context) {
    final frame = LarderFrame.of(context);
    final subtotal = frame.basket.fold(0, (n, l) => n + l.pence);
    final amount = larderPrice(subtotal + delivery);
    return LarderPage(
      title: 'Payment',
      children: [
        ApplianceStatusView(
          status: ApplianceStatus.error,
          title: 'The payment did not go through',
          message:
              'Your bank declined $amount on the card ending ${details.cardLast4}. Nothing '
              'was taken, and the basket is as you left it.',
          actions: [
            ApplianceButton.filled(
              'Try again',
              icon: const Icon(LucideIcons.rotateCw),
              onPressed: () {
                if (frame.tryPayment()) {
                  frame.placeOrder(
                    delivery: delivery,
                    method: method,
                    details: details,
                    gift: gift,
                  );
                }
              },
            ),
            ApplianceButton(
              'Use another card',
              icon: const Icon(LucideIcons.creditCard),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
        larderGroupGap,
        const ApplianceBanner(
          title: 'Why a payment fails',
          message:
              'A card past its date, a spending limit, or the bank asking '
              'to confirm. Your bank\'s app says which.',
        ),
      ],
    );
  }
}
