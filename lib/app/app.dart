import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/input/presentation/input_page.dart';
import '../features/plan/application/app_state.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Career Plan AI',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF9FAFB), // Swiss Spa wall color
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2C2C2C), // Deep professional grey
            primary: const Color(0xFF2C2C2C),
            surface: Colors.white,
            background: const Color(0xFFF9FAFB),
            secondary: const Color(0xFF6B7280), // Muted grey for secondary 1
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            scrolledUnderElevation: 0,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
            iconTheme: IconThemeData(color: Color(0xFF111827)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF111827), width: 1.5),
            ),
            labelStyle: const TextStyle(color: Color(0xFF6B7280)),
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withOpacity(0.1)),
            ),
            margin: EdgeInsets.zero,
          ),
          dividerTheme: DividerThemeData(
            color: Colors.grey.withOpacity(0.1),
            thickness: 1,
            space: 1,
          ),
          typography: Typography.material2021(),
        ),
        home: const InputPage(),
      ),
    );
  }
}
