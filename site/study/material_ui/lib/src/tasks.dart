part of '../stint_material.dart';

extension _Tasks on _Desk {
  Widget workspaceTasks(bool wide) {
    final draft = c.draft;
    final editor = draft == null
        ? Visibility(
            visible: c.hasRowToOpen,
            child: Center(child: Text(w.chooseTask)),
          )
        : _Editor(this, draft, key: ValueKey(draft.task.id));
    if (!wide) return draft == null ? taskList() : editor;
    return Row(
      children: [
        SizedBox(width: 355, child: taskList()),
        const VerticalDivider(width: 1),
        Expanded(
          child: draft == null
              ? editor
              : Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: editor,
                  ),
                ),
        ),
      ],
    );
  }

  Widget taskList() {
    final tasks = c.visible;
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SearchBar(
            controller: search,
            hintText: w.search,
            leading: const Icon(Icons.search),
            trailing: [
              if (search.text.isNotEmpty)
                IconButton(
                  tooltip: w.clear,
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    search.clear();
                    c.filter((f) => f.search = '');
                  },
                ),
            ],
            onChanged: (text) => c.filter((f) => f.search = text),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                onPressed: filters,
                icon: const Icon(Icons.tune),
                label: Text(w.filters),
              ),
              TextButton(
                onPressed: () => c.toggleSelection(),
                child: Text(c.selecting ? w.stopSelecting : w.select),
              ),
              IconButton(
                tooltip: w.refresh,
                onPressed: c.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (c.selecting)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(w.selected(c.selected.length)),
                TextButton(
                  onPressed: c.selectResults,
                  child: Text(w.selectAll),
                ),
                if (c.selected.isNotEmpty) menu(c.selected),
              ],
            ),
          if (tasks.isEmpty)
            ListTile(
              title: Text(c.data.tasks.isEmpty ? w.noTasks : w.noMatches),
              subtitle: Text(c.data.tasks.isEmpty ? w.allClear : w.searchHelp),
              trailing: c.filters.active && c.data.tasks.isNotEmpty
                  ? TextButton(
                      onPressed: () {
                        search.clear();
                        c.filter((f) => f.reset());
                      },
                      child: Text(w.reset),
                    )
                  : null,
            ),
          for (final task in tasks)
            // M3's selected row: the secondary container behind it, not a
            // tint on its words alone.
            ListTile(
              selectedTileColor: Theme.of(context)
                  .colorScheme
                  .secondaryContainer,
              selectedColor: Theme.of(context).colorScheme.onSecondaryContainer,
              selected: c.selecting
                  ? c.selected.contains(task.id)
                  : c.draft?.task.id == task.id,
              leading: c.selecting
                  ? Checkbox(
                      value: c.selected.contains(task.id),
                      onChanged: (_) => c.toggleSelection(task.id),
                    )
                  : null,
              title: Text(w.text(task.title)),
              subtitle: Text(
                '${c.projectName(task.project)}${w.dot}${w.shortDate(task.due)}',
              ),
              trailing: c.selecting ? null : menu({task.id}),
              onTap: () =>
                  c.selecting ? c.toggleSelection(task.id) : open(task),
            ),
        ],
      ),
    );
  }

  Future<void> filters() async {
    final f = c.filters;
    var status = f.status, order = f.sort;
    var project = f.project, assignee = f.assignee;
    final applied = await _raise<bool>(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading(w.filters),
                // The title stands clear of the first field (it sat 8 px
                // over Status's label, under the sheet's taller head).
                const SizedBox(height: 16),
                _Option(w.status, status, {
                  for (final v in TaskStatus.values) v: w.statusName(v),
                }, (v) => update(() => status = v)),
                _Option(w.project, project, {
                  '': w.all,
                  for (final p in projects) p.id: w.text(p.name),
                }, (v) => update(() => project = v)),
                _Option(w.assignee, assignee, {
                  '': w.all,
                  for (final p in team) p.id: w.text(p.name),
                }, (v) => update(() => assignee = v)),
                _Option(w.sort, order, {
                  for (final v in TaskSort.values) v: w.sortName(v),
                }, (v) => update(() => order = v)),
                // Its keys as Add entry's: at the end, with a Cancel to
                // leave by (the dialog has no other).
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => update(() {
                        status = TaskStatus.all;
                        project = '';
                        assignee = '';
                        order = TaskSort.due;
                      }),
                      child: Text(w.reset),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(w.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(w.apply),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted && applied == true) {
      c.filter((f) {
        f.status = status;
        f.project = project;
        f.assignee = assignee;
        f.sort = order;
      });
    }
  }

  Widget menu(Set<String> ids) {
    final done = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    return MenuAnchor(
      builder: (ctx, ctrl, _) => IconButton(
        tooltip:
            '${w.actions}${w.dot}${ids.length == 1 ? ids.first : w.number(ids.length)}',
        onPressed: ctrl.open,
        icon: const Icon(Icons.more_vert),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () => operate(ids, () => c.changeTasks(ids, done: !done)),
          child: Text(done ? w.reopen : w.complete),
        ),
        SubmenuButton(
          menuChildren: [
            for (final project in projects)
              MenuItemButton(
                onPressed: () =>
                    operate(ids, () => c.changeTasks(ids, project: project.id)),
                child: Text(w.text(project.name)),
              ),
          ],
          child: Text(w.move),
        ),
        MenuItemButton(
          onPressed: () => operate(ids, () {
            final deleted = c.deleteTasks(ids);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(w.deleted),
                action: SnackBarAction(
                  label: w.undo,
                  onPressed: () => c.undoDelete(deleted),
                ),
              ),
            );
          }),
          child: Text(w.delete),
        ),
      ],
    );
  }

  Future<void> operate(Set<String> ids, VoidCallback change) async {
    if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
    if (mounted) change();
  }
}

