/// Larder's Settings: the appearance, reading direction and density the
/// whole app takes, the notices it sends, and the account.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'larder.dart';

/// Settings.
class LarderSettings extends StatelessWidget {
  /// Settings.
  const LarderSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = LarderPrefs.of(context);
    final frame = LarderFrame.of(context);
    final shopper = prefs.account;
    void edit(_Setting setting) => frame.push(_SettingsPage(setting: setting));
    const gap = SizedBox(height: ApplianceSpacing.extraLarge);
    Widget toggle(
      String title,
      String? subtitle,
      IconData icon,
      bool value,
      void Function(LarderPrefs p, bool v) set,
    ) => ApplianceListTile(
      leading: Icon(icon),
      title: title,
      subtitle: subtitle,
      trailing: ApplianceSwitch(
        value: value,
        semanticLabel: title,
        onChanged: (v) => prefs.update((p) => set(p, v)),
      ),
    );
    final density = ApplianceSelect<ApplianceDensity>(
      labelText: 'Density',
      value: prefs.density,
      items: const [
        ApplianceSelectItem(
          value: ApplianceDensity.standard,
          label: 'Standard',
        ),
        ApplianceSelectItem(
          value: ApplianceDensity.comfortable,
          label: 'Comfortable',
        ),
        ApplianceSelectItem(value: ApplianceDensity.compact, label: 'Compact'),
      ],
      onChanged: (v) => prefs.update((p) => p.density = v),
    );
    final direction = ApplianceSelect<TextDirection>(
      labelText: 'Reading direction',
      value: prefs.direction,
      items: const [
        ApplianceSelectItem(value: TextDirection.ltr, label: 'Left to right'),
        ApplianceSelectItem(value: TextDirection.rtl, label: 'Right to left'),
      ],
      onChanged: (v) => prefs.update((p) => p.direction = v),
    );
    List<Widget> appearance(bool wide) => [
      const ApplianceSectionHeader('Appearance'),
      AppliancePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ApplianceSegmentedButton<LarderAppearance>(
              semanticLabel: 'Appearance',
              expand: true,
              segments: const [
                ApplianceSegment(
                  value: LarderAppearance.light,
                  label: 'Light',
                  icon: Icon(LucideIcons.sun),
                ),
                ApplianceSegment(
                  value: LarderAppearance.dark,
                  label: 'Dark',
                  icon: Icon(LucideIcons.moon),
                ),
                ApplianceSegment(
                  value: LarderAppearance.system,
                  label: 'System',
                  icon: Icon(LucideIcons.monitor),
                ),
              ],
              value: prefs.appearance,
              onChanged: (v) => prefs.update((p) => p.appearance = v),
            ),
            const SizedBox(height: ApplianceSpacing.large),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: density),
                  const SizedBox(width: ApplianceSpacing.regular),
                  Expanded(child: direction),
                ],
              )
            else ...[
              density,
              const SizedBox(height: ApplianceSpacing.large),
              direction,
            ],
            const SizedBox(height: ApplianceSpacing.large),
            const ApplianceDivider(),
            const SizedBox(height: ApplianceSpacing.regular),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Show prices with tax',
                    style: context.applianceTheme.textTheme.body,
                  ),
                ),
                const SizedBox(width: ApplianceSpacing.medium),
                ApplianceSwitch(
                  value: prefs.withTax,
                  semanticLabel: 'Show prices with tax',
                  onChanged: (v) => prefs.update((p) => p.withTax = v),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
    final notices = ApplianceListGroup(
      header: 'Notices',
      footer: 'Order updates come as an order moves; the letter once a month.',
      children: [
        toggle(
          'Order updates',
          'When an order ships and arrives',
          LucideIcons.bell,
          prefs.orderUpdates,
          (p, v) => p.orderUpdates = v,
        ),
        toggle(
          'New season letter',
          'The new goods, once a month',
          LucideIcons.sparkles,
          prefs.newsletter,
          (p, v) => p.newsletter = v,
        ),
        toggle(
          'Key sounds',
          null,
          LucideIcons.volume2,
          prefs.keySounds,
          (p, v) => p.keySounds = v,
        ),
      ],
    );
    final account = ApplianceListGroup(
      header: 'Account',
      children: [
        if (shopper == null)
          ApplianceListTile(
            leading: const Icon(LucideIcons.user),
            title: 'Sign in to demo account',
            onTap: prefs.signIn,
          )
        else ...[
          ApplianceListTile(
            leading: const Icon(LucideIcons.user),
            title: 'Name',
            trailingText: shopper.name,
            onTap: () => edit(_Setting.name),
          ),
          ApplianceListTile(
            leading: const Icon(LucideIcons.mapPin),
            title: 'Address',
            trailingText: shopper.address,
            onTap: () => edit(_Setting.address),
          ),
          ApplianceListTile(
            leading: const Icon(LucideIcons.creditCard),
            title: 'Cards',
            trailingText: 'One saved',
            onTap: () => edit(_Setting.cards),
          ),
          ApplianceListTile(
            title: 'Sign out',
            isDestructiveAction: true,
            showChevron: false,
            onTap: frame.signOut,
          ),
        ],
      ],
    );
    final help = ApplianceListGroup(
      header: 'Help',
      children: [
        ApplianceListTile(
          leading: const Icon(LucideIcons.packageCheck),
          title: 'Delivery and returns',
          onTap: () => edit(_Setting.delivery),
        ),
        ApplianceListTile(
          leading: const Icon(LucideIcons.mail),
          title: 'Write to the shop',
          onTap: () => edit(_Setting.contact),
        ),
        ApplianceListTile(
          leading: const Icon(LucideIcons.info),
          title: 'About Larder',
          onTap: () => LarderFrame.of(context).go(LarderPlace.overview),
        ),
        const ApplianceListTile(
          leading: Icon(LucideIcons.tag),
          title: 'Version',
          trailingText: '1.0',
          showChevron: false,
        ),
      ],
    );
    Widget column(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    return LarderPage(
      title: 'Settings',
      maxWidth: larderDeskWidth,
      children: [
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 860
              // On a desk, two rows of panes: how the app looks beside what
              // it sends; who you are beside where to ask.
              ? column([
                  for (final (i, (start, end)) in [
                    (column(appearance(true)), notices),
                    (account, help),
                  ].indexed) ...[
                    if (i > 0) gap,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: start),
                        const SizedBox(width: ApplianceSpacing.large),
                        Expanded(child: end),
                      ],
                    ),
                  ],
                ])
              : Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ApplianceMetrics.readingWidth,
                    ),
                    child: column([
                      ...appearance(false),
                      gap,
                      notices,
                      gap,
                      account,
                      gap,
                      help,
                    ]),
                  ),
                ),
        ),
      ],
    );
  }
}

