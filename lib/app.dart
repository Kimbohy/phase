import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'providers.dart';

const _onboardingKey = 'onboarding_done';

class PhaseApp extends ConsumerStatefulWidget {
  const PhaseApp({super.key});

  @override
  ConsumerState<PhaseApp> createState() => _PhaseAppState();
}

class _PhaseAppState extends ConsumerState<PhaseApp> {
  late bool _onboardingDone;

  @override
  void initState() {
    super.initState();
    _onboardingDone =
        ref.read(sharedPreferencesProvider).getBool(_onboardingKey) ?? false;
  }

  Future<void> _finishOnboarding() async {
    await ref.read(sharedPreferencesProvider).setBool(_onboardingKey, true);
    setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      home: _onboardingDone
          ? const HomeShell()
          : OnboardingScreen(onDone: _finishOnboarding),
    );
  }
}
