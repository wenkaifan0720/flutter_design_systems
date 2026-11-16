/// slipway's world: a small team's deploy console, its five projects, their
/// runs and one failing test. Every name is made up.
library;

/// How a run ended, or where it is.
enum RunStatus {
  /// Every step passed.
  passed,

  /// A step failed.
  failed,

  /// It is running now.
  running,

  /// It waits for a runner.
  queued,

  /// Someone stopped it.
  canceled;

  /// The glyph a list shows for it (running draws a spinner instead).
  String get glyph => switch (this) {
    passed => '✓',
    failed => '✗',
    running => '●',
    queued => '○',
    canceled => '–',
  };
}

/// A step of a run.
typedef RunStep = ({String name, RunStatus status, String duration});

/// A run of a project's pipeline.
typedef Run = ({
  int number,
  String project,
  String branch,
  String commit,
  String message,
  String author,
  RunStatus status,
  String duration,
  String ago,
  String trigger,
  double? progress,
});

/// A project slipway deploys.
typedef Project = ({String name, String repo, String env, int runs});

/// The projects.
const List<Project> slipwayProjects = [
  (name: 'atlas-api', repo: 'harbor/atlas-api', env: 'production', runs: 1482),
  (name: 'web-console', repo: 'harbor/web-console', env: 'staging', runs: 911),
  (
    name: 'billing-worker',
    repo: 'harbor/billing-worker',
    env: 'production',
    runs: 604,
  ),
  (name: 'docs-site', repo: 'harbor/docs-site', env: 'preview', runs: 233),
  (
    name: 'mobile-gateway',
    repo: 'harbor/mobile-gateway',
    env: 'staging',
    runs: 377,
  ),
];

/// The latest runs, newest first.
const List<Run> slipwayRuns = [
  (
    number: 1482,
    project: 'atlas-api',
    branch: 'feat/rate-limits',
    commit: '9f3c2a1',
    message: 'cap retries at the gateway budget',
    author: 'mira',
    status: RunStatus.running,
    duration: '1m 48s',
    ago: 'now',
    trigger: 'push',
    progress: 0.62,
  ),
  (
    number: 1481,
    project: 'atlas-api',
    branch: 'fix/flaky-auth',
    commit: 'c41d7e0',
    message: 'wait for the token cache before the first call',
    author: 'oskar',
    status: RunStatus.failed,
    duration: '3m 02s',
    ago: '6m',
    trigger: 'push',
    progress: null,
  ),
  (
    number: 911,
    project: 'web-console',
    branch: 'main',
    commit: '2be8f90',
    message: 'merge: settings page reads the config file',
    author: 'devi',
    status: RunStatus.passed,
    duration: '4m 31s',
    ago: '14m',
    trigger: 'merge',
    progress: null,
  ),
  (
    number: 604,
    project: 'billing-worker',
    branch: 'main',
    commit: '71aa3c4',
    message: 'invoice rounding follows the ledger',
    author: 'tamar',
    status: RunStatus.passed,
    duration: '2m 10s',
    ago: '38m',
    trigger: 'schedule',
    progress: null,
  ),
  (
    number: 233,
    project: 'docs-site',
    branch: 'preview/cli-guide',
    commit: 'e09b1d2',
    message: 'cli guide: the deploy command',
    author: 'mira',
    status: RunStatus.queued,
    duration: '–',
    ago: '1m',
    trigger: 'push',
    progress: null,
  ),
  (
    number: 377,
    project: 'mobile-gateway',
    branch: 'main',
    commit: '5c6f0ab',
    message: 'pin the tls profile',
    author: 'oskar',
    status: RunStatus.canceled,
    duration: '0m 41s',
    ago: '1h',
    trigger: 'manual',
    progress: null,
  ),
  (
    number: 1480,
    project: 'atlas-api',
    branch: 'main',
    commit: '0ad44f1',
    message: 'bump the runtime to 22',
    author: 'devi',
    status: RunStatus.passed,
    duration: '2m 57s',
    ago: '2h',
    trigger: 'merge',
    progress: null,
  ),
];

/// The steps of run #1481, the failing one.
const List<RunStep> slipwayFailedSteps = [
  (name: 'checkout', status: RunStatus.passed, duration: '3s'),
  (name: 'install', status: RunStatus.passed, duration: '41s'),
  (name: 'build', status: RunStatus.passed, duration: '58s'),
  (name: 'test', status: RunStatus.failed, duration: '1m 12s'),
  (name: 'deploy', status: RunStatus.canceled, duration: '–'),
];

