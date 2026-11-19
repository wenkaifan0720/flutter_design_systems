// The application: the start page, the task list of what it takes, one
// question per page, the reader's details with the error summary, the
// answers checked, the confirmation.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'permits.dart';

/// The service's start page: what it is for, what it takes, Start now. In
/// an app Start now stays in reach at the page's foot; on the site it
/// follows what the service is for.
class PermitsStartPage extends StatelessWidget {
  /// The start page.
  const PermitsStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.permits;
    final app = CivicLayout.isApp(MediaQuery.sizeOf(context).width);
    final go = CivicButton.start(
      onPressed: () => state.go(PermitsPage.tasks),
      child: Text(context.say('Start now')),
    );
    return CivicPageBody(
      title: context.say('Apply for a resident parking permit'),
      action: app ? go : null,
      children: [
        Text(
          context.say(
            'Use this service to apply for a permit to park on your street in a Brindlemere permit zone.',
          ),
        ),
        const SizedBox(height: CivicSpacing.s8),
        // A visitor's vehicle parks on another permit: the start page says
        // who counts as one, beside the question.
        CivicPopover(
          title: context.say('Who counts as a visitor'),
          content: Text(
            context.say(
              'Anyone staying less than 14 days who does not live at your address. Their vehicle parks with a visitor permit, not this one.',
            ),
          ),
          builder: (context, anchor) => CivicLink(
            onPressed: anchor.toggle,
            child: Text(context.say('Who counts as a visitor?')),
          ),
        ),
        const SizedBox(height: CivicSpacing.s24),
        CivicListGroup(
          children: [
            CivicListRow(
              leading: const Icon(LucideIcons.clock),
              title: Text(context.say('Takes around 10 minutes')),
            ),
            CivicListRow(
              leading: const Icon(LucideIcons.wallet),
              title: Text(context.say('€60 a year')),
              subtitle: Text(context.say('A motorcycle permit costs €30.')),
            ),
          ],
        ),
        if (!app) ...[
          const SizedBox(height: CivicSpacing.s32),
          Align(alignment: AlignmentDirectional.centerStart, child: go),
        ],
        const SizedBox(height: CivicSpacing.s40),
        CivicListGroup(
          title: context.say('You will need'),
          children: [
            CivicListRow(
              leading: const Icon(LucideIcons.house),
              title: Text(context.say('Your address and date of birth')),
            ),
            CivicListRow(
              leading: const Icon(LucideIcons.fileText),
              title: Text(context.say('Proof of your address')),
              subtitle: Text(context.say('Such as a tenancy agreement')),
            ),
          ],
        ),
        const SizedBox(height: CivicSpacing.s40),
        CivicListGroup(
          title: context.say('Not sure of your zone?'),
          children: [
            CivicListRow(
              leading: const Icon(LucideIcons.mapPin),
              title: Text(context.say('Find your permit zone')),
              onTap: () => state.go(PermitsPage.zones),
            ),
          ],
        ),
      ],
    );
  }
}

/// One item of a bulleted list: the bullet hangs, and a second line starts
/// under the first line's words.
class PermitsBullet extends StatelessWidget {
  /// An item.
  const PermitsBullet({super.key, required this.text});

