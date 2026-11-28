import 'models.dart';

/// A Friday in the studio. A fresh run always reconstructs this same fortnight.
final studyToday = DateTime(2026, 11, 20);
final studyMorning = atMinute(studyToday, 10 * 60);
final seedTimer = (taskId: 'ST-101', start: atMinute(studyToday, 8 * 60 + 18));

DateTime Function() studyClock() {
  final elapsed = Stopwatch()..start();
  return () => studyMorning.add(elapsed.elapsed);
}

const team = <Person>[
  (id: 'maya', name: ('Maya Reed', 'مايا ريد', 'マヤ・リード', 'Maya Reed')),
  (id: 'sam', name: ('Sam Okafor', 'سام أوكافور', 'サム・オカフォー', 'Sam Okafor')),
  (id: 'noor', name: ('Noor Haddad', 'نور حداد', 'ヌール・ハッダード', 'Noor Haddad')),
  (id: 'inez', name: ('Inez Park', 'إينيز بارك', 'イネス・パーク', 'Inez Park')),
  (id: 'leo', name: ('Leo Silva', 'ليو سيلفا', 'レオ・シルバ', 'Leo Silva')),
];

const projects = <Project>[
  (
    id: 'studio',
    name: ('Open studio', 'الاستوديو المفتوح', 'オープンスタジオ', 'Offenes Atelier'),
  ),
  (
    id: 'guide',
    name: ('Field guide', 'الدليل الميداني', 'フィールドガイド', 'Exkursionsführer'),
  ),
  (
    id: 'workshops',
    name: ('Workshop series', 'سلسلة الورش', '連続ワークショップ', 'Workshopreihe'),
  ),
];

