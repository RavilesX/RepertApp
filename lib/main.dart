import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/song_list.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const RepertApp());
}

class RepertApp extends StatelessWidget {
  const RepertApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.neonPurple,
        brightness: Brightness.dark,
        surface: AppColors.bgMid,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'RepertApp',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: base.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
      ),
      home: const SongListScreen(),
    );
  }
}
