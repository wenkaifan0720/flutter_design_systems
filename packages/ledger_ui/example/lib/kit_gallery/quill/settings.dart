/// Settings: the owner's profile, the alerts, the reading direction, the
/// preferences and the appearance, each a ruled section; Sign out at the
/// foot. The direction, the appearance and the density re-set the whole
/// app.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
import 'quill.dart';

class QuillSettings extends StatefulWidget {
  const QuillSettings({super.key});

  @override
  State<QuillSettings> createState() => _QuillSettingsState();
}

class _QuillSettingsState extends State<QuillSettings> {
  String _name = kitMaren.name;
  String _email = 'maren.holt@example.com';
  String _phone = '(415) 555-0119';

  Future<void> _edit(
    String label,
    String value,
    ValueChanged<String> done,
  ) async {
    final words = TextEditingController(text: value);
    final ok = await LedgerDialog.show(
      context,
      title: 'Change ${label.toLowerCase()}',
      confirmLabel: 'Save',
      children: [LedgerTextField(label: label, controller: words)],
    );
    if (ok == true && words.text.trim().isNotEmpty) done(words.text.trim());
    words.dispose();
  }

  Future<void> _signOut() async {
    final ok = await LedgerDialog.show(
      context,
      title: 'Sign out of Quill?',
      body: 'Your entries stay on this device until you sign in again.',
      type: LedgerDialogType.destructive,
      confirmLabel: 'Sign out',
    );
    if (ok == true && mounted) LedgerToast.show(context, 'Signed out');
  }

  @override
  Widget build(BuildContext context) {
    final prefs = QuillPrefs.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final wide = LedgerLayout.isWide(context);
    final paired = width >= LedgerNavigationFrame.railFrom;

    final profile = LedgerSection(
      head: const LedgerHead('Profile', note: 'Since Mar 2023'),
      child: LedgerRows(
        children: [
          LedgerSettingRow(
            title: 'Name',
            value: _name,
            onTap: () => _edit('Name', _name, (v) => setState(() => _name = v)),
          ),
          LedgerSettingRow(
            title: 'Email',
            value: _email,
            onTap: () =>
                _edit('Email', _email, (v) => setState(() => _email = v)),
          ),
          LedgerSettingRow(
            title: 'Phone',
            value: _phone,
            onTap: () =>
                _edit('Phone', _phone, (v) => setState(() => _phone = v)),
          ),
        ],
      ),
    );

    final alerts = LedgerSection(
      head: const LedgerHead('Alerts', note: 'What Quill tells you'),
      child: LedgerRows(
        children: [
          for (final a in kitAlerts)
            LedgerToggleRow(
              icon: a.icon,
              title: a.label,
              subtitle: a.sub,
              value: prefs.alerts[a.label] ?? false,
              onChanged: (v) => prefs.update((p) => p.alerts[a.label] = v),
            ),
        ],
      ),
    );

    final currency = LedgerSelect<String>(
      label: 'Currency',
      value: prefs.currency,
      items: const [
        LedgerSelectItem(value: 'USD', label: 'US dollar'),
        LedgerSelectItem(value: 'EUR', label: 'Euro'),
        LedgerSelectItem(value: 'GBP', label: 'Pound sterling'),
      ],
      onChanged: (v) => prefs.update((p) => p.currency = v),
    );
    final week = LedgerSelect<String>(
      label: 'Week starts on',
      value: prefs.weekStart,
      items: const [
        LedgerSelectItem(value: 'monday', label: 'Monday'),
        LedgerSelectItem(value: 'sunday', label: 'Sunday'),
      ],
      onChanged: (v) => prefs.update((p) => p.weekStart = v),
    );
    final density = LedgerSelect<LedgerDensity>(
      label: 'Density',
      value: prefs.density,
      helper: 'Each step sets rows and controls 4 px tighter',
      items: const [
        LedgerSelectItem(value: LedgerDensity.standard, label: 'Standard'),
        LedgerSelectItem(
          value: LedgerDensity.comfortable,
          label: 'Comfortable',
        ),
        LedgerSelectItem(value: LedgerDensity.compact, label: 'Compact'),
      ],
      onChanged: (v) => prefs.update((p) => p.density = v),
    );
    const fieldGap = LedgerGap(LedgerSpacing.s24);
    final preferences = LedgerSection(
      head: const LedgerHead('Preferences', note: 'This device'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A row's words stand 14 into it: the first label stands there too.
          const LedgerGap(LedgerSpacing.s14),
          if (paired)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: currency),
                const SizedBox(width: LedgerSpacing.s24),
                Expanded(child: week),
              ],
            )
          else ...[
            currency,
            fieldGap,
            week,
          ],
          fieldGap,
          // On the same half grid as Currency: a blank the width of its
          // words, not the column's.
          if (paired)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: density),
                const SizedBox(width: LedgerSpacing.s24),
                const Spacer(),
              ],
            )
          else
            density,
        ],
      ),
    );

    final appearance = LedgerSection(
      head: const LedgerHead('Appearance', note: 'Paper and ink'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (value, label) in const [
            (QuillAppearance.light, 'Light'),
            (QuillAppearance.dark, 'Dark'),
            (QuillAppearance.system, 'As the system is'),
          ])
            LedgerRadio<QuillAppearance>(
              value: value,
              groupValue: prefs.appearance,
              label: label,
              onChanged: (v) => prefs.update((p) => p.appearance = v!),
            ),
        ],
      ),
    );

    final reading = LedgerSection(
      head: const LedgerHead('Reading', note: 'Which way the pages run'),
      child: LedgerToggleRow(
        icon: LucideIcons.arrowRightLeft,
        title: 'Right to left',
        subtitle: 'The pages mirrored, as Arabic and Hebrew read',
        value: prefs.direction == TextDirection.rtl,
        onChanged: (on) => prefs.update(
          (p) => p.direction = on ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );

    // On a phone it spans the column, as a phone's last act does; from 600
    // it hugs its words on the section's keyline (a 512 bar read as a
    // banner).
    final signOut = Align(
      alignment: AlignmentDirectional.centerStart,
      child: LedgerButton(
        'Sign out',
        isDestructiveAction: true,
        expand: !paired,
        onPressed: _signOut,
      ),
    );

    const gap = LedgerGap(LedgerSpacing.s40);
    return LedgerScreen(
      topBar: const LedgerTopBar(title: 'Settings', meta: 'Quill 1.0'),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [profile, gap, alerts, gap, reading],
                  ),
                ),
                const SizedBox(width: LedgerSpacing.s56),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [preferences, gap, appearance, gap, signOut],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                profile,
                gap,
                alerts,
                gap,
                reading,
                gap,
                preferences,
                gap,
                appearance,
                gap,
                signOut,
              ],
            ),
    );
  }
}
