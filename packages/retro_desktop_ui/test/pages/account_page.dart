// Asking for something, and keeping it set: fields in a labelled group, choices with notes, checkboxes for on and off, and the
// one action at the window's foot. Its stars are RetroDesktopGroupBox and RetroDesktopChoices in the active window. Copy it for sign-up,
// a booking, an order, settings, a profile. This form uses RetroDesktopCheckRow for its on/off settings.
import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key, this.onSave});
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return RetroDesktopScaffold(
      topBar: const RetroDesktopAppBar(title: 'Your details'),
      body: RetroDesktopDesktop(
        active: 'Your details',
        tiles: [
          RetroDesktopWindowColumn(
            span: 7,
            windows: [
              RetroDesktopWindow(
                title: 'Your details',
                icon: LucideIcons.user,
                status: const ['Saved 09:14'],
                child: RetroDesktopSections(
                  children: [
                    RetroDesktopBeside(
                      object: const RetroDesktopMonogram('YN'),
                      child: const RetroDesktopSectionHeader(
                        'Your name',
                        note: 'Member since 2019',
                      ),
                    ),
                    RetroDesktopGroupBox(
                      title: 'Name and address',
                      icon: LucideIcons.mail,
                      child: RetroDesktopColumn(
                        gap: 12,
                        children: [
                          const RetroDesktopFormField(
                            label: 'Name',
                            child: RetroDesktopTextField(initial: 'Your name'),
                          ),
                          const RetroDesktopFormField(
                            label: 'Email',
                            help: 'Only for your receipts',
                            child: RetroDesktopTextField(
                              hint: 'you@example.com',
                              leading: Icon(LucideIcons.mail),
                            ),
                          ),
                          RetroDesktopFormField(
                            label: 'Region',
                            child: RetroDesktopPopupButton(
                              'Pick one',
                              onPressed: onSave,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RetroDesktopGroupBox(
                      title: 'How often',
                      child: RetroDesktopChoices(
                        options: const [
                          RetroDesktopChoice('Every day', note: 'At nine'),
                          RetroDesktopChoice('Every week', note: 'On Monday'),
                          RetroDesktopChoice('Never', note: 'Only when asked'),
                        ],
                        onChanged: (_) {},
                        value: 'Every week',
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: RetroDesktopButton(
                        'Save changes',
                        isDefaultAction: true,
                        onPressed: onSave,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          RetroDesktopWindowColumn(
            span: 5,
            windows: [
              RetroDesktopWindow(
                title: 'Reminders',
                icon: LucideIcons.bell,
                child: RetroDesktopColumn(
                  gap: 8,
                  children: [
                    RetroDesktopCheckRow(
                      label: 'Before something is due',
                      note: 'An hour ahead',
                      value: true,
                      onChanged: (_) {},
                    ),
                    RetroDesktopCheckRow(
                      label: 'When someone replies',
                      value: false,
                      onChanged: (_) {},
                    ),
                    const RetroDesktopDivider.etched(),
                    const RetroDesktopNumberField(
                      value: 2,
                      unit: 'reminders a day',
                      note: 'Up to 5',
                    ),
                  ],
                ),
              ),
              const RetroDesktopWindow(
                title: 'About you',
                child: RetroDesktopSections(
                  children: [
                    RetroDesktopDescriptionList([
                      RetroDesktopFact('Plan', 'The middle one'),
                      RetroDesktopFact('Renews', '14 Mar 2027', figures: true),
                      RetroDesktopFact('Devices', '3 of 5'),
                    ]),
                    RetroDesktopDivider.etched(),
                    RetroDesktopGaugeBlock(
                      value: '3',
                      of: 'of 5 devices',
                      share: .6,
                      endLabel: '60%',
                      footStart: 'In use',
                      footEnd: '2 free',
                    ),
                    RetroDesktopDivider.etched(),
                    RetroDesktopTreeBars(
                      rows: [
                        RetroDesktopTreeRow('Laptop', 'today', share: .9),
                        RetroDesktopTreeRow('Phone', 'today', share: .6),
                        RetroDesktopTreeRow('Tablet', 'Monday', share: .2),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
