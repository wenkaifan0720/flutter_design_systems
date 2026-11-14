/// Minimal's text entry: the boxed field in every register and state
/// (label, helper, error, glyph, secure, mono with a unit, clearable, notes,
/// read-only, disabled), the bare page-as-field a create form's title
/// wants, and the grouped form — hairline input rows beside label-and-
/// control rows, validated live.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitInputDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Input & form',
  sections: [
    kitSection(
      'Field',
      children: [
        const MinimalTextField(
          label: 'Name',
          hint: 'Stretch before bed',
          helper: 'Shown on Today and in reminders.',
        ),
        _Filled(
          text: 'Morning run',
          builder: (c) => MinimalTextField(
            label: 'Name',
            controller: c,
            clearable: true,
            helper: 'Clearable: the glyph at the end empties it.',
          ),
        ),
      ],
    ),
    kitSection(
      'States',
      children: [
        _Filled(
          text: '05:30',
          builder: (c) => MinimalTextField(
            label: 'Reminder',
            controller: c,
            mono: true,
            icon: LucideIcons.bell,
            error: 'Pick a time after 06:00.',
          ),
        ),
        _Filled(
          text: 'HAB-4',
          builder: (c) => MinimalTextField(
            label: 'Identifier',
            controller: c,
            mono: true,
            readOnly: true,
            helper: 'Read-only: select and copy, not edit.',
          ),
        ),
        _Filled(
          text: 'Habits',
          builder: (c) =>
              MinimalTextField(label: 'Team', controller: c, enabled: false),
        ),
      ],
    ),
    kitSection(
      'Registers',
      children: [
        const MinimalTextField(
          label: 'Email',
          hint: 'you@ritual.app',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        _Filled(
          text: 'correct horse',
          builder: (c) => MinimalTextField(
            label: 'Password',
            controller: c,
            obscureText: true,
            icon: LucideIcons.lock,
          ),
        ),
        _Filled(
          text: '20',
          builder: (c) => MinimalTextField(
            label: 'Daily goal',
            controller: c,
            mono: true,
            suffix: 'pages',
            keyboardType: TextInputType.number,
          ),
        ),
        const MinimalTextField(
          label: 'Note',
          hint: 'Out the door before 8. Any distance counts.',
          maxLines: 3,
        ),
      ],
    ),
    kitSection(
      'Bare',
      children: [
        Builder(
          builder: (context) {
            final t = context.minimalTheme;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Filled(
                  text: 'Stretch before bed',
                  builder: (c) =>
                      MinimalTextField(bare: true, controller: c, style: t.h1),
                ),
                const MinimalGap(MinimalSpacing.s4),
                const MinimalTextField(bare: true, hint: 'Add a note…'),
              ],
            );
          },
        ),
        kitNote(
          'The page is the field: no box, no rule. A create form\'s title '
          'and note.',
        ),
      ],
    ),
    kitSection(
      'Form',
      children: [
        kitNote(
          'A create form: hairline input rows under the form\'s own group '
          'label, validated as they are typed and on submit.',
        ),
        // The form's group label stands off the line as a section header
        // stands off what is above it, so the two are not read as one.
        const MinimalGap(MinimalSpacing.s8),
        const _HabitForm(),
      ],
    ),
    kitSection(
      'Form rows',
      children: [
        // The note leads, as the create form's does: the group's own footer
        // is the one line under its rows.
        kitNote(
          'A form row names an act or a switch, in the ink; a row that '
          'holds a value is a picker or a date row, its key quiet. A group '
          'with a picker keeps the picker\'s measure: from a tablet up it '
          'stops at 320 px, on its start.',
        ),
        const _Reminders(),
      ],
    ),
  ],
);

const List<MinimalSelectOption<String>> _sounds = [
  MinimalSelectOption('chime', 'Chime'),
  MinimalSelectOption('bell', 'Bell'),
  MinimalSelectOption('none', 'None'),
];

/// Label-and-control rows beside the value rows they sit with: a time and
/// a sound as property rows, then a button and an action.
class _Reminders extends StatefulWidget {
  const _Reminders();

  @override
  State<_Reminders> createState() => _RemindersState();
}

class _RemindersState extends State<_Reminders> {
  DateTime _at = DateTime(2026, 8, 28, 21, 30);
  String _sound = 'chime';

  @override
  Widget build(BuildContext context) => MinimalFormSection(
    footer: 'Reminders follow the device time zone.',
    children: [
      MinimalDatePicker(
        label: 'Remind me at',
        icon: LucideIcons.bell,
        value: _at,
        mode: MinimalDatePickerMode.time,
        onChanged: (v) => setState(() => _at = v),
      ),
      MinimalSelect(
        label: 'Sound',
        icon: LucideIcons.volume2,
        value: _sound,
        options: _sounds,
        onChanged: (v) => setState(() => _sound = v),
      ),
      // The row names what its button does: a reminder sent now, to try it.
      MinimalFormRow(
        label: 'Test reminder',
        icon: LucideIcons.bellRing,
        trailing: MinimalButton(
          'Send now',
          size: MinimalButtonSize.small,
          variant: MinimalButtonVariant.secondary,
          onPressed: () {},
        ),
      ),
      MinimalFormRow(
        label: 'Archive habit',
        icon: LucideIcons.archive,
        onPressed: () {},
      ),
    ],
  );
}

/// A field that starts with text in it: owns the controller the demo
/// hands its field.
class _Filled extends StatefulWidget {
  const _Filled({required this.text, required this.builder});

  final String text;
  final Widget Function(TextEditingController controller) builder;

  @override
  State<_Filled> createState() => _FilledState();
}

class _FilledState extends State<_Filled> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

