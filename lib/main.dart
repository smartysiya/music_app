import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'widgets/main_shell.dart';
import 'package:provider/provider.dart';
import 'providers/playback_provider.dart';
import 'providers/user_provider.dart';
import 'providers/feature_provider.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlaybackProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FeatureProvider()),
      ],
      child: const MusicApp(),
    ),
  );
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        fontFamily: 'Segoe UI', // Using a generic sans-serif
      ),
      home: const MainShell(),
    );
  }
}
