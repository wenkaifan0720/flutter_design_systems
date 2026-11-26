import 'fixtures.dart';
import 'models.dart';

typedef WorkspaceData = ({
  List<Task> tasks,
  List<TimeEntry> entries,
  RunningTimer? timer,
  List<StudioEvent> activity,
});

/// A single in-memory source of truth. Empty starts a writable, empty workspace.
/// A simulated failure consumes one request, so Retry exercises a real reload.
class StintRepository {
  StintRepository({
    this.latency = Duration.zero,
    bool empty = false,
    this.failNext = false,
    DateTime Function()? clock,
  }) : now = clock ?? studyClock(),
       _timer = empty ? null : seedTimer,
       _activity = empty ? [] : seedActivity(),
       _tasks = {
         if (!empty)
           for (final task in seedTasks()) task.id: task,
       },
       _entries = empty ? [] : seedEntries();

  Duration latency;
  bool failNext;
  final Map<String, Task> _tasks;
  final List<TimeEntry> _entries;
  final DateTime Function() now;
  RunningTimer? _timer;
  final List<StudioEvent> _activity;
  int _nextEntry = 1;

  WorkspaceData get snapshot => (
    tasks: List.unmodifiable(_tasks.values),
    entries: List.unmodifiable(_entries),
    timer: _timer,
    activity: List.unmodifiable(_activity),
  );

  Future<WorkspaceData> load() async {
    final fail = failNext;
    failNext = false;
    await Future<void>.delayed(latency);
    if (fail) throw const StintLoadFailure();
    return snapshot;
  }

  void put(Task task) {
    final finished = task.done && _tasks[task.id]?.done == false;
    _tasks[task.id] = task;
    if (finished) {
      final at = now();
      if (_timer?.taskId == task.id) _stop(at);
      _record(ActivityKind.finished, task.title, at);
    }
  }

  List<Task> remove(Iterable<String> ids) {
    final removed = <Task>[];
    for (final id in ids) {
      if (id == _timer?.taskId) stopTimer();
      final task = _tasks.remove(id);
      if (task != null) removed.add(task);
    }
    return removed;
  }

  /// Selecting another open task closes the previous session at the same instant.
  void track(String taskId) {
    final task = _tasks[taskId];
    if (task == null || task.done || _timer?.taskId == taskId) return;
    final at = now();
    _stop(at);
    _timer = (taskId: taskId, start: at);
    _record(ActivityKind.started, task.title, at);
  }

  void stopTimer() => _stop(now());

  void _stop(DateTime at) {
    final timer = _timer;
    if (timer == null) return;
    final task = _tasks[timer.taskId]!;
    _timer = null;
    // Timesheets use whole minutes. A session shorter than a minute gets
    // one minute; split at midnight so each day and week keeps its own work.
    var day = calendarDay(timer.start);
    var start = minuteOfDay(timer.start);
    final firstMinute = atMinute(day, start);
    final endMinute = atMinute(at, minuteOfDay(at));
    final finish = endMinute.isAfter(firstMinute)
        ? endMinute
        : firstMinute.add(const Duration(minutes: 1));
    var minutes = 0;
    do {
      final nextDay = addDays(day, 1);
      final end = finish.isBefore(nextDay) ? minuteOfDay(finish) : 1440;
      _appendBlock(day, start, end, task.project, task.title);
      minutes += end - start;
      day = nextDay;
      start = 0;
    } while (day.isBefore(finish));
    _record(ActivityKind.logged, task.title, at, minutes);
  }

  void _record(
    ActivityKind kind,
    TeamText subject,
    DateTime at, [
    int minutes = 0,
  ]) {
    _activity.insert(0, (
      person: 'maya',
      kind: kind,
      subject: subject,
      at: at,
      minutes: minutes,
    ));
    if (_activity.length > 8) _activity.removeLast();
  }

  void restore(Iterable<Task> tasks) {
    for (final task in tasks) {
      _tasks.putIfAbsent(task.id, () => task);
    }
  }

  void log({
    required DateTime date,
    required int start,
    required int end,
    required String project,
    required TeamText note,
  }) {
    _appendBlock(date, start, end, project, note);
    _record(ActivityKind.logged, note, now(), end - start);
  }

  void _appendBlock(
    DateTime date,
    int start,
    int end,
    String project,
    TeamText note,
  ) => _entries.add((
    id: 'new-${_nextEntry++}',
    date: calendarDay(date),
    start: start,
    end: end,
    project: project,
    note: note,
  ));
}

class StintLoadFailure implements Exception {
  const StintLoadFailure();
}
