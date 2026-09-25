import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/pferde_provider.dart';
import 'screens/home_screen.dart';

class RossKnechtApp extends StatelessWidget {
  const RossKnechtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PferdeProvider(),
      child: MaterialApp(
        title: 'RossKnecht',
        debugShowCheckedModeBanner: false,
        locale: const Locale('de', 'DE'),
        supportedLocales: const [Locale('de', 'DE')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF6D4C41),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
