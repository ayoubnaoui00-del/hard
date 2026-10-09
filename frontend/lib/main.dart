import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/router.dart';
import 'config/theme.dart';
import 'viewmodels/auth/auth_session_viewmodel.dart';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    HttpOverrides.global = DevHttpOverrides();
  }
  runApp(
    const ProviderScope(
      child: GymTrackApp(),
    ),
  );
}

class GymTrackApp extends ConsumerStatefulWidget {
  const GymTrackApp({super.key});

  @override
  ConsumerState<GymTrackApp> createState() => _GymTrackAppState();
}

class _GymTrackAppState extends ConsumerState<GymTrackApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authSessionViewModelProvider.notifier).initializeSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Hard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
