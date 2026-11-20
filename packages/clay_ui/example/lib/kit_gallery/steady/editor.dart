/// Steady's habit editor: a new habit or one being changed, its name, its
/// colour and glyph, when and how often, its goal, its reminder (chosen on a
/// sheet), and its deletion (asked in a dialog).
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'steady.dart';

/// What the editor opens with, for a link or a test.
enum SteadyEditorOpening {
  /// Nothing over it.
  none,

  /// The dialog asking to delete the habit.
  delete,

  /// The sheet choosing the reminder's time.
  reminder,
}

/// The editor of [habit], or of a new habit when null.
class SteadyEditor extends StatefulWidget {
  /// An editor.
  const SteadyEditor({
    super.key,
    this.habit,
    this.opening = SteadyEditorOpening.none,
  });

  /// The habit changed; a new one when null.
  final SteadyHabit? habit;

  /// What opens over it at once.
  final SteadyEditorOpening opening;

  @override
  State<SteadyEditor> createState() => _SteadyEditorState();
}

const _glyphs = [
  LucideIcons.droplets,
  LucideIcons.footprints,
  LucideIcons.bookOpen,
  LucideIcons.flower2,
  LucideIcons.penLine,
  LucideIcons.personStanding,
  LucideIcons.moonStar,
  LucideIcons.leaf,
];

