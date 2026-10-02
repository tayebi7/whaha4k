import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'core/store.dart';
import 'core/strings.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/playlist_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();
  await Store.init();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const Waha4kApp());
}

class Waha4kApp extends StatelessWidget {
  const Waha4kApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: langNotifier,
        builder: (_, lang, __) => MaterialApp(
          key: ValueKey(lang),
          title: 'Waha 4K',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: Store.active == null
              ? const AddPlaylistScreen(first: true)
              : const HomeScreen(),
        ),
      );
}
