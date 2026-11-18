// Writes each traced action's frame times to build/<key>.frames.json: build times always, and raster times when
// the engine drew. A window the display isn't showing has no surface, so its frames are built but not rastered.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

Map<String, Object>? _times(
  int count,
  double Function() average,
  double Function(double) percentile,
  double Function() worst,
  int Function() over,
) => count == 0
    ? null
    : {
        'frames': count,
        'average': average(),
        'p90': percentile(90),
        'p99': percentile(99),
        'worst': worst(),
        'over16ms': over(),
      };

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    for (final MapEntry(:key, :value) in data.entries) {
      final report = value as Map<String, dynamic>;
      // watchPerformance reports engine FrameTiming summaries on the web,
      // where a VM timeline connection is unavailable.
      if (report.containsKey('frame_count')) {
        await File('build/$key.frames.json')
            .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
        continue;
      }
      final s = driver.TimelineSummary.summarize(
        driver.Timeline.fromJson(report),
      );
      final frames = {
        'build': _times(
          s.countFrames(),
          s.computeAverageFrameBuildTimeMillis,
          s.computePercentileFrameBuildTimeMillis,
          s.computeWorstFrameBuildTimeMillis,
          s.computeMissedFrameBuildBudgetCount,
        ),
        'raster': _times(
          s.countRasterizations(),
          s.computeAverageFrameRasterizerTimeMillis,
          s.computePercentileFrameRasterizerTimeMillis,
          s.computeWorstFrameRasterizerTimeMillis,
          s.computeMissedFrameRasterizerBudgetCount,
        ),
      };
      await File('build/$key.frames.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(frames));
    }
  },
);