const _titles = <TeamText>[
  (
    'Proof the studio map',
    'مراجعة خريطة الاستوديو',
    'スタジオマップを校正',
    'Atelierplan Korrektur lesen',
  ),
  (
    'Edit the walking route',
    'تحرير مسار المشي',
    '散策ルートを編集',
    'Spazierroute überarbeiten',
  ),
  (
    'Confirm the print workshop',
    'تأكيد ورشة الطباعة',
    '版画ワークショップを確定',
    'Druckworkshop bestätigen',
  ),
  (
    'Frame the entryway prints',
    'تأطير مطبوعات المدخل',
    'エントランスの版画を額装',
    'Drucke für den Eingang rahmen',
  ),
  (
    'Check the specimen captions',
    'تدقيق شروح العينات',
    '標本のキャプションを確認',
    'Bildunterschriften der Exponate prüfen',
  ),
  (
    'Send the materials list',
    'إرسال قائمة المواد',
    '材料リストを送付',
    'Materialliste verschicken',
  ),
  (
    'Hang the courtyard signs',
    'تعليق لافتات الفناء',
    '中庭のサインを設置',
    'Schilder im Innenhof aufhängen',
  ),
  (
    'Sequence the photographs',
    'ترتيب الصور',
    '写真の順番を決める',
    'Fotos in Reihenfolge bringen',
  ),
  (
    'Book the teaching space',
    'حجز مساحة التدريس',
    '講習スペースを予約',
    'Unterrichtsraum buchen',
  ),
  (
    'Pack the welcome table',
    'تجهيز طاولة الاستقبال',
    '受付テーブルを準備',
    'Empfangstisch vorbereiten',
  ),
  (
    'Draw the footbridge detail',
    'رسم تفاصيل الجسر',
    '歩道橋の詳細図を描く',
    'Detailzeichnung der Fußgängerbrücke anfertigen',
  ),
  (
    'Test the clay samples',
    'اختبار عينات الطين',
    '粘土サンプルを試す',
    'Tonproben testen',
  ),
  (
    'Check the evening lighting',
    'فحص الإضاءة المسائية',
    '夜間照明を確認',
    'Abendbeleuchtung prüfen',
  ),
  ('Write the introduction', 'كتابة المقدمة', '序文を書く', 'Einleitung schreiben'),
  (
    'Set the workshop dates',
    'تحديد مواعيد الورش',
    'ワークショップの日程を決める',
    'Workshoptermine festlegen',
  ),
  (
    'Label the display shelves',
    'وضع بطاقات على الرفوف',
    '展示棚にラベルを貼る',
    'Ausstellungsregale beschriften',
  ),
  (
    'Choose the cover stock',
    'اختيار ورق الغلاف',
    '表紙の用紙を選ぶ',
    'Umschlagkarton auswählen',
  ),
  (
    'Prepare the sign-up form',
    'تجهيز استمارة التسجيل',
    '申込フォームを準備',
    'Anmeldeformular vorbereiten',
  ),
  (
    'Plan the room rotation',
    'تخطيط ترتيب الغرف',
    '部屋の割り当てを計画',
    'Raumbelegung planen',
  ),
  (
    'Review the foldout proof',
    'مراجعة نموذج المطوية',
    '折り込みの校正刷りを確認',
    'Korrekturabzug des Faltblatts prüfen',
  ),
  (
    'Reserve the drying racks',
    'حجز رفوف التجفيف',
    '乾燥ラックを予約',
    'Trockengestelle reservieren',
  ),
  (
    'Order clips for the wall',
    'طلب مشابك للحائط',
    '壁用のクリップを注文',
    'Klammern für die Wand bestellen',
  ),
  (
    'Credit the contributors',
    'إضافة أسماء المساهمين',
    '協力者のクレジットを記載',
    'Mitwirkende nennen',
  ),
  (
    'Prepare the tool kits',
    'تجهيز حقائب الأدوات',
    '道具セットを準備',
    'Werkzeugsets vorbereiten',
  ),
  (
    'Mark the accessible route',
    'تحديد المسار الميسّر',
    'バリアフリールートを示す',
    'Barrierefreien Weg markieren',
  ),
  (
    'Index the plant names',
    'فهرسة أسماء النباتات',
    '植物名の索引を作成',
    'Register der Pflanzennamen erstellen',
  ),
  (
    'Invite the guest tutor',
    'دعوة المدرّس الضيف',
    'ゲスト講師を招待',
    'Gastlehrkraft einladen',
  ),
  (
    'Update the visitor list',
    'تحديث قائمة الزوار',
    '来場者リストを更新',
    'Besucherliste aktualisieren',
  ),
  (
    'Scan the notebook pages',
    'مسح صفحات الدفتر',
    'ノートのページをスキャン',
    'Notizbuchseiten scannen',
  ),
  (
    'Cut the paper bundles',
    'قص رزم الورق',
    '紙の束を裁断',
    'Papierstapel zuschneiden',
  ),
  (
    'Collect the loan frames',
    'جمع الإطارات المستعارة',
    '貸出用の額縁を回収',
    'Leihrahmen abholen',
  ),
  (
    'Number the map stops',
    'ترقيم محطات الخريطة',
    'マップの立ち寄り先に番号を振る',
    'Kartenstationen nummerieren',
  ),
  (
    'Count the spare aprons',
    'عدّ المرايل الاحتياطية',
    '予備のエプロンを数える',
    'Ersatzschürzen zählen',
  ),
  (
    'File the installation plan',
    'أرشفة خطة التركيب',
    '設営計画をファイル',
    'Aufbauplan ablegen',
  ),
  (
    'Approve the spine type',
    'اعتماد خط كعب الكتاب',
    '背表紙の書体を承認',
    'Schrift für den Buchrücken freigeben',
  ),
  (
    'Share the class outline',
    'مشاركة مخطط الدرس',
    '講座の概要を共有',
    'Kursübersicht teilen',
  ),
  (
    'Confirm the steward rota',
    'تأكيد مناوبات المشرفين',
    '係員のシフトを確定',
    'Aufsichtsdienstplan bestätigen',
  ),
  (
    'Check the archive dates',
    'مراجعة تواريخ الأرشيف',
    'アーカイブの日付を確認',
    'Archivdaten prüfen',
  ),
  (
    'Print attendance sheets',
    'طباعة أوراق الحضور',
    '出席表を印刷',
    'Anwesenheitslisten drucken',
  ),
  (
    'Return the sample boards',
    'إعادة ألواح العينات',
    'サンプルボードを返却',
    'Musterplatten zurückgeben',
  ),
];
const _notes = <TeamText>[
  (
    'Use the courtyard entrance on the public copy. Check the step-free route with Sam before sending it to print.',
    'أظهر مدخل الفناء في نسخة الزوار. راجع المسار الخالي من الدرج مع سام قبل إرسال الملف للطباعة.',
    '一般向けの版では中庭側の入口を案内してください。印刷に回す前に、段差のないルートをサムさんと確認してください。',
    'Auf der öffentlichen Fassung den Eingang über den Innenhof angeben. Vor dem Druck die stufenlose Route mit Sam prüfen.',
  ),
  (
    'Compare the latest draft with the marked-up copy on the studio table.',
    'قارن المسودة الأخيرة بالنسخة المصححة على طاولة الاستوديو.',
    '最新の原稿を、スタジオの机にある赤字入りの版と照らし合わせてください。',
    'Den neuesten Entwurf mit der korrigierten Fassung auf dem Ateliertisch vergleichen.',
  ),
  (
    'Confirm the details with the teaching team and add them to the shared schedule.',
    'أكّد التفاصيل مع فريق التدريس وأضفها إلى الجدول المشترك.',
    '講師チームと詳細を確認し、共有スケジュールに追加してください。',
    'Die Details mit dem Lehrteam abstimmen und in den gemeinsamen Zeitplan eintragen.',
  ),
];

