import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabata/app.dart';
import 'package:tabata/data/store.dart';
import 'package:tabata/models/preset.dart';
import 'package:tabata/screens/editor_screen.dart';
import 'package:tabata/screens/run_screen.dart';
import 'package:tabata/services/cues.dart';
import 'package:tabata/services/wake.dart';

void main() {
  Future<TabataStore> seeded() async {
    final store = TabataStore(MemoryBox());
    await store.ensureSeed();
    return store;
  }

  Widget app(TabataStore store, {Widget? home, CueSink? cues, WakeLock? wake}) {
    return TabataApp(
      store: store,
      cues: cues ?? SilentCues(),
      wake: wake ?? NoWake(),
      home: home,
    );
  }

  testWidgets('home lists the seeded preset', (tester) async {
    final store = await seeded();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    expect(find.text('Tabata'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('20/10 × 8'), findsOneWidget);
  });

  testWidgets('work stepper and ruler update the number', (tester) async {
    final store = await seeded();
    await tester.pumpWidget(
      app(store, home: EditorScreen(preset: Preset.classic)),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('work-value'))).data,
      '20',
    );

    await tester.tap(find.byKey(const ValueKey('work-more')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('work-value'))).data,
      '25',
    );

    await tester.tap(find.byKey(const ValueKey('work-value')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ruler')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('ruler-value'))).data,
      '25',
    );

    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ruler')), findsNothing);
  });

  testWidgets(
    'run screen counts from the wall clock and stop logs the session',
    (tester) async {
      final store = await seeded();
      final cues = SilentCues();
      final wake = NoWake();
      final frozen = DateTime(2026, 10, 16, 8);
      await tester.pumpWidget(
        app(
          store,
          cues: cues,
          wake: wake,
          home: RunScreen(preset: Preset.classic, now: () => frozen),
        ),
      );
      await tester.pump();

      expect(find.text('PREP'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('run-seconds'))).data,
        '10',
      );
      expect(find.text('00:00.0'), findsOneWidget);
      expect(wake.enabled, isTrue);
      expect(cues.bed, isTrue);
      expect(cues.spoken, isEmpty);
      expect(cues.beeps, 1);

      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(find.byTooltip('Resume'), findsOneWidget);
      expect(wake.enabled, isFalse);
      expect(cues.bed, isFalse);

      await tester.tap(find.byTooltip('Resume'));
      await tester.pump();
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(wake.enabled, isTrue);

      await tester.tap(find.byTooltip('Stop'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Stopped early'), findsOneWidget);
      expect(find.byTooltip('Copy'), findsOneWidget);
      expect(find.byTooltip('Grok'), findsOneWidget);
      expect(find.byTooltip('Share'), findsOneWidget);
      expect(store.sessions(), hasLength(1));
      expect(store.sessions().single.completed, isFalse);
      expect(store.sessions().single.presetName, 'Classic');
      expect(wake.enabled, isFalse);

      await tester.tap(find.byTooltip('Scope'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Week').last);
      await tester.pumpAndSettle();
      expect(find.text('WEEK'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
