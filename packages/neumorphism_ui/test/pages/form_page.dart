// A form. Star: pressed fields with a printed edge, big choice wells with an LED, a stepper, one act. Copy it for anything a person fills in. Every field
// holds its edge with no shadow; what's selected carries the pigment and bold words, so a flat screen still tells you.
import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class FormPage extends StatelessWidget {
  const FormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final act = NeumorphicButton.filled(
      'Send it',
      icon: NeumorphicGlyphs.send,
      wide: true,
      onPressed: () {},
    );
    final who = NeumorphicCard(
      title: 'Who',
      children: [
        const NeumorphicFormGroup(
          labelText: 'Name',
          child: NeumorphicTextField(hintText: 'A name'),
        ),
        const NeumorphicFormGroup(
          labelText: 'Email',
          helperText: 'Only for this. We send one note.',
          child: NeumorphicTextField(
            hintText: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        NeumorphicFormGroup(
          labelText: 'Where',
          child: NeumorphicSelectField(value: 'A town', onPressed: () {}),
        ),
      ],
    );
    final what = NeumorphicCard(
      title: 'What',
      children: [
        NeumorphicFormGroup(
          labelText: 'Which one',
          child: NeumorphicChoices(
            options: const [
              NeumorphicChoice('The small one', note: 'For one or two'),
              NeumorphicChoice('The middle one', note: 'For a team'),
              NeumorphicChoice('The large one', note: 'For a building'),
            ],
            value: 'The middle one',
            onChanged: (_) {},
          ),
        ),
        NeumorphicFormGroup(
          labelText: 'How many',
          child: NeumorphicNumberField(
            value: 3,
            unit: 'people',
            helperText: 'Up to 12',
            onChanged: (_) {},
          ),
        ),
        NeumorphicSwitchRow(
          label: 'Send a copy',
          subtitle: 'To the same address',
          value: true,
          onChanged: (_) {},
        ),
      ],
    );
    final note = NeumorphicCard(
      title: 'Anything else',
      children: [
        NeumorphicTextField(hintText: 'A note', maxLines: t.desk ? 6 : 3),
      ],
    );
    const summary = NeumorphicCard(
      title: 'So far',
      children: [
        NeumorphicList(
          children: [
            NeumorphicKvRow('Which one', 'The middle one', isFirst: true),
            NeumorphicKvRow('People', '3'),
            NeumorphicTotalRow('Total', '€60'),
          ],
        ),
      ],
    );
    return NeumorphicScaffold(
      topBar: NeumorphicAppBar(
        title: 'A form',
        leading: NeumorphicAppBar.autoLeading(context),
      ),
      footer: t.desk ? null : act,
      body: t.desk
          ? NeumorphicRow(
              spans: const [6, 6],
              children: [
                NeumorphicColumn(
                  gap: 28,
                  children: [
                    who,
                    NeumorphicGrow(child: note),
                  ],
                ),
                NeumorphicColumn(gap: 28, children: [what, summary, act]),
              ],
            )
          : NeumorphicSections(children: [who, what, note, summary]),
    );
  }
}
