import 'package:flutter/foundation.dart';

import 'fixtures.dart';
import 'models.dart';
import 'words.dart';

/// A draft lives outside the detail route, so resizing keeps in-progress edits.
class TaskDraft extends ChangeNotifier {
  TaskDraft(this.original) : task = original;
  final Task original;
  Task task;
  bool submitted = false;

  bool dueIncomplete = false;
  void setDue(DateTime? date) {
    dueIncomplete = date == null;
    edit(task.copyWith(due: date == null ? null : calendarDay(date)));
  }

  bool get dirty =>
      dueIncomplete ||
      task.title != original.title ||
      task.notes != original.notes ||
      task.project != original.project ||
      task.assignee != original.assignee ||
      task.due != original.due ||
      task.estimate != original.estimate ||
      task.priority != original.priority ||
      !setEquals(task.labels, original.labels) ||
      task.done != original.done ||
      task.reminder != original.reminder ||
      task.reminderMinute != original.reminderMinute;
  void edit(Task value) {
    task = value;
    notifyListeners();
  }

  void title(String value, StintLanguage language) =>
      edit(task.copyWith(title: original.title.edit(value, language)));
  void notes(String value, StintLanguage language) =>
      edit(task.copyWith(notes: original.notes.edit(value, language)));
  void toggle(Label label) {
    final labels = {...task.labels};
    if (!labels.remove(label)) labels.add(label);
    edit(task.copyWith(labels: labels));
  }

  Map<String, String> errors(StintWords w) => {
    if (dueIncomplete) 'due': w.dateError,
    if (w.text(task.title).trim().isEmpty) 'title': w.titleError,
    if (!projects.any((p) => p.id == task.project)) 'project': w.projectError,
    if (!team.any((p) => p.id == task.assignee)) 'assignee': w.assigneeError,
    if (task.estimate < 5 || task.estimate > 480) 'estimate': w.estimateError,
  };
  bool validate(StintWords w) {
    submitted = true;
    notifyListeners();
    return errors(w).isEmpty;
  }
}

class EntryDraft extends ChangeNotifier {
  EntryDraft(this.date);
  DateTime date;
  int start = 540, end = 600;
  String project = projects.first.id, note = '';
  bool submitted = false;
  void update(void Function() change) {
    change();
    notifyListeners();
  }

  Map<String, String> errors(StintWords w) => {
    if (start < 0 || end >= 1440 || end <= start) 'end': w.entryError,
    if (!projects.any((p) => p.id == project)) 'project': w.projectError,
    if (note.trim().isEmpty) 'note': w.noteError,
  };
  bool validate(StintWords w) {
    submitted = true;
    notifyListeners();
    return errors(w).isEmpty;
  }
}
