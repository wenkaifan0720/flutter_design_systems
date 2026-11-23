import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Fields: a small well cut into the case; the select, a key.
Widget kitFieldsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Text fields',
  sections: [
    const _Fields(),
    const _Selects(),
    ...kitSpecimens(const [
      'SearchField',
      'PasswordField',
      'InputGroup',
      'InputOtp',
      'NumberField',
      'FormField',
    ]),
  ],
);

class _Fields extends StatelessWidget {
  const _Fields();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Fields',
    note: 'Focus lights a band inside the well\'s edge.',
    gap: KeycapSpacing.large,
    children: [
      const KeycapTextField(labelText: 'Folder name', hintText: 'Garden'),
      const KeycapTextField(
        labelText: 'Search',
        semanticLabel: 'Search notes',
        hintText: 'Search notes',
        leading: Icon(LucideIcons.search),
      ),
      const KeycapTextField(
        labelText: 'Email',
        helperText: 'Where shared notes are sent from',
        keyboardType: TextInputType.emailAddress,
      ),
      const KeycapTextField(
        labelText: 'Folder name',
        errorText: 'There is already a folder called Work.',
      ),
      const KeycapTextField(
        labelText: 'Disabled',
        hintText: 'Not now',
        enabled: false,
      ),
      const KeycapTextField(
        labelText: 'Description',
        hintText: 'What goes in this folder',
        maxLines: 4,
        minLines: 3,
      ),
      Row(
        children: [
          const Expanded(
            child: KeycapTextField(semanticLabel: 'Tag', hintText: 'Add a tag'),
          ),
          const SizedBox(width: KeycapSpacing.small),
          KeycapButton(onPressed: () {}, child: const Text('Add')),
        ],
      ),
    ],
  );
}

class _Selects extends StatefulWidget {
  const _Selects();

  @override
  State<_Selects> createState() => _SelectsState();
}

class _SelectsState extends State<_Selects> {
  String _format = 'md';
  String? _folder;

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Selects',
    note: 'A key showing its value; its list opens on the chosen row.',
    gap: KeycapSpacing.large,
    children: [
      KeycapSelect<String>(
        labelText: 'Export as',
        value: _format,
        items: const [
          KeycapSelectItem(value: 'md', label: 'Markdown'),
          KeycapSelectItem(value: 'txt', label: 'Plain text'),
          KeycapSelectItem(value: 'pdf', label: 'PDF'),
          KeycapSelectItem(value: 'html', label: 'Web page'),
        ],
        onChanged: (v) => setState(() => _format = v),
      ),
      KeycapSelect<String>(
        labelText: 'Folder',
        hintText: 'Choose a folder',
        value: _folder,
        items: const [
          KeycapSelectItem(value: 'inbox', label: 'Inbox'),
          KeycapSelectItem(value: 'work', label: 'Work'),
          KeycapSelectItem(value: 'garden', label: 'Garden'),
          KeycapSelectItem(value: 'archive', label: 'Archive', enabled: false),
        ],
        onChanged: (v) => setState(() => _folder = v),
      ),
      const KeycapSelect<String>(
        labelText: 'Disabled',
        value: 'a',
        items: [KeycapSelectItem(value: 'a', label: 'Markdown')],
        onChanged: null,
      ),
    ],
  );
}