List<Task> seedTasks() => List.generate(
  _titles.length,
  (i) => Task(
    id: 'ST-${101 + i}',
    title: _titles[i],
    notes: _notes[i % 3],
    project: projects[i % 3].id,
    assignee: team[i % 5].id,
    due: i == 38
        ? studyToday
        : addDays(studyToday, i ~/ 3 - (i >= 30 ? 16 : 0)),
    estimate: [45, 90, 30, 60, 120][i % 5],
    priority: [
      Priority.high,
      Priority.normal,
      Priority.low,
      Priority.normal,
    ][i % 4],
    labels: Set.unmodifiable({Label.values[i % 3]}),
    done: i >= 30,
    reminder: i % 4 == 0,
    reminderMinute: 9 * 60 + 30,
  ),
);

List<TimeEntry> seedEntries() {
  final monday = mondayOf(studyToday);
  final entries = <TimeEntry>[];
  for (final offset in [-7, 0]) {
    for (var day = 0; day < 5; day++) {
      for (var shift = 0; shift < 2; shift++) {
        final index = (day * 3 + shift + (offset == 0 ? 0 : 14));
        // Friday's two studio sessions are already on the books at 10:00.
        final start = shift == 0
            ? 9 * 60
            : offset == 0 && day == 4
            ? 7 * 60
            : 13 * 60 + 30;
        entries.add((
          id: 'log-${entries.length + 1}',
          date: addDays(monday, offset + day),
          start: start,
          end: start + [90, 60, 135, 105, 75, 45, 120][index % 7],
          project: projects[index % 3].id,
          note: _titles[index],
        ));
      }
    }
  }
  return entries;
}

const teammateTimers = {
  'sam': 'ST-102',
  'noor': 'ST-103',
  'inez': 'ST-104',
  'leo': 'ST-105',
};

List<StudioEvent> seedActivity() => [
  for (final (person, kind, title, time, minutes) in [
    ('inez', ActivityKind.logged, 13, 600, 120),
    ('leo', ActivityKind.commented, 4, 585, 0),
    ('inez', ActivityKind.started, 3, 577, 0),
    ('inez', ActivityKind.finished, 38, 565, 0),
    ('noor', ActivityKind.started, 2, 544, 0),
    ('sam', ActivityKind.commented, 1, 521, 0),
    ('maya', ActivityKind.started, 0, 498, 0),
  ])
    (
      person: person,
      kind: kind,
      subject: _titles[title],
      at: atMinute(studyToday, time),
      minutes: minutes,
    ),
];