  /// The item's words.
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: CivicSpacing.s8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExcludeSemantics(child: Text('•  ')),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// What a task stands at.
enum _Task { done, started, todo, blocked }

/// The application's task list: its sections, each task a row to its page
/// with where it stands at the end: Completed in words, an unfinished task
/// on a tag so it stands out, and Cannot start yet, greyed and not a link,
/// until what it needs is done.
class PermitsTasksPage extends StatelessWidget {
  /// The task list.
  const PermitsTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.permits;
    final t = context.civicTheme;
    final text = context.civicText;
    final details = [
      state.name,
      state.line1,
      state.town,
      state.postcode,
      state.day,
      state.month,
      state.year,
    ];
    final detailsDone =
        details.every((c) => c.text.trim().isNotEmpty) && state.proof != null;
    final detailsStarted =
        details.any((c) => c.text.trim().isNotEmpty) || state.proof != null;
    final vehicle = state.vehicle == null ? _Task.todo : _Task.done;
    final yours = detailsDone
        ? _Task.done
        : detailsStarted
        ? _Task.started
        : _Task.todo;
    final send = vehicle == _Task.done && yours == _Task.done
        ? _Task.todo
        : _Task.blocked;
    final done = [vehicle, yours, send].where((s) => s == _Task.done).length;
    Widget status(_Task task) => switch (task) {
      _Task.done => Text(context.say('Completed'), style: text.body),
      _Task.started => CivicTag(
        label: context.say('In progress'),
        tone: CivicTone.info,
      ),
      _Task.todo => CivicTag(
        label: context.say('Not yet started'),
        tone: CivicTone.info,
      ),
      _Task.blocked => Text(
        context.say('Cannot start yet'),
        style: text.body.copyWith(color: t.textSecondary),
      ),
    };
    Widget task(String title, String hint, _Task stands, PermitsPage to) =>
        CivicListRow(
          title: Text(context.say(title)),
          subtitle: Text(context.say(hint)),
          trailing: status(stands),
          onTap: stands == _Task.blocked ? null : () => state.go(to),
        );
    return CivicPageBody(
      backLink: context.backLinkTo(PermitsPage.start),
      title: context.say('Your permit application'),
      children: [
        Text(
          context
              .say('You have completed 1 of 3 tasks.')
              .replaceAll('1', '$done'),
        ),
        const SizedBox(height: CivicSpacing.s32),
        // Each part's tasks on a card under its name, a row each.
        CivicListGroup(
          title: context.say('1. Prepare your application'),
          children: [
            task(
              'Vehicle',
              'What kind of vehicle the permit is for',
              vehicle,
              PermitsPage.vehicle,
            ),
            task(
              'Your details',
              'Your name, address and proof of address',
              yours,
              PermitsPage.details,
            ),
          ],
        ),
        const SizedBox(height: CivicSpacing.s32),
        CivicListGroup(
          title: context.say('2. Apply'),
          children: [
            task(
              'Check and send',
              'Check your answers, then send them to us',
              send,
              PermitsPage.check,
            ),
          ],
        ),
      ],
    );
  }
}

/// The first question: what kind of vehicle, as the page's heading.
class PermitsVehiclePage extends StatefulWidget {
  /// The question page.
  const PermitsVehiclePage({super.key});

  @override
  State<PermitsVehiclePage> createState() => _PermitsVehiclePageState();
}

class _PermitsVehiclePageState extends State<PermitsVehiclePage> {
  bool _sent = false;
  final FocusNode _first = FocusNode();

  @override
  void dispose() {
    _first.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.permits;
    final error = _sent && state.vehicle == null
        ? context.say('Select the kind of vehicle the permit is for')
        : null;
    return CivicPageBody(
      backLink: context.backLinkTo(PermitsPage.tasks),
      errorSummary: error == null
          ? null
          : CivicErrorSummary(
              title: context.say('There is a problem'),
              errors: [
                CivicErrorSummaryItem(
                  text: error,
                  onPressed: _first.requestFocus,
                  url: Uri(fragment: 'vehicle'),
                ),
              ],
            ),
      caption: context.say('Step 1 of 3'),
      action: CivicButton(
        onPressed: () {
          if (state.vehicle == null) {
            setState(() => _sent = true);
          } else {
            state.next(PermitsPage.details);
          }
        },
        child: Text(context.say('Continue')),
      ),
      children: [
        CivicRadioGroup<String>(
          labelText: context.say('What kind of vehicle is the permit for?'),
          helperText: context.say('You can apply for one permit at a time.'),
          isPageHeading: true,
          errorText: error,
          groupValue: state.vehicle,
          onChanged: (v) {
            state.vehicle = v;
            state.changed();
          },
          children: [
            CivicRadio(
              value: 'car',
              labelText: context.say('Car or van'),
              focusNode: _first,
            ),
            CivicRadio(
              value: 'motorcycle',
              labelText: context.say('Motorcycle'),
              helperText: context.say('Includes mopeds and scooters.'),
            ),
            CivicRadio(
              value: 'motorhome',
              labelText: context.say('Motorhome or campervan'),
              helperText: context.say('Up to 3.5 tonnes.'),
            ),
          ],
        ),
      ],
    );
  }
}

