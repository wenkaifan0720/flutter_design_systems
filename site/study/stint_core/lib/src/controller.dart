import 'package:flutter/foundation.dart';

import 'fixtures.dart';
import 'forms.dart';
import 'models.dart';
import 'repository.dart';
import 'words.dart';

/// A link to the documentation site can pass these options to any study's
/// public widget.
class StintLaunch {
  const StintLaunch({
    this.place = Place.today,
    this.detail = false,
    this.appearance = Appearance.system,
    this.language = StintLanguage.en,
    this.scale,
    this.compact = false,
    this.accent,
    this.scenario = '',
    this.semantics = false,
    this.settings,
  });
  factory StintLaunch.fromUri(Uri uri) {
    final fragment = Uri.tryParse(uri.fragment);
    final p = {...uri.queryParameters, ...?fragment?.queryParameters};
    final page =
        p['page'] ??
        fragment?.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
    final scale = double.tryParse(p['scale'] ?? '');
    return StintLaunch(
      place: page == 'detail'
          ? Place.tasks
          : Place.values.asNameMap()[page] ?? Place.today,
      detail: page == 'detail',
      appearance: switch (p['theme']) {
        'day' || 'light' => Appearance.day,
        'night' || 'dark' => Appearance.night,
        _ => Appearance.system,
      },
      // dir=rtl: links from before Japanese and German open in Arabic.
      language: p['dir'] == 'rtl'
          ? StintLanguage.ar
          : StintLanguage.forCode(p['lang']),
      scale: scale != null && scale.isFinite
          ? scale.clamp(1, 2).toDouble()
          : null,
      compact: p['density'] == 'compact',
      accent: p['accent'],
      scenario: p['state'] ?? '',
      semantics: p['a11y'] == '1',
    );
  }
  final Place place;
  final bool detail, compact, semantics;
  final Appearance appearance;
  final StintLanguage language;
  final double? scale;
  final String scenario;

  /// The palette the look takes on, by [StintPalette.id]; null keeps the
  /// look's own.
  final String? accent;

  /// Settings a host shares with the running app: the documentation page's
  /// quick controls change them while it runs, and the app's own Settings
  /// page changes the same object. Null: the app makes its own from these
  /// options.
  final StintSettings? settings;

  /// These options, with [settings] shared with the app.
  StintLaunch sharing(StintSettings settings) => StintLaunch(
    place: place,
    detail: detail,
    appearance: appearance,
    language: language,
    scale: scale,
    compact: compact,
    accent: accent,
    scenario: scenario,
    semantics: semantics,
    settings: settings,
  );

  StintRepository createRepository() => StintRepository(
    empty: scenario == 'empty',
    failNext: scenario == 'error',
    latency: Duration(milliseconds: scenario == 'loading' ? 3000 : 220),
  );
}

class StintSettings extends ChangeNotifier {
  StintSettings(StintLaunch launch)
    : appearance = launch.appearance,
      language = launch.language,
      scale = launch.scale,
      compact = launch.compact,
      accent = launch.accent;
  Appearance appearance;
  StintLanguage language;
  bool compact;
  double? scale;

  /// The palette the look takes on, by [StintPalette.id]; null, or an id the
  /// edition doesn't offer, keeps the look's own.
  String? accent;

  /// The palettes the running edition offers, the look's own first. The
  /// edition hands them over as it opens ([StintController.new]); a host
  /// lists them.
  List<StintPalette> get palettes => _palettes;
  List<StintPalette> _palettes = const [];
  set palettes(List<StintPalette> value) {
    if (listEquals(value, _palettes)) return;
    _palettes = List.unmodifiable(value);
    notifyListeners();
  }

  /// The palette in effect: [accent] among [palettes], else the look's own
  /// (the first); null while no edition has handed its palettes over.
  StintPalette? get palette =>
      _palettes.where((p) => p.id == accent).firstOrNull ??
      _palettes.firstOrNull;

  /// [accent] when it is one of [ids], else the first of them: the preset a
  /// look's theme takes.
  String presetOf(List<String> ids) =>
      ids.contains(accent) ? accent! : ids.first;

