// Every doc example in civic_ui's lib, compiled and run (ui_core's template,
// doc_examples.dart beside it). Each fenced dart block and `Example:` line is
// written out below as the body of an entry, so an example that stops
// compiling fails analysis; the first test fails when lib has an example
// this file lacks; the rest build each widget example (push each route, run
// each call) in a bare app on CivicHost.
//
// An example names what its caller has (an index and its setState, a
// controller, a callback): _Caller holds them, as a page's state would, and
// what it makes is disposed once its tree is gone. Routes' examples stand a
// navigator or an app of their own, so routes.dart is left out.
import 'dart:io';

import 'package:civic_ui/civic_parts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'doc_examples.dart';

/// civic_parts.dart's example: what an app's own copy of a part imports
/// (this file imports the same library).
// Indented, so the exporter's import pass leaves the lines alone (an import
// at a line's start is taken for one of this file's own).
const _partsImports = '''
  // lib/ui/my_card.dart, copied from package:civic_ui/src/civic/... and renamed.
  import 'package:flutter/widgets.dart';
  import 'package:civic_ui/civic_parts.dart';
''';

/// What the caller made for an example, disposed once its tree is gone.
final List<VoidCallback> _disposers = [];

T _own<T extends ChangeNotifier>(T value) {
  _disposers.add(value.dispose);
  return value;
}

/// An app's router, as `routerConfig` takes it and `router.go` calls it.
class _Router extends RouterConfig<Object> {
  _Router() : super(routerDelegate: _Pages());

  void go(String location) {}
}

/// A router delegate showing one page, with nothing to listen to.
class _Pages extends RouterDelegate<Object> {
  @override
  Widget build(BuildContext context) => const PermitPage();

  @override
  Future<bool> popRoute() async => false;

  @override
  Future<void> setNewRoutePath(Object configuration) async {}

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// A page of the caller's app.
class PermitPage extends StatelessWidget {
  /// The page.
  const PermitPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Your permit');
}

/// The caller's own question page.
class ApplyPage extends StatelessWidget {
  /// The page.
  const ApplyPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Apply for a permit');
}

/// The caller's app.
class MyApp extends StatelessWidget {
  /// The app.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const ApplyPage();
}

/// A permit, as the caller's data holds it.
class Permit {
  /// A permit.
  const Permit(this.registration, this.ends);

  /// Its vehicle's registration.
  final String registration;

  /// When it ends, in words.
  final String ends;
}

/// What a caller's provider gives: loading, failed or the data.
class _Loaded<T> {
  const _Loaded(this.value);

  final T value;

  Widget when({
    required Widget Function() loading,
    required Widget Function(Object error, StackTrace? stack) error,
    required Widget Function(T value) data,
  }) => data(value);
}

/// The file the caller's picker chose.
class _Picked {
  const _Picked(this.name);

  final String name;
}

/// What a page of the caller's app has to hand when it uses a part: its
/// state, its callbacks, its controllers.
class _Caller {
  int index = 0;
  final pages = const [Text('Home'), Text('Applications')];
  String? emailError = 'Enter an email address';
  String email = '';
  final data = const _Loaded([Permit('CU57 ABC', '3 November 2026')]);
  bool textMessages = false;
  final streets = const ['Mill Lane', 'Northgate', 'Old Town Road'];
  String? street;
  late final day = _own(TextEditingController());
  late final month = _own(TextEditingController());
  late final year = _own(TextEditingController());
  final errors = const ['Enter your full name'];
  late final nameFocus = _own(FocusNode());
  _Picked? proof = const _Picked('council-tax-bill.pdf');
  final destinations = const [
    CivicNavigationDestination(icon: LucideIcons.house, label: 'Home'),
    CivicNavigationDestination(
      icon: LucideIcons.fileText,
      label: 'Applications',
    ),
  ];
  int page = 0;
  String? passwordError;
  String password = '';
  String? vehicle;
  final rows = const [Text('Resident permit, Zone B')];
  final question = const Text('What is your vehicle registration number?');
  final continueButton = CivicButton(
    onPressed: () {},
    child: const Text('Continue'),
  );
  String query = '';
  String? zone = 'a';
  bool largerText = false;
  late final permits = _own(
    RawDataTableController<Map<String, String>>(
      rows: const [
        {'vehicle': 'CU57 ABC', 'ends': '3 November 2026'},
      ],
      columns: [
        const RawDataColumn(id: 'vehicle', label: 'Vehicle'),
        const RawDataColumn(id: 'ends', label: 'Ends'),
      ],
    ),
  );
  int tab = 0;
  String? postcodeError;
  String postcode = '';
  bool pressed = false;
  bool focused = false;
  bool night = false;
  Set<String> shown = {'drafts'};
  String? period = 'week';
  late final reason = _own(TextEditingController());
  double? days = 1;
  bool openNow = false;
  double score = 0;
  double size = 100;
  RawRangeValues cost = const RawRangeValues(20, 60);
  DateTime? start;
  RawDateRange? stay;
  RawTimeOfDay? arrival;
  late final dates = _own(
    RawCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
    ),
  );
  DateTime? chosen;
  List<int> slot = [9, 2];
  late final badge = _own(RawColorController(const Color(0xFF0F4C81)));
  final languages = const ['English', 'Welsh', 'Polish', 'Urdu'];
  List<String> spoken = ['English'];
  final router = _Router();
  late final terms = _own(ScrollController());
  final documents = ['Proof of address', 'Vehicle logbook'];
  late final services = _own(
    DesignTreeController<String>(
      roots: const ['Parking', 'Bins'],
      childrenOf: (s) => s == 'Parking' ? const ['Permits'] : const [],
    ),
  );

