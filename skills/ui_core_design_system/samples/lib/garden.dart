import 'package:flutter/widgets.dart';

/// How much light a plant wants.
enum Light {
  /// A sunny window.
  bright,

  /// Bright, but out of the sun.
  medium,

  /// A corner away from the windows.
  low,
}

/// Whether the app shows itself by day or by night.
enum Appearance {
  /// As the device is set.
  system,

  /// Always by day.
  light,

  /// Always by night.
  dark,
}

/// The species the species field offers.
const List<String> species = [
  'Aloe vera',
  'Calathea orbifolia',
  'Epipremnum aureum',
  'Ficus lyrata',
  'Monstera deliciosa',
  'Olea europaea',
  'Pilea peperomioides',
  'Sansevieria trifasciata',
  'Strelitzia nicolai',
  'Zamioculcas zamiifolia',
];

/// One plant and its watering.
@immutable
class Plant {
  /// A plant given field by field.
  const Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.room,
    required this.light,
    required this.lastWatered,
    required this.everyDays,
    this.reminders = true,
    this.mist = false,
    this.notes = const [],
  });

  /// Which plant it is, whatever it is called.
  final int id;

  /// What its owner calls it.
  final String name;

  /// What it is; null when its owner does not know.
  final String? species;

  /// Where it stands.
  final String room;

  /// How much light it wants.
  final Light light;

  /// The day it was last watered.
  final DateTime lastWatered;

  /// How many days it goes between waterings.
  final int everyDays;

  /// Whether the app reminds its owner to water it.
  final bool reminders;

  /// Whether its leaves are misted when it is watered.
  final bool mist;

  /// What its owner wrote about it, oldest first.
  final List<String> notes;

  /// The day it wants water next.
  DateTime get nextWatering => lastWatered.add(Duration(days: everyDays));

  /// Days from [today] until it wants water: 0 today, below 0 when late.
  int daysLeft(DateTime today) => nextWatering.difference(today).inDays;

  /// This plant with the given fields changed.
  Plant copyWith({
    String? name,
    String? species,
    String? room,
    Light? light,
    DateTime? lastWatered,
    int? everyDays,
    bool? reminders,
    bool? mist,
    List<String>? notes,
  }) => Plant(
    id: id,
    name: name ?? this.name,
    species: species ?? this.species,
    room: room ?? this.room,
    light: light ?? this.light,
    lastWatered: lastWatered ?? this.lastWatered,
    everyDays: everyDays ?? this.everyDays,
    reminders: reminders ?? this.reminders,
    mist: mist ?? this.mist,
    notes: notes ?? this.notes,
  );
}

/// The plants, the rooms they stand in, and the app's settings.
class Garden extends ChangeNotifier {
  /// A garden of [plants] in [rooms], on [today].
  Garden({
    required List<Plant> plants,
    required List<String> rooms,
    required this.outdoorRooms,
    required this.today,
  }) : _plants = [...plants],
       _rooms = [...rooms];

  /// A garden of five plants, for a first start and for tests.
  factory Garden.example({DateTime? today}) {
    final now = today ?? DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    DateTime ago(int days) => day.subtract(Duration(days: days));
    return Garden(
      today: day,
      rooms: const ['Living room', 'Kitchen', 'Bedroom', 'Hall', 'Balcony'],
      outdoorRooms: const {'Balcony'},
      plants: [
        Plant(
          id: 1,
          name: 'Monty',
          species: 'Monstera deliciosa',
          room: 'Living room',
          light: Light.medium,
          lastWatered: ago(6),
          everyDays: 7,
          notes: const ['New leaf unfurling by the window.'],
        ),
        Plant(
          id: 2,
          name: 'Fig',
          species: 'Ficus lyrata',
          room: 'Bedroom',
          light: Light.bright,
          lastWatered: ago(11),
          everyDays: 10,
        ),
        Plant(
          id: 3,
          name: 'Pip',
          species: 'Pilea peperomioides',
          room: 'Kitchen',
          light: Light.bright,
          lastWatered: ago(2),
          everyDays: 5,
          mist: true,
        ),
        Plant(
          id: 4,
          name: 'Snake plant',
          species: 'Sansevieria trifasciata',
          room: 'Hall',
          light: Light.low,
          lastWatered: ago(25),
          everyDays: 21,
          reminders: false,
        ),
        Plant(
          id: 5,
          name: 'Olive',
          species: 'Olea europaea',
          room: 'Balcony',
          light: Light.bright,
          lastWatered: ago(1),
          everyDays: 4,
        ),
      ],
    );
  }

  /// The day the garden is read on.
  final DateTime today;

  /// The rooms that are outside.
  final Set<String> outdoorRooms;

  final List<Plant> _plants;
  final List<String> _rooms;

  /// The plants, in the order of their rooms.
  List<Plant> get plants => [
    for (final room in _rooms) ..._plants.where((p) => p.room == room),
  ];

  /// The rooms, in the order the reader set.
  List<String> get rooms => List.unmodifiable(_rooms);

  /// Whether the app shows itself by day or by night.
  Appearance get appearance => _appearance;
  Appearance _appearance = Appearance.system;
  set appearance(Appearance value) {
    if (value == _appearance) return;
    _appearance = value;
    notifyListeners();
  }

  /// Whether the app reminds its owner on watering days.
  bool get reminders => _reminders;
  bool _reminders = true;
  set reminders(bool value) {
    if (value == _reminders) return;
    _reminders = value;
    notifyListeners();
  }

  /// When in the day the reminder comes.
  String get reminderTime => _reminderTime;
  String _reminderTime = 'Morning';
  set reminderTime(String value) {
    if (value == _reminderTime) return;
    _reminderTime = value;
    notifyListeners();
  }

  /// A new plant's id.
  int get nextId => _plants.fold(0, (top, p) => p.id > top ? p.id : top) + 1;

  /// Adds [plant], or puts it in place of the plant with its id.
  void put(Plant plant) {
    final at = _plants.indexWhere((p) => p.id == plant.id);
    if (at < 0) {
      _plants.add(plant);
    } else {
      _plants[at] = plant;
    }
    notifyListeners();
  }

  /// Marks [plant] watered today.
  void water(Plant plant) => put(plant.copyWith(lastWatered: today));

  /// Takes [plant] out of the garden.
  void remove(Plant plant) {
    _plants.removeWhere((p) => p.id == plant.id);
    notifyListeners();
  }

  /// Moves the room at [from] to [to].
  void moveRoom(int from, int to) {
    _rooms.insert(to, _rooms.removeAt(from));
    notifyListeners();
  }
}

/// Gives the screens below it the garden, and rebuilds them as it changes.
class GardenScope extends InheritedNotifier<Garden> {
  /// Puts [garden] over [child].
  const GardenScope({super.key, required Garden garden, required super.child})
    : super(notifier: garden);

  /// The garden over [context].
  static Garden of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GardenScope>()!.notifier!;
}