  /// Whether the app speaks Arabic, right to left.
  bool get arabic => language == StintLanguage.ar;
  StintWords get words => StintWords(language);
  void update(void Function() apply) {
    apply();
    notifyListeners();
  }
}

class TaskFilters {
  TaskStatus status = TaskStatus.open;
  TaskSort sort = TaskSort.due;
  String project = '', assignee = '', search = '';
  int get count => [
    status != TaskStatus.all,
    project.isNotEmpty,
    assignee.isNotEmpty,
  ].where((v) => v).length;
  bool get active => count != 0 || search.trim().isNotEmpty;
  void reset() {
    status = TaskStatus.all;
    sort = TaskSort.due;
    project = '';
    assignee = '';
    search = '';
  }
}

class StintController extends ChangeNotifier {
  /// [palettes] are the edition's, the look's own first: they go to
  /// [settings] for a host's menu.
  StintController(
    this.repository, {
    StintLaunch launch = const StintLaunch(),
    List<StintPalette> palettes = const [],
  }) : settings = launch.settings ?? StintSettings(launch),
       _ownsSettings = launch.settings == null,
       place = launch.place,
       _initialDetail = launch.detail {
    settings.palettes = palettes;
  }

  final StintRepository repository;
  final StintSettings settings;
  final filters = TaskFilters();
  final _selected = <String>{};
  Set<String> get selected => Set.unmodifiable(_selected);
  bool selecting = false, signedIn = true;
  Place place;
  DataState state = DataState.loading;
  WorkspaceData data = (
    tasks: const [],
    entries: const [],
    timer: null,
    activity: const [],
  );
  DateTime week = mondayOf(studyToday);
  TaskDraft? draft;
  bool _initialDetail, _disposed = false;
  final bool _ownsSettings;
  int _request = 0;

  StintWords get words => settings.words;
  String projectName(String id) =>
      words.text(projects.firstWhere((p) => p.id == id).name);
  String personName(String id) =>
      words.text(team.firstWhere((p) => p.id == id).name);
  Future<void> refresh() async {
    final request = ++_request;
    state = DataState.loading;
    notifyListeners();
    try {
      final result = await repository.load();
      if (_disposed || request != _request) return;
      data = result;
      state = DataState.ready;
      if (_initialDetail && result.tasks.isNotEmpty) {
        _setDraft(result.tasks.first);
      }
      _initialDetail = false;
    } on StintLoadFailure {
      if (_disposed || request != _request) return;
      state = DataState.error;
    }
    notifyListeners();
  }

  List<Task> get openTasks =>
      data.tasks.where((t) => !t.done).toList()..sort(_dueOrder);

  List<Task> get todayTasks =>
      data.tasks.where((t) => calendarDay(t.due) == studyToday).toList()
        ..sort(_dueOrder);

  List<Task> get laterThisWeek {
    final tomorrow = addDays(studyToday, 1),
        nextMonday = addDays(mondayOf(studyToday), 7);
    return openTasks
        .where((t) => !t.due.isBefore(tomorrow) && t.due.isBefore(nextMonday))
        .toList();
  }

  List<TimeEntry> get todayBlocks =>
      entriesFor(mondayOf(studyToday))
          .where((entry) => entry.date == studyToday)
          .toList();

  Task? currentTask(String person) {
    final id = person == 'maya' ? data.timer?.taskId : teammateTimers[person];
    return data.tasks.where((t) => t.id == id && !t.done).firstOrNull;
  }

  void track(String taskId) {
    repository.track(taskId);
    _sync();
  }

  void stopTimer() {
    repository.stopTimer();
    _sync();
  }

  /// Only the visible clock and relative dates subscribe, at their own cadence.
  Stream<DateTime> ticks(Duration interval) =>
      Stream.periodic(interval, (_) => repository.now());

  int _dueOrder(Task a, Task b) {
    final order = a.due.compareTo(b.due);
    return order != 0 ? order : a.id.compareTo(b.id);
  }

  /// Whether the task list shows a row to open: the empty detail pane asks
  /// for a choice only then, not beside an empty, unmatched or failed list.
  bool get hasRowToOpen => state == DataState.ready && visible.isNotEmpty;