class _SteadyEditorState extends State<SteadyEditor> {
  late final TextEditingController _name = TextEditingController(
    text: widget.habit?.name ?? '',
  );
  late final TextEditingController _goal = TextEditingController(
    text: '${widget.habit?.goal ?? 1}',
  );
  late ClayTint _tint = widget.habit?.tint ?? ClayTint.mint;
  late IconData _icon = widget.habit?.icon ?? LucideIcons.leaf;
  late SteadyTime _time = widget.habit?.time ?? SteadyTime.morning;
  late String _repeat = widget.habit?.repeat ?? 'daily';
  late int? _reminder = widget.habit?.reminder;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    if (widget.opening != SteadyEditorOpening.none) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.opening == SteadyEditorOpening.delete) {
          _confirmDelete();
        } else {
          _chooseReminder();
        }
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give the habit a name');
      return;
    }
    final frame = SteadyFrame.of(context);
    final goal = int.tryParse(_goal.text) ?? 1;
    final h =
        widget.habit ??
        SteadyHabit(
          id: 'new-${frame.habits.length}',
          name: name,
          tint: _tint,
          icon: _icon,
          time: _time,
          repeat: _repeat,
          goal: goal,
          unit: goal > 1 ? 'times' : '',
          progress: 0,
          streak: 0,
          best: 0,
          history: List.filled(35, false),
        );
    h
      ..name = name
      ..tint = _tint
      ..icon = _icon
      ..time = _time
      ..repeat = _repeat
      ..goal = goal
      ..reminder = _reminder;
    frame.save(h);
    Navigator.of(context).maybePop();
    showClayToast(
      context,
      widget.habit == null ? 'Habit added' : 'Habit saved',
    );
  }

  Future<void> _confirmDelete() async {
    final h = widget.habit;
    if (h == null) return;
    final frame = SteadyFrame.of(context);
    final navigator = Navigator.of(context);
    final yes = await showClayDialog<bool>(
      context: context,
      isAlert: true,
      builder: (context) => ClayDialog(
        title: 'Delete “${h.name}”?',
        content: Text(
          h.streak > 0
              ? 'Its ${h.streak}-day run and its history go with it. '
                    'Pausing keeps them.'
              : 'Its history goes with it. Pausing keeps it.',
        ),
        actions: [
          ClayDialogAction(
            label: 'Keep',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ClayDialogAction(
            label: 'Delete',
            primary: true,
            destructive: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (yes ?? false) {
      frame.delete(h);
      navigator.maybePop();
    }
  }

  Future<void> _chooseReminder() async {
    final picked = await showClayBottomSheet<int?>(
      context: context,
      title: 'Reminder time',
      builder: (context) => _ReminderSheet(initial: _reminder ?? 8 * 60),
    );
    if (picked != null && mounted) setState(() => _reminder = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final c = theme.colors;
    final editing = widget.habit != null;
    return SteadyPage(
      title: editing ? 'Edit habit' : 'New habit',
      maxWidth: 560,
      bottom: SteadyKeys(
        primary: ClayButton.filled(
          editing ? 'Save habit' : 'Add habit',
          onPressed: _save,
        ),
        secondary: ClayButton(
          'Cancel',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      children: [
        ClayTextField(
          controller: _name,
          label: 'Name',
          hint: 'Drink water',
          error: _nameError,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        steadyGroupGap,
        // Every label on one line, where a field's words start; the balls
        // under a label start there too.
        const ClayFieldLabel('Colour'),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: ClayMetrics.fieldInset,
          ),
          child: Wrap(
            spacing: ClaySpacing.medium,
            runSpacing: ClaySpacing.medium,
            children: [
              for (final t in ClayTint.values)
                _Swatch(
                  color: c.tint(t),
                  label: t.name,
                  chosen: t == _tint,
                  onPressed: () => setState(() => _tint = t),
                ),
            ],
          ),
        ),
        steadyGroupGap,
        const ClayFieldLabel('Glyph'),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: ClayMetrics.fieldInset,
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              // As many to a row as fit, the rows even (four and four on a
              // phone, not seven and one).
              const ball = 44.0, gap = ClaySpacing.small;
              final fit = math.max(
                1,
                ((box.maxWidth + gap) / (ball + gap)).floor(),
              );
              final rows = (_glyphs.length / fit).ceil();
              final perRow = (_glyphs.length / rows).ceil();
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: perRow * (ball + gap) - gap,
                  child: Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final g in _glyphs)
                        ClayIconButton(
                          onPressed: () => setState(() => _icon = g),
                          selected: g == _icon,
                          icon: Icon(g),
                          tooltip: 'Glyph ${_glyphs.indexOf(g) + 1}',
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        steadyGroupGap,
        const ClayFieldLabel('Time of day'),
        ClaySegmentedButton<SteadyTime>(
          segments: [
            for (final t in SteadyTime.values)
              ClaySegment(value: t, label: t.label),
          ],
          selected: _time,
          onChanged: (t) => setState(() => _time = t),
          semanticLabel: 'Time of day',
        ),
        steadyGroupGap,
        ClaySelect<String>(
          label: 'Repeat',
          value: _repeat,
          items: [
            for (final e in steadyRepeats.entries)
              ClaySelectItem(value: e.key, label: e.value),
          ],
          onChanged: (v) => setState(() => _repeat = v),
        ),
        steadyGroupGap,
        ClayTextField(
          controller: _goal,
          label: 'Daily goal',
          helper: '1 for a yes-or-no habit',
          keyboardType: TextInputType.number,
          // Two digits at most, without a count: '1/2' under a number
          // reads as a half.
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          suffix: Text(
            int.tryParse(_goal.text) == 1 ? 'time' : 'times',
            style: theme.textTheme.secondary,
          ),
          onChanged: (_) => setState(() {}),
        ),
        steadyGroupGap,
        ClayGroup(
          children: [
            ClayListTile(
              leading: const Icon(LucideIcons.bell),
              title: 'Remind me',
              trailing: ClaySwitch(
                value: _reminder != null,
                onChanged: (on) =>
                    setState(() => _reminder = on ? 8 * 60 : null),
                semanticLabel: 'Remind me',
              ),
            ),
            ClayListTile(
              leading: const Icon(LucideIcons.clock),
              title: 'Time',
              trailingText: _reminder == null ? 'Off' : steadyClock(_reminder!),
              enabled: _reminder != null,
              onTap: _reminder == null ? null : _chooseReminder,
            ),
          ],
        ),
        if (editing) ...[
          steadyGroupGap,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ClayButton.text(
              'Delete habit',
              icon: const Icon(LucideIcons.trash2),
              isDestructiveAction: true,
              onPressed: _confirmDelete,
            ),
          ),
        ],
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.chosen,
    required this.onPressed,
  });

  final Color color;
  final String label;
  final bool chosen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ClayIconButton(
    onPressed: onPressed,
    selected: chosen,
    tooltip: label,
    style: ClayStyle(fill: WidgetStatePropertyAll(color)),
    icon: chosen
        ? const Icon(LucideIcons.check)
        : const SizedBox.square(dimension: 20),
  );
}

/// The reminder's time: the hour and the minute on clay drums a thumb turns,
/// and the key that sets it.
class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({required this.initial});

  final int initial;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late ClayTime _time = ClayTime(
    hour: widget.initial ~/ 60,
    minute: (widget.initial % 60) ~/ 5 * 5,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClayTimePicker(
          value: _time,
          onChanged: (t) => setState(() => _time = t),
          semanticLabel: 'Reminder time',
        ),
        const SizedBox(height: ClaySpacing.large),
        ClayButton.filled(
          'Set reminder',
          onPressed: () =>
              Navigator.of(context).pop(_time.hour * 60 + _time.minute),
        ),
      ],
    );
  }
}
