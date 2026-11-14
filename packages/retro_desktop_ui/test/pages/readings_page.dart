// A reading now and how it runs: one big figure and what it means, the next hours as a strip, then the days as one shape, the
// amounts as bars and the quiet facts. Its star is RetroDesktopFigureHero with RetroDesktopHourStrip under it. Copy it for anything
// measured through time: weather, power, a tide, a dose. Name the sky's kinds with `RetroDesktopSkyCondition`, or leave the strip out.
import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReadingsPage extends StatelessWidget {
  const ReadingsPage({super.key, this.onOpen});
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return RetroDesktopScaffold(
      topBar: const RetroDesktopAppBar(title: 'Right now'),
      body: RetroDesktopDesktop(
        active: 'Right now',
        tiles: [
          RetroDesktopWindowColumn(
            span: 3,
            windows: [
              RetroDesktopWindow(
                title: 'Places',
                icon: LucideIcons.mapPin,
                info: '2 places',
                statusAction: RetroDesktopButton(
                  'Add place',
                  size: RetroDesktopButtonSize.small,
                  icon: LucideIcons.plus,
                  onPressed: onOpen,
                ),
                child: RetroDesktopWell(
                  child: RetroDesktopList(
                    share: true,
                    children: [
                      RetroDesktopListTile(
                        title: 'First place',
                        subtitle: 'Showers',
                        figure: '8°',
                        leading: const Icon(LucideIcons.cloudRain, size: 18),
                        selected: true,
                        onPressed: onOpen,
                      ),
                      RetroDesktopListTile(
                        title: 'Second place',
                        subtitle: 'Cloudy',
                        figure: '10°',
                        leading: const Icon(LucideIcons.cloud, size: 18),
                        onPressed: onOpen,
                      ),
                    ],
                  ),
                ),
              ),
              const RetroDesktopWindow(
                title: 'Details',
                child: RetroDesktopDescriptionList([
                  RetroDesktopFact('Wind', '24 km/h', icon: LucideIcons.wind),
                  RetroDesktopFact(
                    'Humidity',
                    '81%',
                    icon: LucideIcons.droplets,
                  ),
                  RetroDesktopFact(
                    'Pressure',
                    '1,004 hPa',
                    icon: LucideIcons.gauge,
                  ),
                  RetroDesktopFact(
                    'Visibility',
                    '18 km',
                    icon: LucideIcons.eye,
                  ),
                ], leaders: true),
              ),
              const RetroDesktopWindow(
                title: 'Air',
                icon: LucideIcons.wind,
                child: RetroDesktopSections(
                  children: [
                    RetroDesktopReadingHead(
                      value: '28',
                      title: 'Good',
                      note: 'Nothing to mention today.',
                    ),
                    RetroDesktopScaleBar(
                      at: .14,
                      bands: [
                        'Good\n0–50',
                        'Fair\n51–100',
                        'Poor\n101–150',
                        'Bad\n151+',
                      ],
                    ),
                    RetroDesktopDivider.etched(),
                    RetroDesktopPartHead('Last 5 days', note: 'index'),
                    RetroDesktopDayBars(
                      values: [41, 52, 33, 24, 28],
                      labels: [
                        'Sat\n7',
                        'Sun\n8',
                        'Mon\n9',
                        'Tue\n10',
                        'Wed\n11',
                      ],
                      limit: 50,
                      max: 62,
                    ),
                  ],
                ),
              ),
            ],
          ),
          RetroDesktopWindowColumn(
            span: 9,
            windows: [
              RetroDesktopWindow(
                title: 'Right now',
                icon: LucideIcons.mapPin,
                info: 'Wed 11 March, 09:20',
                status: const ['High 11° at 13:00', 'Low 5° by 21:00'],
                padding: EdgeInsets.zero,
                child: RetroDesktopColumn(
                  children: [
                    const RetroDesktopFigureHero(
                      value: '8',
                      unit: '°',
                      title: 'Showers',
                      note: 'Clearing by 14:00',
                      reads: [
                        ('High', '11°', null),
                        ('Low', '4°', null),
                        ('Rain', '6.4', 'mm'),
                      ],
                      summary: 'Showers ease by midday, dry until evening, then rain again.',
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        t.desk ? 8 : 7,
                        0,
                        t.desk ? 8 : 7,
                        4,
                      ),
                      child: const RetroDesktopColumn(
                        children: [
                          RetroDesktopPartHead(
                            'Next 6 hours',
                            note: 'sky, °C, rain %',
                            open: true,
                          ),
                          RetroDesktopHourStrip(
                            hours: [
                              RetroDesktopHour(
                                label: 'Now',
                                icon: LucideIcons.cloudRain,
                                value: 8,
                                reading: '8°',
                                kind: RetroDesktopSkyCondition.rain,
                                share: .6,
                              ),
                              RetroDesktopHour(
                                label: '10',
                                icon: LucideIcons.cloudDrizzle,
                                value: 9,
                                reading: '9°',
                                kind: RetroDesktopSkyCondition.drizzle,
                                share: .5,
                              ),
                              RetroDesktopHour(
                                label: '11',
                                icon: LucideIcons.cloud,
                                value: 10,
                                reading: '10°',
                                kind: RetroDesktopSkyCondition.cloud,
                                share: .3,
                              ),
                              RetroDesktopHour(
                                label: '12',
                                icon: LucideIcons.cloudSun,
                                value: 11,
                                reading: '11°',
                                kind: RetroDesktopSkyCondition.partSun,
                                share: .1,
                              ),
                              RetroDesktopHour(
                                label: '13',
                                icon: LucideIcons.sun,
                                value: 11,
                                reading: '11°',
                                kind: RetroDesktopSkyCondition.sun,
                              ),
                              RetroDesktopHour(
                                label: '14',
                                icon: LucideIcons.sun,
                                value: 10,
                                reading: '10°',
                                kind: RetroDesktopSkyCondition.sun,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            under: const [
              RetroDesktopWindowColumn(
                span: 5,
                windows: [
                  RetroDesktopWindow(
                    title: 'Five days',
                    icon: LucideIcons.calendarDays,
                    info: 'Low to high, °C',
                    child: RetroDesktopRangeShape(
                      keyLabel: 'Rain chance, mm',
                      dry: 'dry',
                      wet: 'wet',
                      days: [
                        RetroDesktopDayRange(
                          weekday: 'Today',
                          date: '11',
                          icon: LucideIcons.cloudRain,
                          low: 4,
                          high: 11,
                          share: .8,
                          amount: '6.4',
                        ),
                        RetroDesktopDayRange(
                          weekday: 'Thu',
                          date: '12',
                          icon: LucideIcons.cloud,
                          low: 6,
                          high: 10,
                          share: .4,
                          amount: '1.2',
                        ),
                        RetroDesktopDayRange(
                          weekday: 'Fri',
                          date: '13',
                          icon: LucideIcons.sun,
                          low: 3,
                          high: 9,
                          share: .1,
                          amount: '0',
                        ),
                        RetroDesktopDayRange(
                          weekday: 'Sat',
                          date: '14',
                          icon: LucideIcons.sun,
                          low: 1,
                          high: 8,
                          amount: '0',
                        ),
                        RetroDesktopDayRange(
                          weekday: 'Sun',
                          date: '15',
                          icon: LucideIcons.cloudSun,
                          low: 2,
                          high: 9,
                          share: .2,
                          amount: '0.2',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              RetroDesktopWindowColumn(
                span: 4,
                windows: [
                  RetroDesktopWindow(
                    title: 'Rain',
                    icon: LucideIcons.umbrella,
                    info: 'Next 12 hours, mm',
                    infoEnd: '3.8 mm',
                    child: RetroDesktopHatchBars(
                      values: [.8, 1.4, .6, .2, 0, 0, 0, .1, .3, .5, .9, 1.2],
                      max: 1.5,
                      axis: ['1.5', '1.0', '0.5', '0'],
                      labels: [
                        '09',
                        '',
                        '',
                        '12',
                        '',
                        '',
                        '15',
                        '',
                        '',
                        '18',
                        '',
                        '',
                      ],
                      notes: [RetroDesktopBarNote(1, '1.4 at 10:00')],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
