import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/colors.dart';
import 'core/storage/hive_registrar.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive boxes and adapters
  await HiveRegistrar.init();

  runApp(
    const ProviderScope(
      child: LycorisApp(),
    ),
  );
}

class LycorisApp extends StatelessWidget {
  const LycorisApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate authentic Material You tonal palette from Spider Lily Crimson seed
    final materialYouColorScheme = ColorScheme.fromSeed(
      seedColor: LycorisColors.primaryCrimson,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF0F1216),
      surfaceContainerLowest: const Color(0xFF090B0E),
      surfaceContainerLow: const Color(0xFF13171D),
      surfaceContainer: const Color(0xFF181D24),
      surfaceContainerHigh: const Color(0xFF202630),
      surfaceContainerHighest: const Color(0xFF2A313E),
    );

    return MaterialApp(
      title: 'Lycoris',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: materialYouColorScheme,
        scaffoldBackgroundColor: materialYouColorScheme.surfaceContainerLowest,
        appBarTheme: AppBarTheme(
          backgroundColor: materialYouColorScheme.surfaceContainerLow,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: materialYouColorScheme.surfaceContainerLow,
          elevation: 3,
          indicatorColor: materialYouColorScheme.primaryContainer,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: materialYouColorScheme.onPrimaryContainer);
            }
            return IconThemeData(color: materialYouColorScheme.onSurfaceVariant);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                color: materialYouColorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              );
            }
            return TextStyle(
              color: materialYouColorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            );
          }),
        ),
        cardTheme: CardThemeData(
          color: materialYouColorScheme.surfaceContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: materialYouColorScheme.outlineVariant.withAlpha(80)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: materialYouColorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: materialYouColorScheme.outlineVariant.withAlpha(80)),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: materialYouColorScheme.primary,
          foregroundColor: materialYouColorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
