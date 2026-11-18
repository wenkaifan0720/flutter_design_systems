/// Admit's Settings: the account, the notifications and the appearance,
/// which set the whole app as they change.
library;

import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'admit.dart';
import 'data.dart';

/// Settings.
class AdmitSettings extends StatelessWidget {
  /// Settings.
  const AdmitSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = AdmitPrefs.of(context);
    final t = context.brutalTheme.textTheme;
    final c = context.brutalTheme.colors;
    return AdmitPage(
      title: 'Settings',
      children: [
        BrutalBlock(
          lead: true,
          color: c.violet,
          padding: const EdgeInsets.all(BrutalSpacing.large),
          label: 'Account',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SIGNED IN AS', style: t.caption.copyWith(color: c.onBlock)),
              const SizedBox(height: BrutalSpacing.small),
              Text(
                admitOwner.name,
                style: t.headline.copyWith(color: c.onBlock),
              ),
              Text(admitOwner.email, style: t.body.copyWith(color: c.onBlock)),
            ],
          ),
        ),
        admitGroupGap,
        BrutalListGroup(
          header: 'Account',
          children: [
            BrutalListTile(
              leading: const Icon(LucideIcons.user),
              title: 'Name and email',
              onTap: () =>
                  AdmitFrame.of(context).push(const AdmitAccountPage()),
            ),
            BrutalListTile(
              leading: const Icon(LucideIcons.creditCard),
              title: 'Payment',
              subtitle: 'Card ending ${admitOwner.card}',
              onTap: () =>
                  AdmitFrame.of(context).push(const AdmitPaymentPage()),
            ),
          ],
        ),
        admitGroupGap,
        BrutalListGroup(
          header: 'Notifications',
          footer: 'Reminders arrive at 10:00 the day before.',
          children: [
            BrutalListTile(
              leading: const Icon(LucideIcons.bell),
              title: 'Reminders',
              subtitle: 'A day before each event',
              trailing: BrutalSwitch(
                value: prefs.reminders,
                onChanged: (v) => prefs.update((p) => p.reminders = v),
                semanticLabel: 'Reminders',
              ),
            ),
            BrutalListTile(
              leading: const Icon(LucideIcons.mail),
              title: 'Weekly listings',
              subtitle: 'By email, on Mondays',
              trailing: BrutalSwitch(
                value: prefs.listings,
                onChanged: (v) => prefs.update((p) => p.listings = v),
                semanticLabel: 'Weekly listings',
              ),
            ),
            BrutalListTile(
              leading: const Icon(LucideIcons.volume2),
              title: 'Sounds',
              trailing: BrutalSwitch(
                value: prefs.sounds,
                onChanged: (v) => prefs.update((p) => p.sounds = v),
                semanticLabel: 'Sounds',
              ),
            ),
          ],
        ),
        admitGroupGap,
        const BrutalSectionHeader('Appearance'),
        Text('Theme', style: t.label.copyWith(fontSize: 14)),
        const SizedBox(height: BrutalSpacing.small),
        BrutalSegmentedButton<AdmitAppearance>(
          segments: const [
            BrutalSegment(value: AdmitAppearance.light, label: 'Light'),
            BrutalSegment(value: AdmitAppearance.dark, label: 'Dark'),
            BrutalSegment(value: AdmitAppearance.system, label: 'System'),
          ],
          value: prefs.appearance,
          onChanged: (v) => prefs.update((p) => p.appearance = v),
          semanticLabel: 'Theme',
        ),
        const SizedBox(height: BrutalSpacing.large),
        BrutalSelect<String>(
          label: 'Density',
          items: const [
            BrutalSelectItem(value: 'standard', label: 'Standard'),
            BrutalSelectItem(value: 'comfortable', label: 'Comfortable'),
            BrutalSelectItem(value: 'compact', label: 'Compact'),
          ],
          value: _densityName(prefs.density),
          onChanged: (v) => prefs.update(
            (p) => p.density = switch (v) {
              'comfortable' => BrutalDensity.comfortable,
              'compact' => BrutalDensity.compact,
              _ => BrutalDensity.standard,
            },
          ),
        ),
        const SizedBox(height: BrutalSpacing.large),
        Text('Reading direction', style: t.label.copyWith(fontSize: 14)),
        const SizedBox(height: BrutalSpacing.small),
        BrutalSegmentedButton<TextDirection>(
          segments: const [
            BrutalSegment(value: TextDirection.ltr, label: 'Left to right'),
            BrutalSegment(value: TextDirection.rtl, label: 'Right to left'),
          ],
          value: prefs.direction,
          onChanged: (v) => prefs.update((p) => p.direction = v),
          semanticLabel: 'Reading direction',
        ),
        admitGroupGap,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: BrutalButton.text(
            'Sign out',
            onPressed: () => _signOut(context),
            isDestructiveAction: true,
          ),
        ),
      ],
    );
  }

  static Future<void> _signOut(BuildContext context) async {
    final sure = await showBrutalDialog<bool>(
      context: context,
      builder: (context) => BrutalDialog(
        title: 'Sign out?',
        content: Text(
          'Your tickets stay with ${admitOwner.email}; sign in again to '
          'see them on this device.',
        ),
        actions: [
          BrutalDialogAction(
            label: 'Stay signed in',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          BrutalDialogAction(
            label: 'Sign out',
            primary: true,
            destructive: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    showBrutalToast(context, 'Signed out on this device.');
  }

  static String _densityName(BrutalDensity d) => d == BrutalDensity.comfortable
      ? 'comfortable'
      : d == BrutalDensity.compact
      ? 'compact'
      : 'standard';
}

/// The account's name and email, saved together.
class AdmitAccountPage extends StatefulWidget {
  /// The account page.
  const AdmitAccountPage({super.key});

  @override
  State<AdmitAccountPage> createState() => _AdmitAccountPageState();
}

class _AdmitAccountPageState extends State<AdmitAccountPage> {
  final _name = TextEditingController(text: admitOwner.name);
  final _email = TextEditingController(text: admitOwner.email);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    final frame = AdmitFrame.of(context);
    Navigator.of(context).maybePop();
    showBrutalToast(frame.context, 'Name and email saved.');
  }

  @override
  Widget build(BuildContext context) {
    return AdmitPage(
      title: 'Name and email',
      bottom: _SaveButton(label: 'Save', onPressed: _save),
      children: [
        BrutalTextField(
          controller: _name,
          label: 'Name',
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
        ),
        const SizedBox(height: BrutalSpacing.large),
        BrutalTextField(
          controller: _email,
          label: 'Email',
          helper: 'Tickets and receipts go here.',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
      ],
    );
  }
}

/// The card on file, and a new one to put in its place.
class AdmitPaymentPage extends StatefulWidget {
  /// The payment page.
  const AdmitPaymentPage({super.key});

  @override
  State<AdmitPaymentPage> createState() => _AdmitPaymentPageState();
}

class _AdmitPaymentPageState extends State<AdmitPaymentPage> {
  final _card = TextEditingController();
  final _expiry = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _card.dispose();
    _expiry.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _complete =>
      _card.text.replaceAll(' ', '').length >= 12 &&
      _expiry.text.length >= 4 &&
      _code.text.length >= 3;

  void _save() {
    final frame = AdmitFrame.of(context);
    Navigator.of(context).maybePop();
    showBrutalToast(frame.context, 'New card saved.');
  }

  @override
  Widget build(BuildContext context) {
    void changed(String _) => setState(() {});
    final expiry = BrutalTextField(
      controller: _expiry,
      label: 'Expiry',
      hint: 'MM/YY',
      keyboardType: TextInputType.datetime,
      textDirection: TextDirection.ltr,
      onChanged: changed,
    );
    final code = BrutalTextField(
      controller: _code,
      label: 'Security code',
      hint: '3 digits',
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      obscureText: true,
      onChanged: changed,
    );
    return AdmitPage(
      title: 'Payment',
      bottom: _SaveButton(
        label: 'Save card',
        onPressed: _complete ? _save : null,
      ),
      children: [
        BrutalListGroup(
          header: 'On file',
          children: [
            BrutalListTile(
              leading: const Icon(LucideIcons.creditCard),
              title: 'Card ending ${admitOwner.card}',
              subtitle: 'Expires 08/28',
            ),
          ],
        ),
        admitGroupGap,
        const BrutalSectionHeader('Replace it'),
        BrutalTextField(
          controller: _card,
          label: 'Card number',
          hint: '16 digits',
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          autofillHints: const [AutofillHints.creditCardNumber],
          onChanged: changed,
        ),
        const SizedBox(height: BrutalSpacing.large),
        // As checkout's: side by side up to 1.5 times the text, then stacked.
        if (MediaQuery.textScalerOf(context).scale(1) > 1.5) ...[
          expiry,
          const SizedBox(height: BrutalSpacing.large),
          code,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: expiry),
              const SizedBox(width: BrutalSpacing.regular),
              Expanded(child: code),
            ],
          ),
      ],
    );
  }
}

/// A page's one main action, the column's width on a phone.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.sizeOf(context).width < 600 ? double.infinity : null,
    child: BrutalButton.filled(label, onPressed: onPressed),
  );
}
