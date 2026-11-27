/// Publish: a finished take's details (title, notes, show, cover, when,
/// and what listeners may do), then the upload, which can fail and be tried
/// again.
library;

import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

import 'data.dart';
import 'roomtone.dart';

enum _Stage { editing, uploading, failed, done }

/// The publish form for the take just finished.
class RoomtonePublishPage extends StatefulWidget {
  /// The form; with [failed], as its last upload left it.
  const RoomtonePublishPage({super.key, this.failed = false});

  /// Whether it opens on a failed upload.
  final bool failed;

  @override
  State<RoomtonePublishPage> createState() => _RoomtonePublishPageState();
}

class _RoomtonePublishPageState extends State<RoomtonePublishPage>
    with SingleTickerProviderStateMixin {
  late _Stage _stage = widget.failed ? _Stage.failed : _Stage.editing;
  final _title = TextEditingController(text: 'Night walk, harbour wall');
  final _notes = TextEditingController(
    text: 'Forty minutes along the harbour wall after the last ferry.',
  );
  String _show = roomtoneShows[1].id;
  bool _scheduled = false;
  DateTime? _day = DateTime(2026, 11, 19);
  StudioTime _time = const StudioTime(hour: 9, minute: 0);
  bool _explicit = false;
  bool _tell = true;
  bool _downloads = true;
  bool _coverChosen = true;
  String? _titleError;

  // The upload: the first try drops at 64%, as a train's connection does;
  // the next goes through.
  late final AnimationController _upload = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  late int _tries = widget.failed ? 1 : 0;

  @override
  void initState() {
    super.initState();
    if (widget.failed) _upload.value = 0.64;
  }

  @override
  void dispose() {
    _upload.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _titleError = 'Give the episode a title.');
      return;
    }
    setState(() {
      _titleError = null;
      _stage = _Stage.uploading;
    });
    _tries++;
    final fails = _tries == 1;
    _upload.value = 0;
    await _upload.animateTo(fails ? 0.64 : 1);
    if (!mounted) return;
    setState(() => _stage = fails ? _Stage.failed : _Stage.done);
    if (!fails) {
      showStudioToast(
        context,
        _scheduled
            ? 'Scheduled for ${_scheduleLabel(context)}'
            : 'Published to ${_showName()}',
      );
    }
  }

  String _scheduleLabel(BuildContext context) {
    final strings = MaterialLocalizations.of(context);
    final date = strings.formatFullDate(_day!);
    final time = strings.formatTimeOfDay(
      TimeOfDay(hour: _time.hour, minute: _time.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return '$date at $time';
  }

  String _showName() => roomtoneShows.firstWhere((s) => s.id == _show).name;

  @override
  Widget build(BuildContext context) => switch (_stage) {
    _Stage.editing => _form(context),
    _Stage.uploading => _uploading(context),
    _Stage.failed => _failed(context),
    _Stage.done => _done(context),
  };

  Widget _form(BuildContext context) {
    final theme = context.studioTheme;
    final first = DateTime(2026, 11, 16);
    return RoomtonePage(
      title: 'Publish',
      bottom: StudioButton.lit(
        _scheduled ? 'Schedule episode' : 'Publish now',
        icon: const Icon(LucideIcons.upload),
        onPressed: _publish,
      ),
      // On a desk the details stand beside when and to whom it goes out.
      maxWidth: roomtonePageWidth(context),
      children: roomtoneColumns(
        context,
        [
          const StudioSectionHeader('Details'),
          StudioTextField(
            controller: _title,
            labelText: 'Title',
            errorText: _titleError,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: StudioSpacing.regular),
          StudioTextField(
            controller: _notes,
            labelText: 'Show notes',
            helperText: 'Listeners read these under the player.',
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: StudioSpacing.regular),
          StudioSelect<String>(
            labelText: 'Show',
            value: _show,
            items: [
              for (final s in roomtoneShows)
                StudioSelectItem(value: s.id, label: s.name),
            ],
            onChanged: (v) => setState(() => _show = v),
          ),
          roomtoneGroupGap,
          StudioFileDrop(
            labelText: 'Cover',
            hintText: 'Square, at least 1400 px',
            multiple: false,
            files: _coverChosen
                ? const [StudioFile(name: 'harbour-wall.jpg', bytes: 820000)]
                : const [],
            onChoose: () => setState(() => _coverChosen = true),
            onRemove: (_) => setState(() => _coverChosen = false),
          ),
        ],
        [
          const StudioSectionHeader('Goes out'),
          StudioSegmentedButton<bool>(
            semanticLabel: 'Goes out',
            expand: true,
            segments: const [
              StudioSegment(value: false, label: 'Now'),
              StudioSegment(value: true, label: 'On a day'),
            ],
            value: _scheduled,
            onChanged: (v) => setState(() => _scheduled = v),
          ),
          if (_scheduled) ...[
            const SizedBox(height: StudioSpacing.regular),
            StudioDatePicker(
              labelText: 'Day',
              value: _day,
              firstDate: first,
              lastDate: DateTime(2027, 6, 30),
              currentDate: first,
              onChanged: (d) => setState(() => _day = d),
            ),
            const SizedBox(height: StudioSpacing.regular),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'At',
                    style: theme.textTheme.body.copyWith(
                      color: theme.colors.legend,
                    ),
                  ),
                ),
                StudioTimePicker(
                  value: _time,
                  semanticLabel: 'Goes out at',
                  onChanged: (t) => setState(() => _time = t),
                ),
              ],
            ),
          ],
          roomtoneGroupGap,
          StudioListGroup(
            header: 'Listeners',
            children: [
              StudioListTile.toggle(
                title: 'Tell followers',
                subtitle: 'A notification when it goes out',
                value: _tell,
                onChanged: (v) => setState(() => _tell = v),
              ),
              StudioListTile.toggle(
                title: 'Allow downloads',
                value: _downloads,
                onChanged: (v) => setState(() => _downloads = v),
              ),
              StudioListTile.toggle(
                title: 'Explicit',
                subtitle: 'Strong language',
                value: _explicit,
                onChanged: (v) => setState(() => _explicit = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _uploading(BuildContext context) => RoomtonePage(
    title: 'Publish',
    children: [
      _UploadRow(
        title: _title.text,
        show: _showName(),
        meter: AnimatedBuilder(
          animation: _upload,
          builder: (context, _) => StudioProgressBar(
            value: _upload.value,
            semanticLabel: 'Uploading',
          ),
        ),
      ),
    ],
  );

  Widget _failed(BuildContext context) => RoomtonePage(
    title: 'Publish',
    maxWidth: roomtonePageWidth(context),
    children: roomtoneColumns(
      context,
      [
        _UploadRow(
          title: _title.text,
          show: _showName(),
          // Where it stopped, unlit: the meter no longer runs.
          meter: StudioProgressBar(
            value: _upload.value,
            color: context.studioTheme.colors.danger.withValues(alpha: 0.4),
            semanticLabel: 'Uploaded',
          ),
        ),
      ],
      [
        StudioStatusView.error(
          title: 'Upload failed',
          message:
              'The connection dropped at 64%. The episode is kept on this '
              'device; nothing went out.',
          actionLabel: 'Try again',
          onAction: _publish,
        ),
        const SizedBox(height: StudioSpacing.regular),
        Center(
          child: StudioButton.text(
            'Edit the details',
            onPressed: () => setState(() => _stage = _Stage.editing),
          ),
        ),
      ],
    ),
  );

  Widget _done(BuildContext context) => RoomtonePage(
    title: 'Publish',
    children: [
      _UploadRow(
        title: _title.text,
        show: _showName(),
        status: _scheduled ? 'Scheduled' : 'On air',
      ),
      roomtoneGroupGap,
      StudioStatusView(
        icon: Icon(
          _scheduled ? LucideIcons.calendarClock : LucideIcons.radioTower,
        ),
        title: _scheduled ? 'Scheduled' : 'On air',
        message: _scheduled
            ? 'It goes out on ${_scheduleLabel(context)}.'
            : 'Followers of ${_showName()} hear about it now.',
        actionLabel: 'Back to the recorder',
        onAction: () => Navigator.of(context).maybePop(),
      ),
    ],
  );
}

// The episode going up: its title and show beside a tag saying where it is.
// The episode going up, on glass: its row, and the meter of how far it has
// gone under it in the same pane.
class _UploadRow extends StatelessWidget {
  const _UploadRow({
    required this.title,
    required this.show,
    this.status = 'Not out',
    this.meter,
  });

  final String title;
  final String show;
  final String status;
  final Widget? meter;

  @override
  Widget build(BuildContext context) {
    final row = StudioListTile(
      leading: const Icon(LucideIcons.fileAudio),
      title: title,
      subtitle: show,
      trailing: StudioTag(
        status,
        tone: status == 'On air' ? StudioTagTone.lit : StudioTagTone.plain,
      ),
    );
    if (meter == null) return StudioListGroup(children: [row]);
    return StudioDisplay(
      padding: const EdgeInsets.all(StudioMetrics.recessInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row,
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StudioSpacing.regular - StudioMetrics.recessInset,
              StudioSpacing.tight,
              StudioSpacing.regular - StudioMetrics.recessInset,
              StudioSpacing.medium - StudioMetrics.recessInset,
            ),
            child: meter,
          ),
        ],
      ),
    );
  }
}
