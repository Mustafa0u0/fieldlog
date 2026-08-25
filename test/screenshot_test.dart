@Tags(['screenshot'])
library;

import 'dart:io';

import 'package:fieldlog/models/inspection.dart';
import 'package:fieldlog/screens/new_inspection_screen.dart';
import 'package:fieldlog/theme.dart';
import 'package:fieldlog/widgets/inspection_tile.dart';
import 'package:fieldlog/widgets/queue_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outbox_queue/outbox_queue.dart';

/// Renders the screens to PNG so the README shows the real thing.
///
/// A real font has to be loaded first. The default test font draws every glyph
/// as a filled rectangle — deliberately, so that golden comparisons do not
/// break when a platform ships a new font version. That is right for
/// regression testing and useless for a screenshot, so these load Roboto.
///
/// Run with: flutter test --tags screenshot --update-goldens
Future<void> _load(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final name in files) {
    final file = File('test/fonts/$name');
    if (!file.existsSync()) continue;
    loader.addFont(
        file.readAsBytes().then((bytes) => ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _loadFonts() async {
  await _load(
      'Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
  // Without this every icon is a filled square, which is exactly what the
  // banner and the button are trying not to be.
  await _load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

/// The screenshots pin the family so the loaded Roboto is actually used; the
/// app itself keeps the platform default, which is the right choice on device.
ThemeData _forRender(ThemeData theme) => theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle:
            theme.appBarTheme.titleTextStyle?.copyWith(fontFamily: 'Roboto'),
      ),
      // A theme that sets its own textStyle does not inherit the family above,
      // so the button label would render as a filled box while everything
      // around it read correctly.
      filledButtonTheme: FilledButtonThemeData(
        style: theme.filledButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(
            (theme.filledButtonTheme.style?.textStyle?.resolve({}) ??
                    const TextStyle())
                .copyWith(fontFamily: 'Roboto'),
          ),
        ),
      ),
    );

void main() {
  setUpAll(_loadFonts);

  final inspections = [
    Inspection(
      id: '1',
      site: 'Coop 2 · North shed',
      condition: Condition.urgent,
      note: 'Water line frozen at the far end. Birds crowding the near feeder.',
      recordedAt: DateTime(2026, 1, 14, 7, 5),
    ),
    Inspection(
      id: '2',
      site: 'Coop 1',
      condition: Condition.attention,
      note: 'Feeder motor sounds rough. Still turning.',
      recordedAt: DateTime(2026, 1, 14, 6, 48),
    ),
    Inspection(
      id: '3',
      site: 'Store',
      condition: Condition.ok,
      note: '',
      recordedAt: DateTime(2026, 1, 14, 6, 30),
    ),
  ];

  for (final brightness in Brightness.values) {
    final name = brightness.name;

    testWidgets('round — $name', (tester) async {
      tester.view.physicalSize = const Size(1170, 2200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: _forRender(buildTheme(brightness)),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(title: const Text('Today')),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: QueueBanner(
                stats:
                    const OutboxStats(pending: 2, waiting: 1, deadLettered: 0),
                onSync: () {},
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final inspection in inspections)
                    InspectionTile(inspection: inspection),
                ],
              ),
            ),
          ]),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Inspection'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden/round-$name.png'),
      );
    });

    testWidgets('capture — $name', (tester) async {
      tester.view.physicalSize = const Size(1170, 2200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: _forRender(buildTheme(brightness)),
        debugShowCheckedModeBanner: false,
        home: const NewInspectionScreen(),
      ));
      await tester.enterText(
          find.byType(TextField).first, 'Coop 2 · North shed');
      await tester.tap(find.text('Needs attention'));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden/capture-$name.png'),
      );
    });
  }

  tearDownAll(() {
    final dir = Directory('test/golden');
    if (dir.existsSync()) {
      stdout.writeln('golden files: ${dir.listSync().length}');
    }
  });
}