/// What a vehicle answer says.
String permitsVehicleLabel(BuildContext context, String? vehicle) =>
    context.say(switch (vehicle) {
      'motorcycle' => 'Motorcycle',
      'motorhome' => 'Motorhome or campervan',
      _ => 'Car or van',
    });

/// The reader's details: name, address, date of birth and proof of
/// address, with the error summary when it was sent with problems.
class PermitsDetailsPage extends StatefulWidget {
  /// The details page.
  const PermitsDetailsPage({super.key});

  @override
  State<PermitsDetailsPage> createState() => _PermitsDetailsPageState();
}

class _PermitsDetailsPageState extends State<PermitsDetailsPage> {
  final _name = FocusNode();
  final _line1 = FocusNode();
  final _town = FocusNode();
  final _postcode = FocusNode();
  final _day = FocusNode();
  final _month = FocusNode();
  final _year = FocusNode();
  final _proof = FocusNode();

  @override
  void dispose() {
    for (final n in [
      _name,
      _line1,
      _town,
      _postcode,
      _day,
      _month,
      _year,
      _proof,
    ]) {
      n.dispose();
    }
    super.dispose();
  }

  /// The problems, in the order the fields stand: (field, words, focus).
  List<(String, String, FocusNode)> _problems(PermitsState s) {
    final out = <(String, String, FocusNode)>[];
    if (s.name.text.trim().isEmpty) {
      out.add(('name', 'Enter your full name', _name));
    }
    if (s.line1.text.trim().isEmpty) {
      out.add(('line1', 'Enter the first line of your address', _line1));
    }
    if (s.town.text.trim().isEmpty) {
      out.add(('town', 'Enter your town or city', _town));
    }
    if (s.postcode.text.trim().isEmpty) {
      out.add(('postcode', 'Enter a postcode', _postcode));
    }
    final d = int.tryParse(s.day.text);
    final m = int.tryParse(s.month.text);
    final y = int.tryParse(s.year.text);
    if (d == null && m == null && y == null) {
      out.add(('dob', 'Enter your date of birth', _day));
    } else if (d == null ||
        m == null ||
        y == null ||
        d < 1 ||
        d > 31 ||
        m < 1 ||
        m > 12 ||
        y < 1900) {
      out.add((
        'dob',
        'Date of birth must be a real date',
        d == null || d < 1 || d > 31
            ? _day
            : m == null || m < 1 || m > 12
            ? _month
            : _year,
      ));
    }
    if (s.proof == null) {
      out.add(('proof', 'Choose a file that proves your address', _proof));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.permits;
    final problems = state.showErrors
        ? _problems(state)
        : const <(String, String, FocusNode)>[];
    String? errorOf(String field) {
      for (final (f, words, _) in problems) {
        if (f == field) return context.say(words);
      }
      return null;
    }

    final dobError = errorOf('dob');
    final dobParts = <CivicDatePart>{
      if (dobError != null) ...{
        if (int.tryParse(state.day.text) case final d
            when d == null || d < 1 || d > 31)
          CivicDatePart.day,
        if (int.tryParse(state.month.text) case final m
            when m == null || m < 1 || m > 12)
          CivicDatePart.month,
        if (int.tryParse(state.year.text) case final y
            when y == null || y < 1900)
          CivicDatePart.year,
      },
    };
    return CivicPageBody(
      backLink: context.backLinkTo(PermitsPage.vehicle),
      errorSummary: problems.isEmpty
          ? null
          : CivicErrorSummary(
              title: context.say('There is a problem'),
              errors: [
                for (final (field, words, node) in problems)
                  CivicErrorSummaryItem(
                    text: context.say(words),
                    onPressed: node.requestFocus,
                    url: Uri(fragment: field),
                  ),
              ],
            ),
      caption: context.say('Step 2 of 3'),
      title: context.say('Your details'),
      // Kept in reach at an app's foot while the questions scroll.
      action: CivicButton(
        onPressed: () {
          if (_problems(state).isEmpty) {
            state.showErrors = false;
            state.next(PermitsPage.check);
          } else {
            state.showErrors = true;
            state.changed();
          }
        },
        child: Text(context.say('Continue')),
      ),
      // Each question at one size: the name (one field, so its label is
      // the question), the address, the date of birth and the proof.
      children: [
        CivicTextField(
          labelText: context.say('What is your full name?'),
          isQuestion: true,
          controller: state.name,
          focusNode: _name,
          errorText: errorOf('name'),
          autofillHints: const [AutofillHints.name],
          textInputAction: TextInputAction.next,
          onChanged: (_) => state.changed(),
        ),
        const SizedBox(height: CivicSpacing.s32),
        CivicFieldset(
          labelText: context.say('What is your address?'),
          children: [
            CivicTextField(
              labelText: context.say('Address line 1'),
              controller: state.line1,
              focusNode: _line1,
              errorText: errorOf('line1'),
              autofillHints: const [AutofillHints.streetAddressLine1],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: CivicSpacing.s16),
            CivicTextField(
              labelText: context.say('Town or city'),
              controller: state.town,
              focusNode: _town,
              errorText: errorOf('town'),
              autofillHints: const [AutofillHints.addressCity],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: CivicSpacing.s16),
            CivicTextField(
              labelText: context.say('Postcode'),
              controller: state.postcode,
              focusNode: _postcode,
              errorText: errorOf('postcode'),
              widthInCharacters: 10,
              autofillHints: const [AutofillHints.postalCode],
              textInputAction: TextInputAction.next,
            ),
          ],
        ),
        const SizedBox(height: CivicSpacing.s32),
        CivicDateInput(
          labelText: context.say('What is your date of birth?'),
          helperText: context.say('For example, 27 3 1987'),
          errorText: dobError,
          errorParts: dobParts,
          dayLabel: context.say('Day'),
          monthLabel: context.say('Month'),
          yearLabel: context.say('Year'),
          dayController: state.day,
          monthController: state.month,
          yearController: state.year,
          dayFocusNode: _day,
          monthFocusNode: _month,
          yearFocusNode: _year,
        ),
        const SizedBox(height: CivicSpacing.s32),
        CivicFieldset(
          labelText: context.say('Upload proof of your address'),
          helperText: context.say(
            'A council tax bill or a tenancy agreement, as a PDF or a photo.',
          ),
          // The question says what is wrong; the upload takes the edge.
          errorText: errorOf('proof'),
          children: [
            CivicFileUpload(
              isError: errorOf('proof') != null,
              chooseLabel: context.say(
                state.proof == null ? 'Choose file' : 'Choose another file',
              ),
              emptyLabel: context.say('No file chosen'),
              removeLabel: context.say('Remove'),
              fileName: state.proof,
              focusNode: _proof,
              onChoose: () {
                state.proof = 'tenancy-agreement.pdf';
                state.changed();
              },
              onRemoved: () {
                state.proof = null;
                state.changed();
              },
            ),
          ],
        ),
      ],
    );
  }
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// The answers, checked before sending, each with the way back to it.
class PermitsCheckPage extends StatelessWidget {
  /// The check page.
  const PermitsCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.permits;
    final change = context.say('Change');
    CivicSummaryRow row(String label, String value, PermitsPage page) {
      final said = context.say(label);
      return CivicSummaryRow(
        label: said,
        value: Text(permitsAsTyped(value)),
        actionLabel: change,
        actionSemanticLabel: '$change $said',
        onActionPressed: () => state.go(page),
        // The question's own address, as the app's URLs name its pages.
        actionUrl: Uri.parse('/${page.name}'),
      );
    }

    final month = int.tryParse(state.month.text);
    final dob = [
      state.day.text,
      if (month != null && month >= 1 && month <= 12)
        context.say(_months[month - 1])
      else
        state.month.text,
      state.year.text,
    ].join(' ');
    return CivicPageBody(
      backLink: context.backLinkTo(PermitsPage.details),
      caption: context.say('Step 3 of 3'),
      title: context.say('Check your answers before sending your application'),
      children: [
        CivicSummaryList(
          rows: [
            row(
              'Vehicle',
              permitsVehicleLabel(context, state.vehicle),
              PermitsPage.vehicle,
            ),
            row('Name', state.name.text, PermitsPage.details),
            row(
              'Address',
              [
                state.line1.text,
                state.town.text,
                state.postcode.text,
              ].where((l) => l.isNotEmpty).join('\n'),
              PermitsPage.details,
            ),
            row('Date of birth', dob, PermitsPage.details),
            row('Proof of address', state.proof ?? '', PermitsPage.details),
          ],
        ),
        const SizedBox(height: CivicSpacing.s48),
        CivicSectionHeader(title: context.say('Now send your application')),
        Text(
          context.say(
            'By sending this application you confirm that, to the best of your knowledge, the details you are providing are correct.',
          ),
        ),
        const SizedBox(height: CivicSpacing.s32),
        CivicButton(
          onPressed: () => state.go(PermitsPage.sent),
          child: Text(context.say('Accept and send')),
        ),
      ],
    );
  }
}

/// The confirmation: the panel with the reference, what happens next.
class PermitsSentPage extends StatelessWidget {
  /// The confirmation page.
  const PermitsSentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.permits;
    final text = context.civicText;
    return CivicPageBody(
      children: [
        CivicConfirmationPanel(
          title: context.say('Application sent'),
          child: Column(
            children: [
              Text(context.say('Your reference number')),
              const SizedBox(height: CivicSpacing.s8),
              // A reference reads left to right in either direction, on
              // one line: it scales down before it would break.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  permitsReference(
                    context,
                    'BRM-4821-K',
                    style: TextStyle(
                      fontSize: text.headingL.fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CivicSpacing.s32),
        Text(context.say('We have sent you a confirmation email.')),
        const SizedBox(height: CivicSpacing.s32),
        CivicSectionHeader(title: context.say('What happens next')),
        Text(
          context.say(
            'We will check your proof of address and decide within 5 working days. We will email you when we have decided.',
          ),
        ),
        const SizedBox(height: CivicSpacing.s24),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: CivicLink(
            onPressed: () => state.go(PermitsPage.applications),
            child: Text(context.say('View your applications')),
          ),
        ),
        const SizedBox(height: CivicSpacing.s48),
        const _Feedback(),
      ],
    );
  }
}

/// How it went, asked once the application is sent: a score said in words,
/// and thanks once it is given.
class _Feedback extends StatefulWidget {
  const _Feedback();

  @override
  State<_Feedback> createState() => _FeedbackState();
}

class _FeedbackState extends State<_Feedback> {
  double _ease = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CivicSectionHeader(
        title: context.say('What did you think of this service?'),
      ),
      CivicRating(
        labelText: context.say('How easy was it to apply?'),
        value: _ease,
        labels: [
          for (final words in const [
            'Very hard',
            'Hard',
            'Neither easy nor hard',
            'Easy',
            'Very easy',
          ])
            context.say(words),
        ],
        onChanged: (v) => setState(() => _ease = v),
      ),
      if (_ease > 0) ...[
        const SizedBox(height: CivicSpacing.s16),
        Semantics(
          liveRegion: true,
          child: Text(
            context.say('Thank you. Your answer helps us improve the service.'),
          ),
        ),
      ],
    ],
  );
}
