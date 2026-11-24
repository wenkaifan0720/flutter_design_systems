import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:ui_core/ui_core.dart' show RawDialogAction;

import '../design/design.dart';
import '../garden.dart';

enum _Leave { stay, discard, save }

/// One plant's page: what it is, where it stands, its light and its
/// watering, and its notes. A new plant when [plant] is null.
class PlantScreen extends StatefulWidget {
  /// The page of [plant], or of a new one.
  const PlantScreen({super.key, this.plant});

  /// The plant edited; null for a new one.
  final Plant? plant;

  @override
  State<PlantScreen> createState() => _PlantScreenState();
}

class _PlantScreenState extends State<PlantScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.plant?.name,
  );
  final TextEditingController _note = TextEditingController();
  late String? _species = widget.plant?.species;
  late String _room = widget.plant?.room ?? 'Living room';
  late Light _light = widget.plant?.light ?? Light.medium;
  late DateTime? _watered = widget.plant?.lastWatered;
  late bool _reminders = widget.plant?.reminders ?? true;
  late bool _mist = widget.plant?.mist ?? false;
  late List<String> _notes = [...?widget.plant?.notes];
  bool _changed = false;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _change(VoidCallback change) => setState(() {
    change();
    _changed = true;
  });

  /// Saves the plant and leaves; false when its name is missing.
  bool _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give the plant a name');
      return false;
    }
    final garden = GardenScope.of(context);
    final today = garden.today;
    garden.put(
      Plant(
        id: widget.plant?.id ?? garden.nextId,
        name: name,
        species: _species,
        room: _room,
        light: _light,
        lastWatered: _watered ?? today,
        everyDays: widget.plant?.everyDays ?? 7,
        reminders: _reminders,
        mist: _mist,
        notes: _notes,
      ),
    );
    _changed = false;
    Navigator.pop(context);
    return true;
  }

  /// Asks what to do with the changes before the page goes.
  Future<void> _leave() async {
    final answer = await showTendDialog<_Leave>(
      context,
      title: 'Discard your changes?',
      content: const Text('The plant keeps what it had before.'),
      actions: (context) => [
        RawDialogAction(
          label: 'Keep editing',
          onPressed: () => Navigator.pop(context, _Leave.stay),
        ),
        RawDialogAction(
          label: 'Discard',
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context, _Leave.discard),
        ),
        RawDialogAction(
          label: 'Save',
          onPressed: () => Navigator.pop(context, _Leave.save),
        ),
      ],
    );
    if (!mounted) return;
    switch (answer) {
      case _Leave.discard:
        Navigator.pop(context);
      case _Leave.save:
        _save();
      case _Leave.stay || null:
        break;
    }
  }

  Future<void> _addNote() async {
    _note.clear();
    final note = await showTendSheet<String>(
      context,
      title: 'Add a note',
      content: TendTextField(labelText: 'Note', controller: _note),
      actions: (context) => [
        TendButton(
          'Cancel',
          variant: TendButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        TendButton(
          'Add',
          onPressed: () => Navigator.pop(context, _note.text.trim()),
        ),
      ],
    );
    if (note != null && note.isNotEmpty) {
      _change(() => _notes = [..._notes, note]);
    }
  }

  void _careTips() => unawaited(
    showTendPanel<void>(
      context,
      title: 'Caring for ${_species ?? 'this plant'}',
      builder: (context, close) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(switch (_light) {
            Light.bright => 'Give it a sunny window and water it when the top of the soil is dry.',
            Light.medium => 'Keep it bright but out of the midday sun, and let the soil dry a little between waterings.',
            Light.low => 'It manages in a dim corner. Water it rarely: too much water harms it more than too little.',
          }),
          const SizedBox(height: 24),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TendButton('Done', onPressed: close),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final garden = GardenScope.of(context);
    final theme = TendTheme.of(context);
    final today = garden.today;
    final adding = widget.plant == null;
    return PopScope<Object?>(
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_leave());
      },
      child: TendScaffold(
        title: adding ? 'New plant' : widget.plant!.name,
        actions: [
          TendIconButton(
            icon: Icons.info_outline,
            semanticLabel: 'Care tips',
            onPressed: _careTips,
          ),
        ],
        bottomBar: Align(
          alignment: AlignmentDirectional.centerEnd,
          // Nothing to save until something changed: null turns it off.
          child: TendButton(
            'Save',
            onPressed: adding || _changed ? () => _save() : null,
          ),
        ),
        body: TendColumn(
          maxWidth: 560,
          children: [
            TendTextField(
              labelText: 'Name',
              hintText: 'What you call it',
              required: true,
              controller: _name,
              errorText: _nameError,
              onChanged: (_) => _change(() => _nameError = null),
            ),
            const SizedBox(height: 16),
            TendCombobox<String>(
              labelText: 'Species',
              options: species,
              value: _species,
              onSelected: (next) => _change(() => _species = next),
            ),
            const SizedBox(height: 16),
            TendSelect<String>(
              labelText: 'Room',
              options: garden.rooms,
              value: _room,
              onChanged: (next) => _change(() => _room = next),
            ),
            const SizedBox(height: 16),
            const TendHeading('Light'),
            TendRadioGroup<Light>(
              value: _light,
              onChanged: (next) => _change(() => _light = next),
              options: const [
                TendRadioOption(value: Light.bright, label: 'A sunny window'),
                TendRadioOption(
                  value: Light.medium,
                  label: 'Bright, out of the sun',
                ),
                TendRadioOption(value: Light.low, label: 'A dim corner'),
              ],
            ),
            const SizedBox(height: 16),
            TendDateField(
              labelText: 'Last watered',
              value: _watered,
              firstDate: today.subtract(const Duration(days: 365)),
              lastDate: today,
              onChanged: (next) => _change(() => _watered = next),
            ),
            const SizedBox(height: 16),
            TendCheckbox(
              value: _mist,
              label: 'Mist the leaves on watering days',
              onChanged: (next) => _change(() => _mist = next!),
            ),
            // The words beside the switch name it: one node, read together.
            MergeSemantics(
              child: Row(
                children: [
                  Expanded(
                    child: Text('Remind me to water it', style: theme.body),
                  ),
                  TendSwitch(
                    value: _reminders,
                    onChanged: (next) => _change(() => _reminders = next),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const TendHeading('Notes'),
            for (final note in _notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(note),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TendButton(
                'Add a note',
                icon: Icons.add,
                variant: TendButtonVariant.outlined,
                onPressed: _addNote,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
