import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabata/app.dart';
import 'package:tabata/data/store.dart';
import 'package:tabata/models/preset.dart';
import 'package:tabata/models/session_log.dart';
import 'package:tabata/screens/editor_screen.dart';
import 'package:tabata/services/cues.dart';
import 'package:tabata/services/wake.dart';
import 'package:tabata/theme/app_theme.dart';
import 'package:tabata/widgets/complete_sheet.dart';
import 'package:tabata/widgets/run_view.dart';

const _shots = bool.fromEnvironment('SCREENSHOTS');

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadScreenshotFonts();
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    if (!_shots) {
      return;
    }
    await expectLater(
      find.byKey(const ValueKey('frame')),
      matchesGoldenFile('../docs/screenshots/$name.png'),
    );
  }

  Widget frame({Widget? home, TabataStore? store}) {
    return RepaintBoundary(
      key: const ValueKey('frame'),
      child: TabataApp(
        store: store ?? TabataStore(MemoryBox()),
        cues: SilentCues(),
        wake: NoWake(),
        home: home,
      ),
    );
  }

  testWidgets('presets screen', (tester) async {
    phone(tester);
    final store = TabataStore(MemoryBox());
    await store.savePreset(Preset.classic);
    await store.savePreset(
      const Preset(
        id: 'morning',
        name: 'Morning',
        prep: 5,
        work: 40,
        rest: 20,
        rounds: 6,
        sets: 3,
        setRest: 60,
        cooldown: 0,
      ),
    );
    await tester.pumpWidget(frame(store: store));
    await tester.pumpAndSettle();
    expect(find.text('20/10 × 8'), findsOneWidget);
    expect(find.text('40/20 × 6 · 3'), findsOneWidget);
    await shoot(tester, 'presets');
  });

  testWidgets('editor and ruler', (tester) async {
    phone(tester);
    await tester.pumpWidget(frame(home: EditorScreen(preset: Preset.classic)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('work-value')), findsOneWidget);
    await shoot(tester, 'editor');
    await tester.tap(find.byKey(const ValueKey('work-value')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ruler')), findsOneWidget);
    await shoot(tester, 'ruler');
  });

  testWidgets('running countdown', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      frame(
        home: Scaffold(
          backgroundColor: AppColors.workTint,
          body: RunView(
            label: 'ROUND 3/8 · WORK',
            seconds: 3,
            progress: 0.85,
            elapsed: Duration(milliseconds: 6600),
            paused: false,
            tint: AppColors.workTint,
            ring: AppColors.accent,
            onPause: _noop,
            onStop: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ROUND 3/8 · WORK'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('run-seconds'))).data,
      '3',
    );
    await shoot(tester, 'running');

    await tester.pumpWidget(
      frame(
        home: Scaffold(
          backgroundColor: AppColors.restTint,
          body: RunView(
            label: 'ROUND 3/8 · REST',
            seconds: 8,
            progress: 0.2,
            elapsed: Duration(seconds: 46),
            paused: false,
            tint: AppColors.restTint,
            ring: Color(0xFF64748B),
            onPause: _noop,
            onStop: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ROUND 3/8 · REST'), findsOneWidget);
    await shoot(tester, 'rest');
  });

  testWidgets('session complete sheet', (tester) async {
    phone(tester);
    final started = DateTime(2026, 10, 16, 8, 41);
    final log = SessionLog.capture(
      preset: Preset.classic,
      startedAt: started,
      endedAt: started.add(const Duration(minutes: 4)),
      elapsed: const Duration(minutes: 4),
      completed: true,
    );
    await tester.pumpWidget(frame(home: _SheetHost(log: log)));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('4:00'), findsOneWidget);
    await shoot(tester, 'complete');
  });
}

Future<void> _loadScreenshotFonts() async {
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
  const wanted = {'Roboto', 'MaterialIcons'};
  final loaded = <String>{};
  for (final entry in manifest) {
    final family = entry['family'] as String;
    if (!wanted.contains(family)) {
      continue;
    }
    final loader = FontLoader(family);
    for (final face in entry['fonts'] as List) {
      loader.addFont(rootBundle.load(face['asset'] as String));
    }
    await loader.load();
    loaded.add(family);
  }
  if (!loaded.containsAll(wanted)) {
    throw StateError('Screenshot fonts missing: ${wanted.difference(loaded)}');
  }
}

void _noop() {}

class _SheetHost extends StatefulWidget {
  const _SheetHost({required this.log});

  final SessionLog log;

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showCompleteSheet(context, log: widget.log, history: [widget.log]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: AppColors.workTint);
  }
}