/// A live create form: hairline input rows, validated as they are typed
/// and on submit, beside a disabled row and a mono count.
class _HabitForm extends StatefulWidget {
  const _HabitForm();

  @override
  State<_HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends State<_HabitForm> {
  final _name = TextEditingController(text: 'Stretch before bed');
  final _goal = TextEditingController(text: '0');
  final _note = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    _note.dispose();
    super.dispose();
  }

  String? get _nameError =>
      _name.text.trim().isEmpty ? 'A habit needs a name.' : null;

  String? get _goalError {
    final goal = int.tryParse(_goal.text.trim());
    if (goal == null) return 'Minutes, as a whole number.';
    if (goal < 1 || goal > 240) return 'Between 1 and 240 minutes.';
    return null;
  }

  void _create() {
    setState(() => _submitted = true);
    if (_nameError == null && _goalError == null) {
      showMinimalSnackBar(
        context,
        '${_name.text.trim()} created',
        icon: LucideIcons.circleCheck,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalFormSection(
          title: 'New habit',
          footer: 'Name and goal are required.',
          children: [
            MinimalInputRow(
              label: 'Name',
              icon: LucideIcons.type,
              controller: _name,
              hint: 'Stretch before bed',
              error: _submitted ? _nameError : null,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.next,
            ),
            MinimalInputRow(
              label: 'Goal',
              icon: LucideIcons.target,
              controller: _goal,
              hint: '10',
              mono: true,
              keyboardType: TextInputType.number,
              error: _goalError,
              onChanged: (_) => setState(() {}),
            ),
            MinimalInputRow(
              label: 'Note',
              icon: LucideIcons.notebookPen,
              controller: _note,
              hint: 'Why it matters',
              maxLines: 2,
            ),
            const MinimalInputRow(
              label: 'Area',
              icon: LucideIcons.folder,
              hint: 'Evening',
              enabled: false,
            ),
          ],
        ),
        const MinimalGap(MinimalSpacing.s12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: MinimalButton('Create habit', onPressed: _create),
        ),
      ],
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// A labelled field waiting for its value, with a helper line.
Widget kitSpecimenInputField() => const MinimalTextField(
  label: 'Name',
  hint: 'Stretch before bed',
  helper: 'Shown on Today and in reminders.',
);

/// A filled password field, its glyph leading.
Widget kitSpecimenInputPassword() => _Filled(
  text: 'correct horse',
  builder: (c) => MinimalTextField(
    label: 'Password',
    controller: c,
    obscureText: true,
    icon: LucideIcons.lock,
  ),
);

/// A mono time the form refuses, its message under the field.
Widget kitSpecimenInputError() => _Filled(
  text: '05:30',
  builder: (c) => MinimalTextField(
    label: 'Reminder',
    controller: c,
    mono: true,
    icon: LucideIcons.bell,
    error: 'Pick a time after 06:00.',
  ),
);

/// A note that rests three lines tall.
Widget kitSpecimenInputMultiline() => _Filled(
  text:
      'Out the door before 8. Any distance counts, even a walk round the '
      'block on a bad day.',
  builder: (c) =>
      MinimalTextField(label: 'Note', controller: c, maxLines: 3, minLines: 3),
);

/// Labelled fields inline in a form, the label column quiet.
Widget kitSpecimenInputRowForm() => _Body(
  child: MinimalFormSection(
    title: 'Habit',
    children: [
      _Filled(
        text: 'Stretch before bed',
        builder: (c) => MinimalInputRow(label: 'Name', controller: c),
      ),
      const MinimalInputRow(
        label: 'Goal',
        hint: 'Minutes a day',
        mono: true,
        keyboardType: TextInputType.number,
      ),
    ],
  ),
);

/// An inline row the form refuses, its message under the row.
Widget kitSpecimenInputRowError() => _Body(
  child: MinimalFormSection(
    children: [
      _Filled(
        text: '0',
        builder: (c) => MinimalInputRow(
          label: 'Goal',
          controller: c,
          mono: true,
          error: 'Between 1 and 240 minutes.',
        ),
      ),
    ],
  ),
);

/// A reminders group: its label, a time, a picker, a switch, the footer.
Widget kitSpecimenFormSectionReminders() => _Body(
  child: MinimalFormSection(
    title: 'Reminders',
    footer: 'Reminders follow the device time zone.',
    children: [
      MinimalDatePicker(
        label: 'Remind me at',
        icon: LucideIcons.bell,
        value: DateTime(2026, 8, 28, 21, 30),
        mode: MinimalDatePickerMode.time,
        onChanged: (_) {},
      ),
      MinimalSelect(
        label: 'Sound',
        icon: LucideIcons.volume2,
        value: 'chime',
        options: _sounds,
        onChanged: (_) {},
      ),
      MinimalFormRow(
        label: 'Snooze',
        icon: LucideIcons.alarmClock,
        trailing: MinimalSwitch(
          value: true,
          label: 'Snooze',
          onChanged: (_) {},
        ),
      ),
    ],
  ),
);

/// A row that names a switch, the switch at its end.
Widget kitSpecimenFormRowControl() => MinimalFormRow(
  label: 'Remind me',
  icon: LucideIcons.bell,
  trailing: MinimalSwitch(value: true, label: 'Remind me', onChanged: (_) {}),
);

/// A row that is itself the act, with its forward chevron.
Widget kitSpecimenFormRowChevron() => MinimalFormRow(
  label: 'Archive habit',
  icon: LucideIcons.archive,
  onPressed: () {},
);

/// Lays a specimen out as a scrolling page body does: its own height,
/// however tall the stage.
class _Body extends StatelessWidget {
  const _Body({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      UnconstrainedBox(constrainedAxis: Axis.horizontal, child: child);
}
