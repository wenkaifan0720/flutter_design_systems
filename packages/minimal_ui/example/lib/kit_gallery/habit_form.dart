/// The gallery's shared New habit form: one source for the New habit
/// screen's sheet and for the example's Habits app, where Create adds the
/// habit to Today with an undo.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'habits.dart';

/// The create form, as a page the sheet card carries: its bar is the card
/// header (the quiet title, the close), the name is the page's own field,
/// then a note and the property pills, and the footer holds the "Create
/// another" switch beside Cancel and Create habit. [habits] receives the
/// habit; null only says so in a toast.
class KitNewHabitPage extends StatefulWidget {
  const KitNewHabitPage({
    super.key,
    this.habits,
    this.name = '',
    this.onCreated,
  });

  final KitHabits? habits;

  /// Says a habit was made, once the sheet is closed: its toast's [message]
  /// and the [undo] that takes it back off. Null toasts from the page the
  /// sheet was raised over.
  final void Function(String message, VoidCallback? undo)? onCreated;

  /// The name the field starts with.
  final String name;

  @override
  State<KitNewHabitPage> createState() => _KitNewHabitPageState();
}

class _KitNewHabitPageState extends State<KitNewHabitPage> {
  late final _name = TextEditingController(text: widget.name);
  final _note = TextEditingController();
  bool _another = false;

  // The set properties, and the one still to choose (null).
  String _repeat = 'Every evening';
  String _reminder = '21:30';
  String _group = 'Evening';
  String? _goal;

  @override
  void initState() {
    super.initState();
    _name.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _name
      ..removeListener(_changed)
      ..dispose();
    _note.dispose();
    super.dispose();
  }

  void _create() {
    final name = _name.text.trim();
    final habits = widget.habits;
    final habit = habits?.add(
      name: name,
      group: _group,
      note: _note.text.trim(),
      repeat: _repeat,
      reminder: _reminder,
    );
    final message = '$name added to $_group';
    final undo = habit == null ? null : () => habits!.remove(habit);
    void toast(BuildContext context) => showMinimalSnackBar(
      context,
      message,
      icon: LucideIcons.check,
      actionLabel: undo == null ? null : 'Undo',
      onAction: undo,
    );
    if (_another) {
      _name.clear();
      _note.clear();
      toast(context);
      return;
    }
    final navigator = Navigator.of(context);
    final under = navigator.context;
    navigator.pop();
    final announce = widget.onCreated;
    announce == null ? toast(under) : announce(message, undo);
  }

  /// A property pill whose menu offers [choices]: set, it prints the
  /// value; unset, the property's [name].
  MinimalPropertyPill _pill({
    required IconData icon,
    required String name,
    required String? value,
    required List<String> choices,
    required ValueChanged<String> pick,
    bool mono = false,
  }) => MinimalPropertyPill(
    icon: icon,
    label: value ?? name,
    name: name,
    hasValue: value != null,
    mono: mono && value != null,
    items: [
      for (final choice in choices)
        MinimalMenuItem(
          choice,
          selected: choice == value,
          onPressed: () => setState(() => pick(choice)),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final named = _name.text.trim().isNotEmpty;
    return MinimalScaffold(
      topBar: const MinimalAppBar(title: 'New habit', subtitle: 'Habits'),
      // The card's own footer line: the switch prints its own words; when
      // they and the actions do not share a line, the actions drop under
      // them, each keeping its edge.
      footer: MinimalSheetFooter(
        accessory: MinimalSwitch(
          value: _another,
          label: 'Create another',
          showLabel: true,
          onChanged: (on) => setState(() => _another = on),
        ),
        leading: const MinimalSheetAction('Cancel'),
        trailing: MinimalSheetAction(
          'Create habit',
          isDefaultAction: true,
          enabled: named,
          onPressed: _create,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MinimalTextField(
            bare: true,
            controller: _name,
            hint: 'Habit name',
            style: t.h1,
            autofocus: widget.name.isEmpty,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
          ),
          MinimalTextField(
            bare: true,
            controller: _note,
            hint: 'Add a note…',
            style: t.body,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const MinimalGap(MinimalSpacing.s12),
          MinimalPropertyBar(
            pills: [
              _pill(
                icon: LucideIcons.repeat,
                name: 'Repeat',
                value: _repeat,
                choices: kitHabitRepeats,
                pick: (v) => _repeat = v,
              ),
              _pill(
                icon: LucideIcons.bell,
                name: 'Reminder',
                value: _reminder,
                mono: true,
                choices: const ['06:30', '07:00', '21:00', '21:30', '22:00'],
                pick: (v) => _reminder = v,
              ),
              _pill(
                icon: LucideIcons.folder,
                name: 'Group',
                value: _group,
                choices: kitHabitGroups,
                pick: (v) => _group = v,
              ),
              _pill(
                icon: LucideIcons.target,
                name: 'Goal',
                value: _goal,
                choices: const ['3 a week', '5 a week', 'Every time'],
                pick: (v) => _goal = v,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
