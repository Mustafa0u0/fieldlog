import 'package:fieldlog/models/inspection.dart';
import 'package:fieldlog/screens/new_inspection_screen.dart';
import 'package:fieldlog/theme.dart';
import 'package:fieldlog/widgets/inspection_tile.dart';
import 'package:fieldlog/widgets/queue_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outbox_queue/outbox_queue.dart';

Widget _wrap(Widget child, Brightness brightness) => MaterialApp(
      theme: buildTheme(brightness),
      home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('the banner distinguishes waiting from retrying', (tester) async {
    await tester.pumpWidget(_wrap(
      QueueBanner(
        stats: const OutboxStats(pending: 2, waiting: 1, deadLettered: 0),
        onSync: () {},
      ),
      Brightness.light,
    ));

    expect(find.textContaining('2 to send'), findsOneWidget);
    expect(find.textContaining('1 retrying shortly'), findsOneWidget);
  });

  testWidgets('a clear queue says so plainly', (tester) async {
    await tester.pumpWidget(_wrap(
      QueueBanner(
        stats: const OutboxStats(pending: 0, waiting: 0, deadLettered: 0),
        onSync: () {},
      ),
      Brightness.light,
    ));

    expect(find.text('Everything is on the server'), findsOneWidget);
  });

  testWidgets('a tile names the condition rather than only colouring it',
      (tester) async {
    await tester.pumpWidget(_wrap(
      InspectionTile(
        inspection: Inspection(
          id: '1',
          site: 'Coop 2',
          condition: Condition.urgent,
          note: 'Water line frozen.',
          recordedAt: DateTime(2026, 1, 1, 7, 5),
        ),
      ),
      Brightness.light,
    ));

    expect(find.text('Coop 2'), findsOneWidget);
    expect(find.text('Urgent'), findsOneWidget,
        reason: 'colour alone is not a label');
    expect(find.text('07:05'), findsOneWidget);
  });

  testWidgets('recording is blocked until a site is named', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: const NewInspectionScreen(),
    ));

    final button = find.widgetWithText(FilledButton, 'Record');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'North shed');
    await tester.pump();

    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('every condition explains what it means', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: const NewInspectionScreen(),
    ));

    for (final condition in Condition.values) {
      expect(find.text(condition.label), findsOneWidget);
      expect(find.text(condition.meaning), findsOneWidget,
          reason:
              '"${condition.label}" means different things to different people');
    }
  });

  testWidgets('it renders on both grounds', (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(_wrap(
        InspectionTile(
          inspection: Inspection(
            id: '1',
            site: 'Coop 2',
            condition: Condition.attention,
            note: 'Feeder jammed.',
            recordedAt: DateTime(2026, 1, 1, 7, 5),
          ),
        ),
        brightness,
      ));
      expect(tester.takeException(), isNull);
    }
  });
}