  List<Task> get visible {
    final f = filters, search = f.search.trim().toLowerCase();
    final tasks = data.tasks
        .where(
          (t) =>
              (f.status == TaskStatus.all ||
                  t.done == (f.status == TaskStatus.done)) &&
              (f.project.isEmpty || t.project == f.project) &&
              (f.assignee.isEmpty || t.assignee == f.assignee) &&
              (search.isEmpty ||
                  [
                    words.text(t.title),
                    t.id,
                    projectName(t.project),
                    personName(t.assignee),
                  ].any((text) => text.toLowerCase().contains(search))),
        )
        .toList();
    tasks.sort((a, b) {
      final order = switch (f.sort) {
        TaskSort.due => 0,
        TaskSort.priority => b.priority.index.compareTo(a.priority.index),
        TaskSort.title => words.text(a.title).compareTo(words.text(b.title)),
      };
      return order != 0 ? order : _dueOrder(a, b);
    });
    return tasks;
  }

  void filter(void Function(TaskFilters) change) {
    change(filters);
    notifyListeners();
  }

  void toggleSelection([String? id]) {
    if (id == null) {
      selecting = !selecting;
      _selected.clear();
    } else {
      selecting = true;
      if (!_selected.remove(id)) _selected.add(id);
    }
    notifyListeners();
  }

  void selectResults() {
    selecting = true;
    _selected.addAll(visible.map((t) => t.id));
    notifyListeners();
  }

  void navigate(Place value) {
    _setDraft(null);
    place = value;
    _selected.clear();
    selecting = false;
    notifyListeners();
  }

  void openTask(Task? task) {
    place = Place.tasks;
    _setDraft(task);
    notifyListeners();
  }

  void _setDraft(Task? task) {
    draft?.dispose();
    draft = task == null ? null : TaskDraft(task);
  }

  bool saveTask() {
    final d = draft;
    if (d == null || !d.validate(words)) return false;
    repository.put(d.task);
    _setDraft(d.task);
    _sync();
    return true;
  }

  void changeTasks(Iterable<String> ids, {bool? done, String? project}) {
    final changing = ids.toSet();
    for (final t in data.tasks.where((t) => changing.contains(t.id))) {
      final updated = t.copyWith(done: done, project: project);
      repository.put(updated);
      if (t.id == draft?.task.id) _setDraft(updated);
    }
    _selected.clear();
    selecting = false;
    _sync();
  }

  List<Task> deleteTasks(Iterable<String> ids) {
    final removed = repository.remove(ids.toList());
    if (removed.any((t) => t.id == draft?.task.id)) _setDraft(null);
    _selected.clear();
    selecting = false;
    _sync();
    return removed;
  }

  void undoDelete(List<Task> tasks) {
    repository.restore(tasks);
    _sync();
  }

  void _sync() {
    data = repository.snapshot;
    notifyListeners();
  }

  List<TimeEntry> entriesFor(DateTime first) =>
      data.entries
          .where(
            (e) =>
                !e.date.isBefore(first) && e.date.isBefore(addDays(first, 7)),
          )
          .toList()
        ..sort((a, b) {
          final day = b.date.compareTo(a.date);
          return day == 0 ? a.start.compareTo(b.start) : day;
        });
  List<int> dailyMinutes(DateTime first) {
    final daily = List.filled(7, 0);
    for (final e in entriesFor(first)) {
      daily[e.date.weekday - 1] += e.end - e.start;
    }
    return daily;
  }

  int totalMinutes(DateTime first) =>
      dailyMinutes(first).fold(0, (sum, day) => sum + day);
  void shiftWeek(int weeks) {
    week = addDays(week, weeks * 7);
    notifyListeners();
  }

  bool addEntry(EntryDraft d) {
    if (!d.validate(words)) return false;
    final note = d.note.trim();
    repository.log(
      date: d.date,
      start: d.start,
      end: d.end,
      project: d.project,
      note: TranslatedText.asEntered(note),
    );
    week = mondayOf(d.date);
    _sync();
    return true;
  }

  void signIn(bool value) {
    signedIn = value;
    navigate(Place.today);
  }

  @override
  void dispose() {
    _disposed = true;
    _setDraft(null);
    if (_ownsSettings) settings.dispose();
    super.dispose();
  }
}