  void setState(VoidCallback change) => change();
  void retry() {}
  void goHome() {}
  void goBack() {}
  void save() {}
  void later() {}
  void apply() {}
  void pickProof() {}
  void openApplication(String reference) {}
  void openAll() {}
  void remove() {}
  void openAccount() {}
  void confirm(String code) {}
  void openService(String service) {}

  final picked = <String>['BR21 KLM', 'BR19 XTP'];

  void renew() {}

  Future<void> fetchApplications() async {}

  Map<String, DocExample> get examples => {
    // app/frame.dart
    'CivicNavItem': (context) {
      const item = CivicNavItem(
        LucideIcons.fileText,
        'Applications',
        ValueKey('applications'),
      );
      return CivicShellFrame(
        destinations: const [CivicNavItem(LucideIcons.house, 'Home'), item],
        selectedIndex: 1,
        onDestinationSelected: (_) {},
        child: const CivicScreen(body: Text('Applications')),
      );
    },
    'CivicShellAction': (context) => CivicShellFrame(
      destinations: const [CivicNavItem(LucideIcons.house, 'Home')],
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      action: CivicShellAction(
        icon: LucideIcons.plus,
        label: 'Apply for a permit',
        onPressed: (context) => Navigator.of(context).pushNamed('/apply'),
      ),
      child: const CivicScreen(body: Text('Home')),
    ),
    'CivicShellFrame': (context) => CivicShellFrame(
      destinations: const [
        CivicNavItem(LucideIcons.house, 'Home'),
        CivicNavItem(LucideIcons.fileText, 'Applications'),
      ],
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      child: pages[index],
    ),
    // app/host.dart
    'CivicHost': (context) => MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => CivicHost(child: child!),
    ),
    // app/input.dart
    'CivicInput': (context) => CivicInput(
      labelText: 'Email address',
      errorText: emailError,
      onChanged: (value) => email = value,
    ),
    // app/preview.dart
    'CivicPreview': (context) => const CivicPreview(
      presentation: CivicPresentation.pushed,
      child: PermitPage(),
    ),
    // app/screen.dart
    'CivicScreen': (context) => CivicScreen(
      topBar: CivicTopBar(
        title: 'Your permit',
        leading: CivicTopBar.autoLeading(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Text('Your permit', style: context.civicText.headingXL)],
      ),
    ),
    // app/states.dart
    'CivicLoadingState': (context) => data.when(
      loading: () => const CivicLoadingState(),
      error: (error, _) => CivicErrorState(
        title: 'Sorry, there is a problem',
        message: '$error',
      ),
      data: (permits) => Column(
        children: [for (final permit in permits) Text(permit.registration)],
      ),
    ),
    'CivicErrorState': (context) => CivicErrorState(
      title: 'Sorry, the service is unavailable',
      message: 'Check your connection, then try again.',
      onRetry: retry,
    ),
    'CivicBreadcrumbs': (context) => CivicBreadcrumbs(
      items: [
        CivicBreadcrumb(label: 'Home', onPressed: goHome, url: Uri.parse('/')),
        CivicBreadcrumb(
          label: 'Your applications',
          onPressed: goBack,
          url: Uri.parse('/applications'),
        ),
      ],
    ),
    'CivicButton': (context) => CivicButton(
      onPressed: () => Navigator.of(context).pushNamed('/check'),
      child: const Text('Continue'),
    ),
    'CivicButtonGroup': (context) => CivicButtonGroup(
      children: [
        CivicButton(onPressed: save, child: const Text('Save and continue')),
        CivicLink(
          onPressed: later,
          child: const Text('Save and come back later'),
        ),
      ],
    ),
    'CivicCheckbox': (context) => CivicCheckbox(
      value: textMessages,
      onChanged: (value) => setState(() => textMessages = value!),
      labelText: 'Text message',
      helperText: 'We will send a text when your permit is ready.',
    ),
    'CivicCombobox': (context) => CivicCombobox<String>(
      labelText: 'Street',
      options: streets,
      onSelected: (value) => setState(() => street = value),
    ),
    'CivicDateInput': (context) => CivicDateInput(
      labelText: 'What is your date of birth?',
      helperText: 'For example, 27 3 1987',
      dayLabel: 'Day',
      monthLabel: 'Month',
      yearLabel: 'Year',
      dayController: day,
      monthController: month,
      yearController: year,
    ),
    'CivicDetails': (context) => const CivicDetails(
      title: 'Help with proof of address',
      child: Text(
        'A council tax bill or a tenancy agreement from the last '
        'three months.',
      ),
    ),
    'showCivicDialog': (context) {
      Future<bool?> ask() async {
        final cancel = await showCivicDialog<bool>(
          context: context,
          builder: (context) => CivicDialog(
            title: 'Cancel your application?',
            content: const Text('You will lose the answers you have given.'),
            actions: [
              CivicButton(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cancel application'),
              ),
              CivicButton.secondary(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep it'),
              ),
            ],
          ),
        );
        return cancel;
      }

      // A dialog opens from a press, never while a page builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) ask().ignore();
      });
      return null;
    },
    'CivicEmptyState': (context) => CivicEmptyState(
      title: 'No applications yet',
      actions: [
        CivicButton(onPressed: apply, child: const Text('Apply for a permit')),
      ],
      children: [const Text('When you apply for a permit it will show here.')],
    ),
    'CivicErrorSummary': (context) => Column(
      children: [
        if (errors.isNotEmpty)
          CivicErrorSummary(
            title: 'There is a problem',
            errors: [
              CivicErrorSummaryItem(
                text: 'Enter your full name',
                onPressed: nameFocus.requestFocus,
                url: Uri(fragment: 'full-name'),
              ),
            ],
          ),
      ],
    ),
    'CivicFieldset': (context) {
      bool? email = true;
      bool? post = false;
      void setEmail(bool? value) => email = value;
      void setPost(bool? value) => post = value;
      return CivicFieldset(
        labelText: 'How would you like to be contacted?',
        helperText: 'Select all that apply.',
        children: [
          CivicCheckbox(value: email, onChanged: setEmail, labelText: 'Email'),
          CivicCheckbox(value: post, onChanged: setPost, labelText: 'Post'),
        ],
      );
    },
    'CivicFileUpload': (context) => CivicFileUpload(
      labelText: 'Upload proof of address',
      helperText:
          'A council tax bill or a tenancy agreement, as a PDF or a photo.',
      chooseLabel: 'Choose file',
      emptyLabel: 'No file chosen',
      removeLabel: 'Remove',
      fileName: proof?.name,
      onChoose: pickProof,
      onRemoved: () => setState(() => proof = null),
    ),
    'CivicIconButton': (context) => CivicIconButton(
      icon: LucideIcons.x,
      semanticLabel: 'Close',
      tooltip: 'Close',
      onPressed: () => Navigator.of(context).pop(),
    ),
    'CivicInset': (context) => const CivicInset(
      child: Text('It can take up to 5 working days to decide.'),
    ),
    'CivicWarning': (context) => const CivicWarning(
      assistiveLabel: 'Warning',
      child: Text(
        'You can be fined up to 80 crowns if you park without a permit.',
      ),
    ),
    'CivicLink': (context) => CivicLink(
      url: Uri.parse('/guidance/permit-zones'),
      onPressed: () => router.go('/guidance/permit-zones'),
      child: const Text('Read the guidance on permit zones'),
    ),
    'CivicBackLink': (context) =>
        CivicBackLink(onPressed: () => Navigator.of(context).maybePop()),
    'CivicListRow': (context) => CivicListGroup(
      children: [
        CivicListRow(
          title: const Text('Resident permit, Zone B'),
          subtitle: const Text('BRM-4821-K · Sent 3 November'),
          trailing: const CivicTag(label: 'In review', tone: CivicTone.info),
          onTap: () => openApplication('BRM-4821-K'),
        ),
      ],
    ),
    'CivicListGroup': (context) => CivicListGroup(
      title: 'Your applications',
      children: [
        CivicListRow(
          title: const Text('Visitor permits, 10 days'),
          onTap: () => openApplication('BRM-3307-A'),
        ),
      ],
    ),
    'CivicNavigationBar': (context) => CivicNavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      destinations: const [
        CivicNavigationDestination(icon: LucideIcons.house, label: 'Home'),
        CivicNavigationDestination(
          icon: LucideIcons.fileText,
          label: 'Applications',
        ),
      ],
    ),
    'CivicSideNavigation': (context) => CivicSideNavigation(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      destinations: destinations,
    ),
    'CivicPagination': (context) => CivicPagination(
      pageCount: 12,
      selectedIndex: page,
      onPageChanged: (index) => setState(() => page = index),
      urlOf: (index) => Uri.parse('/streets?page=${index + 1}'),
    ),
    'CivicConfirmationPanel': (context) => CivicConfirmationPanel(
      title: 'Application sent',
      child: Column(
        children: [
          const Text('Your reference number'),
          Text('BRM-4821-K', style: context.civicText.code),
        ],
      ),
    ),
    'CivicNotificationBanner': (context) => const CivicNotificationBanner(
      title: 'Important',
      child: Text('Permits for Zone C are paused until 1 December.'),
    ),
    'CivicPasswordField': (context) => CivicPasswordField(
      labelText: 'Password',
      helperText: 'At least 10 characters',
      errorText: passwordError,
      onChanged: (value) => password = value,
    ),
    'CivicRadioGroup': (context) => CivicRadioGroup<String>(
      labelText: 'What kind of vehicle is the permit for?',
      isPageHeading: true,
      groupValue: vehicle,
      onChanged: (value) => setState(() => vehicle = value),
      children: const [
        CivicRadio(value: 'car', labelText: 'Car or van'),
        CivicRadio(
          value: 'motorcycle',
          labelText: 'Motorcycle',
          helperText: 'Includes mopeds and scooters.',
        ),
      ],
    ),
    'CivicScaffold': (context) => CivicScaffold(
      topBar: const CivicTopBar(title: 'Brindlemere parking permits'),
      skipLinkLabel: 'Skip to main content',
      body: CivicPageBody(title: 'Your applications', children: rows),
    ),
    'CivicPageBody': (context) => CivicPageBody(
      backLink: CivicBackLink(
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      caption: 'Question 2 of 5',
      action: CivicButton(onPressed: apply, child: const Text('Continue')),
      children: [question],
    ),
    'CivicSearchField': (context) => CivicSearchField(
      labelText: 'Search applications',
      helperText: 'A reference, a registration or a street',
      onSubmitted: (words) => setState(() => query = words),
    ),
    'CivicSectionBreak': (context) =>
        const CivicSectionBreak(size: CivicSectionBreakSize.large),
    'CivicSectionHeader': (context) => CivicSectionHeader(
      title: 'Your permits',
      action: CivicLink(onPressed: openAll, child: const Text('View all')),
    ),
    'CivicSelect': (context) => CivicSelect<String>(
      labelText: 'Permit zone',
      value: zone,
      onChanged: (value) => setState(() => zone = value),
      items: const [
        CivicSelectItem(value: 'a', label: 'Zone A: Old Town'),
        CivicSelectItem(value: 'b', label: 'Zone B: Harbourside'),
      ],
    ),
    'CivicSummaryList': (context) => CivicSummaryList(
      rows: [
        CivicSummaryRow(
          label: 'Name',
          value: const Text('Amara Okafor'),
          actionLabel: 'Change',
          actionSemanticLabel: 'Change name',
          onActionPressed: () => router.go('/apply/name'),
          actionUrl: Uri.parse('/apply/name'),
        ),
      ],
    ),
    'CivicSummaryCard': (context) {
      final rows = [
        const CivicSummaryRow(label: 'Registration', value: Text('CU57 ABC')),
      ];
      return CivicSummaryCard(
        title: 'Vehicle 1',
        actions: [CivicLink(onPressed: remove, child: const Text('Remove'))],
        child: CivicSummaryList(rows: rows),
      );
    },
    'CivicSwitch': (context) => CivicSwitch(
      value: largerText,
      onChanged: (value) => setState(() => largerText = value),
      labelText: 'Larger text',
      helperText: 'Makes the words on every page bigger.',
    ),
    'CivicTable': (context) => CivicTable<Map<String, String>>(
      caption: 'Permits in your household',
      controller: permits,
      cellBuilder: (context, permit, column) => Text(permit[column.id] ?? ''),
    ),
    'CivicTabBar': (context) => CivicTabBar(
      tabs: const ['Details', 'Documents', 'History'],
      selectedIndex: tab,
      onTap: (i) => setState(() => tab = i),
    ),
    'CivicTag': (context) =>
        const CivicTag(label: 'In progress', tone: CivicTone.info),
    'CivicTextField': (context) => CivicTextField(
      labelText: 'Postcode',
      widthInCharacters: 10,
      autofillHints: const [AutofillHints.postalCode],
      errorText: postcodeError,
      onChanged: (value) => postcode = value,
    ),
    'CivicTimeline': (context) => const CivicTimeline(
      entries: [
        CivicTimelineEntry(
          title: 'Proof of address checked',
          date: '5 November 2026',
        ),
        CivicTimelineEntry(
          title: 'Application received',
          date: '3 November 2026',
          child: Text('We will check it within 10 working days.'),
        ),
      ],
    ),
    'CivicToast': (context) {
      // A toast is shown from a press, never while a page builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        CivicToast.show(context, 'Your answers have been saved');
      });
      return null;
    },
    'CivicTopBar': (context) => CivicTopBar(
      title: 'Brindlemere parking permits',
      onTitlePressed: () => router.go('/'),
      actions: [
        CivicIconButton(
          icon: LucideIcons.user,
          semanticLabel: 'Your account',
          onPressed: openAccount,
        ),
      ],
    ),
    'CivicTopBar.backButton': (context) => CivicTopBar(
      title: 'Apply for a permit',
      leading: CivicTopBar.backButton(context, onPressed: goBack),
    ),
    'CivicTopBar.autoLeading': (context) => CivicTopBar(
      title: 'Your permit',
      leading: CivicTopBar.autoLeading(context),
    ),
    // fonts.dart
    'civicFontFamily': (context) async {
      final bytes = Future.value(
        ByteData.sublistView(
          File('assets/fonts/AtkinsonNext-400.ttf').readAsBytesSync(),
        ),
      );
      final loader = FontLoader(civicFontFamily('AtkinsonNext'))
        ..addFont(bytes);
      await loader.load();
      return null;
    },
    'civicLoadFonts': (context) {
      // An app's main, compiled here, not run: it would replace the test's
      // tree.
      Future<void> main() async {
        WidgetsFlutterBinding.ensureInitialized();
        await civicLoadFonts();
        runApp(const MyApp());
      }

      return main;
    },
    // material.dart
    'CivicFace': (context) => CivicFace(
      fill: context.civicTheme.action,
      edgeColor: context.civicTheme.actionEdge,
      edgeHeight: CivicMetrics.bar,
      pressed: pressed,
      focused: focused,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + CivicMetrics.bar),
        child: Text('Continue'),
      ),
    ),
    'CivicWell': (context) => CivicWell(
      focused: focused,
      child: const Padding(
        padding: EdgeInsets.all(CivicMetrics.edge + 12),
        child: Text('42'),
      ),
    ),
    // theme.dart
    'CivicStyle': (context) => CivicButton(
      style: const CivicStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 32)),
      ),
      onPressed: () {},
      child: const Text('Continue'),
    ),
    'CivicThemeData': (context) {
      final theme = CivicThemeData.light();
      final mine = CivicThemeData.from(
        brightness: Brightness.light,
        action: const Color(0xFF00594C),
      );
      return Column(
        children: [
          CivicTheme(data: theme, child: const Text('Light')),
          CivicTheme(data: mine, child: const Text('Mine')),
        ],
      );
    },
    'CivicTheme': (context) => MaterialApp(
      builder: (context, child) => CivicTheme(
        data: MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? CivicThemeData.dark()
            : CivicThemeData.light(),
        child: child!,
      ),
      home: const ApplyPage(),
    ),
    'AnimatedCivicTheme': (context) {
      const page = Text('Your permit');
      return AnimatedCivicTheme(
        data: night ? CivicThemeData.dark() : CivicThemeData.light(),
        child: page,
      );
    },
    // chip/chip.dart
    'CivicChip': (context) => CivicChip(
      label: 'Open now',
      selected: openNow,
      onSelected: (on) => setState(() => openNow = on),
    ),
    // calendar/calendar.dart
    'CivicCalendar': (context) => CivicCalendar(
      controller: dates,
      onChanged: (day) => setState(() => chosen = day),
    ),
    // code-field/code_field.dart
    'CivicCodeField': (context) => CivicCodeField(
      labelText: 'Security code',
      helperText: 'We sent a 6 digit code to 07700 900 123.',
      onCompleted: (code) => confirm(code),
    ),
    // color-picker/color_picker.dart
    'CivicColorPicker': (context) => SingleChildScrollView(
      child: CivicColorPicker(
        labelText: 'Badge colour',
        controller: badge,
        swatches: const [
          CivicColorSwatch(Color(0xFF0F4C81), 'Harbour blue'),
          CivicColorSwatch(Color(0xFF0B6136), 'Park green'),
        ],
      ),
    ),
    // date-picker/date_picker.dart
    'CivicDatePicker': (context) => CivicDatePicker(
      labelText: 'When do you want the permit to start?',
      helperText:
          'For example, ${CivicDatePicker.exampleOf(context, DateTime(2026, 3, 27))}',
      value: start,
      firstDate: DateTime(2026),
      lastDate: DateTime(2026, 12, 31),
      onChanged: (day) => setState(() => start = day),
    ),
    'CivicDateRangePicker': (context) => CivicDateRangePicker(
      labelText: 'When will your visitor stay?',
      value: stay,
      firstDate: DateTime(2026),
      lastDate: DateTime(2026, 12, 31),
      onChanged: (range) => setState(() => stay = range),
    ),
    'CivicTimeInput': (context) => CivicTimeInput(
      labelText: 'What time will you arrive?',
      helperText: 'For example, 9:30 AM',
      value: arrival,
      onChanged: (time) => setState(() => arrival = time),
    ),
    // kbd/kbd.dart
    'CivicKbd': (context) => const Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Press '),
          WidgetSpan(child: CivicKbd('Enter')),
          TextSpan(text: ' to continue.'),
        ],
      ),
    ),
    // multi-select/multi_select.dart
    'CivicMultiSelect': (context) => CivicMultiSelect<String>(
      labelText: 'Which languages do you speak?',
      options: languages,
      values: spoken,
      onChanged: (next) => setState(() => spoken = next),
    ),
    // number-field/number_field.dart
    'CivicNumberField': (context) => CivicNumberField(
      labelText: 'How many visitor days do you need?',
      helperText: 'From 1 to 30 days.',
      value: days,
      min: 1,
      max: 30,
      onChanged: (value) => setState(() => days = value),
    ),
    // rating/rating.dart
    'CivicRating': (context) => CivicRating(
      labelText: 'How easy was it to apply?',
      value: score,
      labels: const ['Very hard', 'Hard', 'Neither', 'Easy', 'Very easy'],
      onChanged: (v) => setState(() => score = v),
    ),
    // slider/slider.dart
    'CivicSlider': (context) => CivicSlider(
      labelText: 'Text size',
      value: size,
      min: 100,
      max: 200,
      divisions: 4,
      valueLabel: (v) => '${v.round()}%',
      onChanged: (v) => setState(() => size = v),
    ),
    'CivicRangeSlider': (context) => CivicRangeSlider(
      labelText: 'Monthly cost',
      values: cost,
      max: 100,
      valueLabel: (v) => '£${v.round()}',
      onChanged: (range) => setState(() => cost = range),
    ),
    // text-area/text_area.dart
    'CivicTextArea': (context) => CivicTextArea(
      labelText: 'Why do you need a visitor permit?',
      helperText: 'Do not include personal or financial information.',
      maxLength: 500,
      controller: reason,
    ),
    // toggle-group/toggle_group.dart
    'CivicToggleGroup': (context) => CivicToggleGroup<String>(
      labelText: 'Show',
      segments: const [
        CivicSegment(value: 'closed', label: 'Closed'),
        CivicSegment(value: 'drafts', label: 'Drafts'),
      ],
      selected: shown,
      onSelectionChanged: (next) => setState(() => shown = next),
    ),
    'CivicSegmentedControl': (context) => CivicSegmentedControl<String>(
      labelText: 'Period',
      segments: const [
        CivicSegment(value: 'week', label: 'Week'),
        CivicSegment(value: 'month', label: 'Month'),
      ],
      value: period,
      onChanged: (next) => setState(() => period = next),
    ),
    // wheel-picker/wheel_picker.dart
    'CivicWheelPicker': (context) => CivicWheelPicker(
      labelText: 'Arrival time',
      columns: (_) => [
        RawPickerColumn(itemCount: 24, itemLabel: (i) => '$i', looping: true),
        RawPickerColumn(
          itemCount: 4,
          itemLabel: (i) => '${i * 15}'.padLeft(2, '0'),
        ),
      ],
      selection: slot,
      onChanged: (next) => setState(() => slot = next),
    ),
    // menu/menu.dart
    'CivicMenuItem': (context) {
      const item = CivicMenuItem(
        value: 'print',
        label: 'Print this page',
        icon: LucideIcons.printer,
      );
      return Text(item.label);
    },
    'CivicMenu': (context) => CivicMenu<String>(
      semanticLabel: 'Application actions',
      items: const [
        CivicMenuItem(value: 'print', label: 'Print this page'),
        CivicMenuItem(
          value: 'withdraw',
          label: 'Withdraw application',
          isDestructiveAction: true,
          startsGroup: true,
        ),
      ],
      onSelected: (action) {},
      builder: (context, anchor) => CivicButton.secondary(
        onPressed: anchor.toggle,
        child: const Text('Actions'),
      ),
    ),
    // split-button/split_button.dart
    'CivicSplitButton': (context) => CivicSplitButton(
      label: 'Send application',
      onPressed: () {},
      actions: [
        CivicSplitAction('Save and come back later', onPressed: () {}),
        CivicSplitAction('Print your answers', onPressed: () {}),
      ],
    ),
    // popover/popover.dart
    'CivicPopover': (context) => CivicPopover(
      title: 'Who counts as a visitor',
      content: const Text(
        'Anyone staying less than 14 days who does not live at the address.',
      ),
      builder: (context, anchor) => CivicLink(
        onPressed: anchor.toggle,
        child: const Text('Who counts as a visitor?'),
      ),
    ),
    // tooltip/tooltip.dart
    'CivicTooltip': (context) => CivicTooltip(
      message: 'Print this page',
      child: CivicIconButton(
        icon: LucideIcons.printer,
        semanticLabel: 'Print this page',
        onPressed: () {},
      ),
    ),
    // sheet/sheet.dart
    'showCivicBottomSheet': (context) {
      // A sheet opens from a press, never while a page builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showCivicBottomSheet<void>(
          context: context,
          title: 'Filter applications',
          builder: (context) => const Text('Status'),
          actions: [
            CivicButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Show applications'),
            ),
          ],
        );
      });
      return null;
    },
    'showCivicSideSheet': (context) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showCivicSideSheet<void>(
          context: context,
          title: 'Filter applications',
          builder: (context) => const Text('Status'),
        );
      });
      return null;
    },
    'showCivicActionSheet': (context) {
      Future<String?> ask() async {
        final action = await showCivicActionSheet<String>(
          context: context,
          title: 'Application BRM-4821-K',
          actions: const [
            CivicActionSheetAction(value: 'print', label: 'Print your answers'),
            CivicActionSheetAction(
              value: 'withdraw',
              label: 'Withdraw application',
              isDestructiveAction: true,
            ),
          ],
        );
        return action;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) ask().ignore();
      });
      return null;
    },
    // command-palette/command_palette.dart
    'showCivicCommandPalette': (context) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showCivicCommandPalette(
          context: context,
          commands: [
            RawCommand(
              label: 'Your applications',
              group: 'Pages',
              onPressed: () {},
            ),
            RawCommand(
              label: 'Apply for a permit',
              group: 'Actions',
              onPressed: () {},
            ),
          ],
        );
      });
      return null;
    },
    // card/card.dart
    'CivicCard': (context) => CivicCard(
      title: 'Resident permit, Zone B',
      url: Uri.parse('/permits/BRM-4821-K'),
      onPressed: () {},
      child: const Text('Runs out on 3 November 2027.'),
    ),
    // accordion/accordion.dart
    'CivicAccordion': (context) => const CivicAccordion(
      sections: [
        CivicAccordionSection(
          title: 'Who can apply',
          child: Text('Anyone who lives in a permit zone.'),
        ),
        CivicAccordionSection(
          title: 'What it costs',
          child: Text('€60 a year.'),
        ),
      ],
    ),
    // step-indicator/step_indicator.dart
    'CivicStepIndicator': (context) => const CivicStepIndicator(
      steps: ['Your vehicle', 'Your details', 'Proof of address', 'Check'],
      currentStep: 1,
    ),
    // page-dots/page_dots.dart
    'CivicPageDots': (context) =>
        CivicPageDots(pageCount: 5, selectedIndex: 1, onPageChanged: (page) {}),
    // carousel/carousel.dart
    'CivicCarousel': (context) => CivicCarousel(
      semanticLabel: 'Photos of Zone B',
      itemCount: 3,
      itemBuilder: (context, index) => Center(child: Text('Photo $index')),
    ),
    // scroll-area/scroll_area.dart
    'CivicScrollArea': (context) => CivicScrollArea(
      controller: terms,
      semanticLabel: 'Terms of the permit',
      child: SingleChildScrollView(
        controller: terms,
        child: const Text('The permit is for the vehicle named on it.'),
      ),
    ),
    // split-view/split_view.dart
    'CivicSplitView': (context) => const CivicSplitView(
      first: Text('Your applications'),
      second: Text('Resident permit, Zone B'),
      minFirst: 160,
      minSecond: 240,
    ),
    // reorderable-list/reorderable_list.dart
    'CivicReorderableList': (context) => CivicReorderableList<String>(
      items: documents,
      labelOf: (d) => d,
      onReorder: (from, to) => setState(() {
        documents.insert(to, documents.removeAt(from));
      }),
    ),
    // swipe-actions/swipe_actions.dart
    'CivicSwipeActions': (context) => CivicSwipeActions(
      menuLabel: 'Actions for Resident permit',
      endActions: [
        CivicSwipeAction(label: 'Archive', onPressed: () {}),
        CivicSwipeAction(
          label: 'Withdraw',
          onPressed: () {},
          isDestructiveAction: true,
        ),
      ],
      child: const CivicListRow(title: Text('Resident permit')),
    ),
    // tree/tree.dart
    'CivicTree': (context) => CivicTree<String>(
      controller: services,
      labelOf: (s) => s,
      onActivate: (s) => openService(s),
    ),
    // avatar/avatar.dart
    'CivicAvatar': (context) => const CivicAvatar(name: 'Ana Ruiz'),
    'CivicAvatarGroup': (context) => const CivicAvatarGroup(
      names: ['Ana Ruiz', 'Ben Okafor', 'Chi Lee', 'Dev Rao'],
    ),
    // badge/badge.dart
    'CivicBadge': (context) => const CivicBadge(
      count: 2,
      noun: 'update',
      child: Text('Your applications'),
    ),
    // image/image.dart
    'CivicImage': (context) => const CivicImage(
      image: AssetImage('assets/zone-b.png'),
      description: 'Map of Zone B: from the river to Mill Lane',
      caption: 'Zone B runs from the river to Mill Lane.',
    ),
    // amount/amount.dart
    'CivicAmount': (context) => const CivicAmount(6250),
    // key-figure/key_figure.dart
    'CivicKeyFigure': (context) => const CivicKeyFigure(
      label: 'Permits issued this year',
      value: '1,240',
      detail: 'To 31 October 2026',
    ),
    // grid/grid.dart
    'CivicGrid': (context) => const CivicGrid(
      children: [
        CivicCard(title: 'Parking', child: Text('Permits, fines, bays')),
        CivicCard(title: 'Bins', child: Text('Collections, new bins')),
        CivicCard(title: 'Council tax', child: Text('Pay, discounts')),
      ],
    ),
    // spinner/spinner.dart (it turns until it goes, so it is shown still)
    'CivicSpinner': (context) =>
        _still(const CivicSpinner(label: 'Checking your vehicle')),
    // progress-bar/progress_bar.dart
    'CivicProgressBar': (context) => const CivicProgressBar(
      label: 'Uploading proof of address',
      value: 0.4,
      valueLabel: '2 of 5 pages uploaded',
    ),
    // meter/meter.dart
    'CivicMeter': (context) => const CivicMeter(
      label: 'Visitor days used this year',
      value: 38,
      max: 60,
      high: 50,
      valueLabel: '38 of 60 days used',
    ),
    // skeleton/skeleton.dart (it fades until it goes, so it is shown still)
    'CivicSkeleton': (context) => _still(
      const CivicSkeleton(
        child: Row(
          spacing: 16,
          children: [
            CivicSkeletonBlock(width: 48, height: 48, circle: true),
            Expanded(child: CivicSkeletonText(lines: 2)),
          ],
        ),
      ),
    ),
    'CivicSkeletonBlock': (context) => const CivicSkeletonBlock(height: 120),
    'CivicSkeletonText': (context) => const CivicSkeletonText(lines: 3),
    // charts/charts.dart
    'CivicLineChart': (context) => const CivicLineChart(
      title: 'Permits issued each month',
      labels: ['Jan', 'Feb', 'Mar'],
      series: [
        CivicChartSeries('Resident', [120, 135, 128]),
        CivicChartSeries('Visitor', [80, 92, 110]),
      ],
    ),
    'CivicAreaChart': (context) => const CivicAreaChart(
      title: 'Applications waiting',
      labels: ['Mon', 'Tue', 'Wed'],
      series: [
        CivicChartSeries('Waiting', [42, 38, 51]),
      ],
    ),
    'CivicBarChart': (context) => const CivicBarChart(
      title: 'Fines paid by quarter',
      labels: ['Q1', 'Q2', 'Q3', 'Q4'],
      series: [
        CivicChartSeries('Fines paid', [310, 280, 355, 290]),
      ],
    ),
    'CivicSparkline': (context) => const CivicSparkline(
      label: 'Visitor permits this week',
      values: [12, 18, 15, 22, 19, 26, 31],
    ),
    // charts/pie_chart.dart
    'CivicPieChart': (context) => const CivicPieChart(
      title: 'Permits by kind',
      slices: [
        CivicPieSlice('Resident', 1240),
        CivicPieSlice('Visitor', 610),
        CivicPieSlice('Business', 150),
      ],
    ),
    // pull-to-refresh/pull_to_refresh.dart
    'CivicPullToRefresh': (context) => CivicPullToRefresh(
      onRefresh: fetchApplications,
      child: ListView(children: rows),
    ),
    // action-bar/action_bar.dart
    'CivicActionBar': (context) => CivicActionBar(
      count: picked.length,
      onClear: () => setState(picked.clear),
      actions: [
        CivicButton.secondary(onPressed: renew, child: const Text('Renew')),
      ],
    ),
    // format.dart
    'CivicFormat': (context) {
      final permit = (ends: DateTime(2026, 11, 3));
      return Text('Your permit ends on ${CivicFormat.date(permit.ends)}');
    },
  };
}

/// [child] under Reduce Motion, for a part that moves until it goes (a
/// wait), which a test that waits for the page to settle would wait on
/// forever.
Widget _still(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

Widget _harness(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => CivicHost(child: app ?? const SizedBox.shrink()),
  home: child,
);

void main() {
  tearDown(() {
    for (final dispose in _disposers) {
      dispose();
    }
    _disposers.clear();
  });

  test("civic_parts.dart's example imports what this file imports", () {
    expect(
      _partsImports,
      contains("import 'package:civic_ui/civic_parts.dart';"),
    );
  });

  testDocExamples(
    self: 'test/doc_examples_test.dart',
    examples: _Caller().examples,
    wrap: _harness,
    skip: const {'routes.dart'},
  );
}