/// The test step's log.
const List<String> slipwayLog = [
  r'$ make test',
  '',
  'testrun 3.2 · /work/atlas-api · 5 files',
  '',
  ' ✓ src/limits/budget.test.ts (12 tests) 84ms',
  ' ✓ src/limits/window.test.ts (8 tests) 41ms',
  ' ✓ src/routes/health.test.ts (3 tests) 12ms',
  ' ✗ src/auth/token.test.ts (6 tests | 1 failed) 2207ms',
  '   ✗ token cache > refreshes before expiry',
  '     AssertionError: expected 401 to be 200',
  '      ❯ src/auth/token.test.ts:48:31',
  '     46|   await clock.advance(minutes(59));',
  '     47|   const res = await client.get("/v1/me");',
  '     48|   expect(res.status).toBe(200);',
  '       |                               ^',
  '     49| });',
  ' ✓ src/routes/projects.test.ts (17 tests) 133ms',
  '',
  ' Test Files  1 failed | 4 passed (5)',
  '      Tests  1 failed | 45 passed (46)',
  '   Duration  2.71s',
  '',
  'error: step "test" exited with code 1',
];

/// The steps of [run], as far as it got.
List<RunStep> slipwayStepsOf(Run run) => switch (run.status) {
  RunStatus.failed => slipwayFailedSteps,
  RunStatus.queued => [
    for (final s in slipwayFailedSteps)
      (name: s.name, status: RunStatus.queued, duration: '–'),
  ],
  RunStatus.canceled => [
    for (final (i, s) in slipwayFailedSteps.indexed)
      (
        name: s.name,
        status: i == 0 ? RunStatus.passed : RunStatus.canceled,
        duration: i == 0 ? s.duration : (i == 1 ? '38s' : '–'),
      ),
  ],
  RunStatus.running => [
    for (final s in slipwayFailedSteps)
      (
        name: s.name,
        status: switch (s.name) {
          'test' => RunStatus.running,
          'deploy' => RunStatus.queued,
          _ => RunStatus.passed,
        },
        duration: switch (s.name) {
          'test' => '6s',
          'deploy' => '–',
          _ => s.duration,
        },
      ),
  ],
  RunStatus.passed => [
    for (final s in slipwayFailedSteps)
      (
        name: s.name,
        status: RunStatus.passed,
        duration: s.name == 'deploy' ? '22s' : s.duration,
      ),
  ],
};

/// The test step's log for [run]: the failing one's in full, a running
/// one's so far, a passing one's green, and a line for a run whose tests
/// never started.
List<String> slipwayLogOf(Run run) {
  final head = [
    r'$ make test',
    '',
    'testrun 3.2 · /work/${run.project} · 5 files',
    '',
  ];
  return switch (run.status) {
    RunStatus.failed => slipwayLog,
    RunStatus.queued => ['waiting for a runner · 2 runs ahead'],
    RunStatus.canceled => [
      'the tests never ran: ${run.author} canceled the run during install',
    ],
    RunStatus.running => [...head, ...slipwayLog.sublist(4, 7)],
    RunStatus.passed => [
      ...head,
      ...slipwayLog.sublist(4, 7),
      ' ✓ src/auth/token.test.ts (6 tests) 2207ms',
      slipwayLog[16],
      '',
      ' Test Files  5 passed (5)',
      '      Tests  46 passed (46)',
      '   Duration  2.71s',
    ],
  };
}

/// The branches the deploy form offers.
const List<String> slipwayBranches = [
  'main',
  'feat/rate-limits',
  'fix/flaky-auth',
  'preview/cli-guide',
];

/// Hebrew words for the right-to-left screens: the commit messages a
/// Hebrew-speaking teammate writes.
const Map<int, String> slipwayHebrewMessages = {
  1482: 'הגבלת ניסיונות חוזרים לתקציב השער',
  1481: 'המתנה למטמון האסימונים לפני הקריאה הראשונה',
  911: 'מיזוג: דף ההגדרות קורא את קובץ התצורה',
  604: 'עיגול החשבוניות לפי ספר החשבונות',
  233: 'מדריך שורת הפקודה: פקודת הפריסה',
  377: 'קיבוע פרופיל ה-TLS',
  1480: 'שדרוג סביבת הריצה לגרסה 22',
};

/// One line of a change: [op] `' '` kept, `'-'` gone, `'+'` new.
typedef DiffLine = ({String op, String text});

/// The file run #1481's commit changed.
const String slipwayDiffFile = 'src/auth/token.ts';

/// Where the change starts in the file, before and after.
const int slipwayDiffStart = 12;

/// Run #1481's change: wait for a token that will last, not any token.
const List<DiffLine> slipwayDiff = [
  (op: ' ', text: 'export async function token(client: Client) {'),
  (op: ' ', text: '  const cached = cache.get("token");'),
  (op: '-', text: '  if (cached) return cached;'),
  (
    op: '+',
    text: '  if (cached && cached.expires > clock.now() + minutes(5)) {',
  ),
  (op: '+', text: '    return cached;'),
  (op: '+', text: '  }'),
  (op: ' ', text: '  const fresh = await client.post("/v1/token");'),
  (op: '-', text: '  cache.set("token", fresh, minutes(60));'),
  (op: '+', text: '  cache.set("token", fresh, minutes(55));'),
  (op: ' ', text: '  return fresh;'),
  (op: ' ', text: '}'),
];
