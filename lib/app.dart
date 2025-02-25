
import 'package:comisc_creator/src/ui/home/home_page.dart';
import 'package:flutter/material.dart';

import 'config/palette.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'ComicNeue',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Palette.orange,
        appBarTheme: const AppBarTheme(
          backgroundColor: Palette.orangeDark,
          elevation: 0,
          foregroundColor: Palette.white,
        ),
      ),
      // darkTheme: ThemeData(
      //   fontFamily: 'ComicNeue',
      //   colorScheme: ColorScheme.fromSeed(
      //     seedColor: Colors.orange,
      //     brightness: Brightness.dark,
      //   ),
      //   appBarTheme: const AppBarTheme(
      //     backgroundColor: Palette.orangeDark,
      //     elevation: 0,
      //     foregroundColor: Palette.white,
      //   ),
      //   useMaterial3: true,
      // ),
      themeMode: ThemeMode.light,
      home: const HomePage(),
    );
  }
}