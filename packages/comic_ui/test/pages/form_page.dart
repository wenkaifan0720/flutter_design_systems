// Making something new. The star is `ComicFormField`: a square label, one control, a line of help, in panels. A `ComicBalloon` asks the
// question, `ComicChoices` picks from a few, `ComicNumberField` counts, and one `ComicButton.filled` ends it. Copy it for a composer, a sign-up,
// any page whose job is one form.
import 'package:material_ui/material_ui.dart';
import 'package:comic_ui/comic_ui.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  var _kind = 'Out';
  var _people = 4;
  var _ask = true;
  var _late = false;

  @override
  Widget build(BuildContext context) {
    return ComicScaffold(
      topBar: ComicAppBar(
        title: 'Something new',
        leading: ComicAppBar.autoLeading(context),
      ),
      body: ComicSections(
        children: [
          ComicTier(
            spans: const [7, 5],
            phone: ComicTierLayout.stack,
            children: [
              ComicPanel(
                caption: 'The basics',
                child: ComicColumn(
                  gap: 14,
                  children: [
                    const ComicBalloon("What's the plan?"),
                    const ComicFormField(
                      'A name for it',
                      help: 'The first thing people will read.',
                      child: ComicTextField(hint: 'The long weekend'),
                    ),
                    ComicFormField(
                      'When',
                      child: ComicSelectField(
                        value: 'Fri 4 – Sun 6',
                        note: 'Two nights',
                        onPressed: () {},
                      ),
                    ),
                    const ComicFormField(
                      'A few words',
                      child: ComicTextField(
                        hint: 'What should people bring?',
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
              ComicPanel(
                caption: 'The details',
                child: ComicColumn(
                  gap: 14,
                  children: [
                    ComicFormField(
                      'What kind',
                      child: ComicChoices(
                        options: const [
                          ComicChoice('Out', note: 'Somewhere else'),
                          ComicChoice('In', note: 'At someone\'s'),
                          ComicChoice('Away', note: 'Overnight'),
                        ],
                        value: _kind,
                        onChanged: (kind) => setState(() => _kind = kind),
                      ),
                    ),
                    ComicFormField(
                      'How many',
                      child: ComicNumberField(
                        value: _people,
                        unit: 'people',
                        onChanged: (next) => setState(() => _people = next),
                        min: 1,
                      ),
                    ),
                    ComicSwitchRow(
                      isFirst: true,
                      label: 'Ask everyone',
                      note: 'A vote goes out with it.',
                      value: _ask,
                      onChanged: (on) => setState(() => _ask = on),
                    ),
                    ComicSwitchRow(
                      label: 'Late answers',
                      note: 'Leave it open after the day.',
                      value: _late,
                      onChanged: (on) => setState(() => _late = on),
                    ),
                    ComicButton.filled('Send it round', onPressed: () {}),
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
