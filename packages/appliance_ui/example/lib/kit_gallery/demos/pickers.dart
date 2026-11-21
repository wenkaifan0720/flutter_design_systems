import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Pickers: wells that suggest, choices latched as keys, chips, the
/// calendar and the date and time pickers, a tray for a file, a colour.
Widget kitPickersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Pickers',
  sections: const [_Pickers()],
);

/// A slow lookup of the shops that stock a kettle, as a server answers.
Future<Iterable<String>> _stockists(String words) => Future.delayed(
  const Duration(milliseconds: 1200),
  () => const [
    'Leith Hardware',
    'Portobello Kitchens',
    'Musselburgh Electric',
  ].where((s) => s.toLowerCase().contains(words.toLowerCase())),
);

/// A lookup with no connection: it fails after a moment.
Future<Iterable<String>> _offline(String words) => Future.delayed(
  const Duration(milliseconds: 600),
  () => throw StateError('No connection'),
);

class _Pickers extends StatefulWidget {
  const _Pickers();

  @override
  State<_Pickers> createState() => _PickersState();
}

class _PickersState extends State<_Pickers> {
  String? _town;
  List<String> _rooms = const ['Kitchen'];
  final Set<String> _filters = {'In stock'};
  final List<String> _picked = ['Kettles', 'Teapots'];
  DateTime? _day = DateTime(2026, 11, 20);
  RawDateRange? _away;
  ApplianceTime _time = const ApplianceTime(18, 30);
  ApplianceTime _alarm = const ApplianceTime(7, 15);
  bool _over = false;
  final _calendar = RawCalendarController(
    firstDate: DateTime(2026, 11),
    lastDate: DateTime(2027, 3, 31),
    mode: RawCalendarMode.range,
    selectedRange: RawDateRange(DateTime(2026, 11, 18), DateTime(2026, 11, 24)),
    currentDate: DateTime(2026, 11, 16),
  );
  final _colour = RawColorController(const Color(0xFFEE6A26));

  @override
  void dispose() {
    _calendar.dispose();
    _colour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitSection(
        title: 'Wells that suggest',
        note: 'Type and the plate opens; Enter takes the lit row and keeps typing.',
        children: [
          ApplianceCombobox<String>(
            label: 'Town',
            value: _town,
            onSelected: (t) => setState(() => _town = t),
            options: const ['Leith', 'Portobello', 'Musselburgh', 'Dalkeith'],
            helper: 'Where we deliver',
          ),
          ApplianceTagInput<String>(
            label: 'Rooms',
            values: _rooms,
            onChanged: (r) => setState(() => _rooms = r),
            options: const ['Kitchen', 'Hall', 'Garden', 'Larder', 'Bathroom'],
            onCreate: (text) => text.trim().isEmpty ? null : text.trim(),
            hint: 'Add a room',
          ),
          const ApplianceCombobox<String>(
            label: 'Town (off)',
            options: ['Leith'],
            enabled: false,
          ),
          ApplianceCombobox<String>(
            label: 'Stockist',
            helper: 'Looked up as you type: the plate says so while it looks',
            debounceDuration: const Duration(milliseconds: 250),
            search: _stockists,
          ),
          ApplianceCombobox<String>(
            label: 'Stockist (offline)',
            helper:
                'The lookup fails: the plate says so, with a row to try again',
            search: _offline,
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Chips',
        note: 'A chip latches down with its lamp; one with a cross removes.',
        children: [
          KitRow(
            children: [
              for (final f in const ['In stock', 'On offer', 'Electric'])
                ApplianceChip(
                  f,
                  selected: _filters.contains(f),
                  onSelected: (on) =>
                      setState(() => on ? _filters.add(f) : _filters.remove(f)),
                ),
            ],
          ),
          KitRow(
            children: [
              for (final p in _picked)
                ApplianceChip(
                  p,
                  onDeleted: () => setState(() => _picked.remove(p)),
                ),
              const ApplianceChip('Shown only'),
            ],
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'Dates and times',
        note: 'Chosen days are lit keys; the days between them a trough.',
        children: [
          ApplianceDatePicker(
            label: 'Delivery day',
            value: _day,
            firstDate: DateTime(2026, 11, 16),
            lastDate: DateTime(2027, 2, 28),
            currentDate: DateTime(2026, 11, 16),
            selectable: (d) => d.weekday != DateTime.sunday,
            helper: 'No deliveries on Sundays',
            onChanged: (d) => setState(() => _day = d),
          ),
          ApplianceDateRangePicker(
            label: 'Away',
            value: _away,
            firstDate: DateTime(2026, 11, 16),
            lastDate: DateTime(2027, 2, 28),
            currentDate: DateTime(2026, 11, 16),
            onChanged: (r) => setState(() => _away = r),
          ),
          SizedBox(width: 308, child: ApplianceCalendar(controller: _calendar)),
          KitRow(
            children: [
              ApplianceTimePicker(
                value: _time,
                onChanged: (t) => setState(() => _time = t),
                semanticLabel: 'Delivery time',
              ),
              ApplianceTimePicker(
                value: _alarm,
                twentyFourHour: false,
                onChanged: (t) => setState(() => _alarm = t),
                semanticLabel: 'Reminder',
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: ApplianceSpacing.extraLarge),
      KitSection(
        title: 'A file and a colour',
        note: 'A tray lights while a file is over it; a colour in its window.',
        children: [
          ApplianceDropZone(
            label: 'Drop a photo of the receipt',
            hint: 'PNG or JPG, up to 10 MB',
            icon: const Icon(LucideIcons.imageUp),
            active: _over,
            onPressed: () => setState(() => _over = !_over),
          ),
          SizedBox(
            width: 300,
            child: ApplianceColorPicker(controller: _colour, showAlpha: true),
          ),
        ],
      ),
    ],
  );
}