enum _Setting {
  name('Name'),
  address('Address'),
  cards('Cards'),
  delivery('Delivery and returns'),
  contact('Write to the shop');

  const _Setting(this.title);
  final String title;
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage({required this.setting});
  final _Setting setting;

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  final _value = TextEditingController();
  final _postcode = TextEditingController();
  bool _initialized = false;
  bool _submitted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final account = LarderPrefs.of(context).account;
    if (account == null) return;
    switch (widget.setting) {
      case _Setting.name:
        _value.text = account.name;
      case _Setting.address:
        _value.text = account.address;
        _postcode.text = account.postcode;
      case _Setting.cards:
      case _Setting.delivery:
      case _Setting.contact:
        break;
    }
  }

  @override
  void dispose() {
    _value.dispose();
    _postcode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = LarderPrefs.of(context);
    final account = prefs.account;
    final setting = widget.setting;
    if (setting == _Setting.delivery) {
      return LarderPage(
        title: setting.title,
        children: [
          const AppliancePanel(
            child: ApplianceDescriptionList(
              items: [
                (
                  'Standard delivery',
                  '3 to 5 days. £4.50, or free on orders of £40 or more.',
                ),
                ('Next-day delivery', '£6.50 when you order by 8 pm.'),
                (
                  'Returns',
                  'Write to the shop with the order number and the items you would like to return.',
                ),
              ],
            ),
          ),
          larderGroupGap,
          ApplianceButton(
            'Write to the shop',
            onPressed: () =>
                LarderFrame.of(context)
                    .push(const _SettingsPage(setting: _Setting.contact)),
          ),
        ],
      );
    }
    final contact = setting == _Setting.contact;
    if (account == null && !contact) {
      return LarderPage(
        title: setting.title,
        children: [
          ApplianceButton('Sign in to demo account', onPressed: prefs.signIn),
        ],
      );
    }
    final label = switch (setting) {
      _Setting.name => 'Full name',
      _Setting.address => 'Street address',
      _Setting.cards => 'Card number',
      _Setting.contact => 'Message',
      _Setting.delivery => throw StateError('Delivery has no form'),
    };
    String? error() {
      if (_value.text.trim().isEmpty) {
        return 'Enter a ${label.toLowerCase()}.';
      }
      if (setting == _Setting.cards &&
          (_value.text.length < 12 || _value.text.length > 19)) {
        return 'Enter 12 to 19 digits.';
      }
      return null;
    }

    void save() {
      final value = _value.text.trim();
      if (error() != null ||
          setting == _Setting.address && _postcode.text.trim().isEmpty) {
        setState(() => _submitted = true);
        return;
      }
      if (contact) {
        prefs.update((p) => p.messages.insert(0, value));
        _value.clear();
        setState(() => _submitted = false);
        showApplianceToast(context, 'Message saved');
        return;
      }
      final changed = switch (setting) {
        _Setting.name => account!.copyWith(name: value),
        _Setting.address => account!.copyWith(
          address: value,
          postcode: _postcode.text.trim().toUpperCase(),
        ),
        _Setting.cards => account!.copyWith(
          cardLast4: value.substring(value.length - 4),
        ),
        _ => throw StateError('This page has no saved account field'),
      };
      prefs.saveAccount(changed);
      Navigator.of(context).pop();
    }

    void revalidate(String _) {
      if (_submitted) setState(() {});
    }

    return LarderPage(
      title: setting.title,
      children: [
        AppliancePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (setting == _Setting.cards) ...[
                Text('Saved card ending ${account!.cardLast4}'),
                const SizedBox(height: ApplianceSpacing.regular),
              ],
              ApplianceTextField(
                labelText: label,
                controller: _value,
                helperText: contact ? 'Messages are saved in this demo.' : null,
                maxLines: contact ? 4 : 1,
                keyboardType: setting == _Setting.cards
                    ? TextInputType.number
                    : null,
                inputFormatters: setting == _Setting.cards
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                errorText: _submitted ? error() : null,
                onChanged: revalidate,
              ),
              if (setting == _Setting.address) ...[
                const SizedBox(height: ApplianceSpacing.regular),
                ApplianceTextField(
                  labelText: 'Postcode',
                  controller: _postcode,
                  textCapitalization: TextCapitalization.characters,
                  errorText: _submitted && _postcode.text.trim().isEmpty
                      ? 'Enter a postcode.'
                      : null,
                  onChanged: revalidate,
                ),
              ],
              const SizedBox(height: ApplianceSpacing.large),
              ApplianceButton.filled(
                contact ? 'Save message' : 'Save changes',
                onPressed: save,
              ),
            ],
          ),
        ),
        if (contact && prefs.messages.isNotEmpty) ...[
          larderGroupGap,
          const ApplianceSectionHeader('Saved messages'),
          ApplianceListGroup(
            children: [
              for (final message in prefs.messages)
                ApplianceListTile(title: message, showChevron: false),
            ],
          ),
        ],
      ],
    );
  }
}
