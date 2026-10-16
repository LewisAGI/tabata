import 'package:flutter/widgets.dart';

import '../data/store.dart';
import '../services/cues.dart';
import '../services/wake.dart';

class TabataScope extends InheritedWidget {
  const TabataScope({
    super.key,
    required this.store,
    required this.cues,
    required this.wake,
    required super.child,
  });

  final TabataStore store;
  final CueSink cues;
  final WakeLock wake;

  static TabataScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TabataScope>();
    assert(scope != null, 'TabataScope is missing');
    return scope!;
  }

  /// Lookup that does not register a dependency. Safe inside [initState].
  static TabataScope read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<TabataScope>();
    final scope = element?.widget;
    assert(scope is TabataScope, 'TabataScope is missing');
    return scope! as TabataScope;
  }

  @override
  bool updateShouldNotify(TabataScope oldWidget) {
    return store != oldWidget.store ||
        cues != oldWidget.cues ||
        wake != oldWidget.wake;
  }
}
