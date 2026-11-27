import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';

import '../kit.dart';

/// Fields and selects: wells to type in, keys that open a list.
Widget kitFieldsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Text fields',
  sections: const [_Fields(), _MoreFields()],
);

class _Fields extends StatefulWidget {
  const _Fields();

  @override
  State<_Fields> createState() => _FieldsState();
}

class _FieldsState extends State<_Fields> {
  String? _shelf = 'brewing';
  String _sort = 'featured';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const KitSection(
        title: 'Text fields',
        note: 'A sunken well; focused, an orange bezel lights round it.',
        gap: ApplianceSpacing.large,
        children: [
          ApplianceTextField(
            labelText: 'Full name',
            hintText: 'As on the door',
          ),
          ApplianceTextField(
            labelText: 'Search',
            hintText: 'Pots, tins, kettles',
            leading: Icon(LucideIcons.search),
          ),
          ApplianceTextField(
            labelText: 'Postcode',
            errorText: 'Enter a postcode we deliver to',
          ),
          ApplianceTextField(
            labelText: 'Gift note',
            helperText: 'Up to 200 letters',
            maxLines: 3,
          ),
          ApplianceTextField(
            labelText: 'Account',
            enabled: false,
            hintText: 'Rosa Lind',
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Selects',
        note: 'A key printed with its value; its list lights the chosen lamp.',
        gap: ApplianceSpacing.large,
        children: [
          ApplianceSelect<String?>(
            labelText: 'Shelf',
            value: _shelf,
            items: const [
              ApplianceSelectItem(value: null, label: 'All goods'),
              ApplianceSelectItem(value: 'cookware', label: 'Cookware'),
              ApplianceSelectItem(value: 'brewing', label: 'Coffee and tea'),
              ApplianceSelectItem(value: 'tableware', label: 'Tableware'),
              ApplianceSelectItem(value: 'storage', label: 'Storage'),
              ApplianceSelectItem(value: 'home', label: 'Home', enabled: false),
            ],
            onChanged: (v) => setState(() => _shelf = v),
          ),
          ApplianceSelect<String>(
            labelText: 'Sort by',
            value: _sort,
            helperText: 'Featured puts the new season first',
            items: const [
              ApplianceSelectItem(value: 'featured', label: 'Featured'),
              ApplianceSelectItem(value: 'low', label: 'Price, low to high'),
              ApplianceSelectItem(value: 'high', label: 'Price, high to low'),
            ],
            onChanged: (v) => setState(() => _sort = v),
          ),
          const ApplianceSelect<String>(
            labelText: 'Size',
            value: null,
            hintText: 'Choose a size',
            items: [ApplianceSelectItem(value: 's', label: 'Small')],
            onChanged: null,
          ),
        ],
      ),
    ],
  );
}

/// The other wells: search, password, a well with its units, a code, a
/// labelled field round any control.
class _MoreFields extends StatelessWidget {
  const _MoreFields();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitSection(
        title: 'Search and password',
        note: 'A lens at the start; a clear key once typed. An eye key shows the words.',
        children: [
          ApplianceSearchField(hintText: 'Search the shop'),
          AppliancePasswordField(helperText: 'At least 12 letters'),
          AppliancePasswordField(
            labelText: 'Old password',
            errorText: 'That is not it',
          ),
          ApplianceSearchField(hintText: 'Search (off)', enabled: false),
        ],
      ),
      SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Units and codes',
        note: 'Units moulded at the well\'s ends; a code in display-window cells.',
        children: [
          ApplianceInputGroup(
            labelText: 'Budget',
            prefix: '£',
            suffix: 'a month',
          ),
          ApplianceInputGroup(
            labelText: 'Weight',
            suffix: 'kg',
            errorText: 'At most 30 kg',
          ),
          ApplianceOtpField(),
          ApplianceOtpField(isError: true, semanticLabel: 'Code, wrong'),
        ],
      ),
      SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Labelled fields',
        note: 'Any control with its label, help and what is wrong.',
        children: [
          ApplianceField(
            labelText: 'Postcode',
            helperText: 'For the delivery',
            required: true,
            child: ApplianceTextField(semanticLabel: 'Postcode'),
          ),
          ApplianceField(
            labelText: 'Email',
            errorText: 'Add an @ and a domain',
            child: ApplianceTextField(semanticLabel: 'Email'),
          ),
        ],
      ),
    ],
  );
}