class _Editor extends StatelessWidget {
  const _Editor(this.desk, this.draft, {super.key});
  final _Desk desk;
  final TaskDraft draft;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: draft,
    builder: (context, _) {
      final c = desk.c,
          w = c.words,
          t = draft.task,
          errors = draft.submitted ? draft.errors(w) : const <String, String>{};
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(t.id, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: w.text(t.title),
            decoration: InputDecoration(
              labelText: w.title,
              errorText: errors['title'],
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => draft.title(v, w.language),
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: w.text(t.notes),
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: w.notes,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => draft.notes(v, w.language),
          ),
          // One rhythm down the form: 14 between fields (a select stands 7
          // inside its own room), so no floating label sits on the row above.
          const SizedBox(height: 7),
          _Option(w.project, t.project, {
            for (final p in projects) p.id: w.text(p.name),
          }, (v) => draft.edit(t.copyWith(project: v))),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Autocomplete<Person>(
              initialValue: TextEditingValue(text: c.personName(t.assignee)),
              displayStringForOption: (p) => w.text(p.name),
              // The field still holding the chosen name lists the whole team:
              // opened, it is a choice; only typed words narrow it.
              optionsBuilder: (q) => q.text == c.personName(t.assignee)
                  ? team
                  : team.where(
                      (p) => w
                          .text(p.name)
                          .toLowerCase()
                          .contains(q.text.toLowerCase()),
                    ),
              fieldViewBuilder: (ctx, ctl, focus, submit) => TextField(
                controller: ctl,
                focusNode: focus,
                // M3's editable exposed dropdown: the arrow Project's select
                // draws, so the two pickers read as one kind of field.
                decoration: InputDecoration(
                  labelText: w.assignee,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                onSubmitted: (_) => submit(),
              ),
              onSelected: (p) => draft.edit(t.copyWith(assignee: p.id)),
            ),
          ),
          ListTile(
            title: Text(w.due),
            subtitle: Text(w.shortDate(t.due)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final v = await showDatePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDate: t.due,
                // The study's day, not the machine's: the app runs on a
                // fixed morning, and the picker rings the day it calls today.
                currentDate: studyToday,
              );
              if (context.mounted && v != null) draft.setDue(v);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 7),
            child: TextFormField(
              initialValue: w.number(t.estimate),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩０-９]')),
              ],
              decoration: InputDecoration(
                labelText: w.estimate,
                errorText: errors['estimate'],
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) =>
                  draft.edit(t.copyWith(estimate: w.parseMinutes(v) ?? 0)),
            ),
          ),
          _Option(w.priority, t.priority, {
            for (final p in Priority.values) p: w.priorityName(p),
          }, (v) => draft.edit(t.copyWith(priority: v))),
          Text(w.labels),
          Wrap(
            spacing: 8,
            children: [
              for (final label in Label.values)
                FilterChip(
                  label: Text(w.labelName(label)),
                  selected: t.labels.contains(label),
                  onSelected: (_) => draft.toggle(label),
                ),
            ],
          ),
          CheckboxListTile(
            title: Text(w.done),
            value: t.done,
            onChanged: (v) => draft.edit(t.copyWith(done: v)),
          ),
          SwitchListTile(
            title: Text(w.reminder),
            value: t.reminder,
            onChanged: (v) => draft.edit(t.copyWith(reminder: v)),
          ),
          if (t.reminder)
            ListTile(
              title: Text(w.reminderTime),
              subtitle: Text(w.clock(t.reminderMinute)),
              onTap: () async {
                final v = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: t.reminderMinute ~/ 60,
                    minute: t.reminderMinute % 60,
                  ),
                );
                if (context.mounted && v != null) {
                  draft.edit(
                    t.copyWith(reminderMinute: v.hour * 60 + v.minute),
                  );
                }
              },
            ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: draft.dirty ? desk.save : null,
              icon: const Icon(Icons.check),
              label: Text(w.save),
            ),
          ),
        ],
      );
    },
  );
}
