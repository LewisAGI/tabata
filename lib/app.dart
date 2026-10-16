import 'package:flutter/material.dart';

import 'data/store.dart';
import 'screens/home_screen.dart';
import 'screens/scope.dart';
import 'services/cues.dart';
import 'services/wake.dart';
import 'theme/app_theme.dart';

class TabataApp extends StatelessWidget {
  const TabataApp({
    super.key,
    required this.store,
    required this.cues,
    required this.wake,
    this.home,
  });

  final TabataStore store;
  final CueSink cues;
  final WakeLock wake;
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return TabataScope(
      store: store,
      cues: cues,
      wake: wake,
      child: MaterialApp(
        title: 'Tabata',
        theme: buildTheme(),
        debugShowCheckedModeBanner: false,
        home: home ?? const HomeScreen(),
      ),
    );
  }
}
