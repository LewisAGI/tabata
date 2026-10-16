import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/store.dart';
import 'services/device_cues.dart';
import 'services/wake.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = TabataStore(PrefsBox(prefs));
  await store.ensureSeed();
  runApp(TabataApp(store: store, cues: DeviceCues(), wake: PlusWake()));
}
