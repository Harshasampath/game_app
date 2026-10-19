import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/system/app_system_ui.dart';
import 'game/audio/game_audio.dart';
import 'presentation/flame_app_shell.dart';
import 'presentation/providers/dependency_providers.dart';
import 'presentation/screens/splash_screen.dart';

class NebulaStrikeScreen extends StatefulWidget {
  const NebulaStrikeScreen({super.key});

  @override
  State<NebulaStrikeScreen> createState() => _NebulaStrikeScreenState();
}

class _NebulaStrikeScreenState extends State<NebulaStrikeScreen> {
  late Future<SharedPreferences> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeGame();
  }

  Future<SharedPreferences> _initializeGame() async {
    await AppSystemUi.configurePortrait();
    await GameAudio.preload();
    return await SharedPreferences.getInstance();
  }

  void _restoreOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _restoreOrientation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _restoreOrientation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF060A14),
        body: FutureBuilder<SharedPreferences>(
          future: _initFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF74C0FC),
                ),
              );
            }

            return ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(snapshot.data!),
              ],
              child: const SplashGate(
                child: FlameAppShell(),
              ),
            );
          },
        ),
      ),
    );
  }
}
