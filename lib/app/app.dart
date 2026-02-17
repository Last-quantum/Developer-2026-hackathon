import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/input/presentation/input_page.dart';
import '../features/main_shell/presentation/main_app_page.dart';
import '../features/plan/application/app_state.dart';
import '../features/plan/application/local_storage_service.dart';

class MyApp extends StatelessWidget {
  final LocalStorageService storage;

  const MyApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(storage),
      child: MaterialApp(
        title: 'Career Plan AI',
        // 为了解决中文字体渲染问题，不指定特定字体，让系统自动选择最佳字体
        // 这样既能保证英文的清晰度，又能保证中文的完整性和清晰度
        theme: ThemeData(
          useMaterial3: true,
          fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'Heiti SC', 'Noto Sans CJK'],
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2C2C2C),
            primary: const Color(0xFF2C2C2C),
            surface: Colors.white,
            background: const Color(0xFFF9FAFB),
            secondary: const Color(0xFF6B7280),
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
        home: const _LandingPage(),
      ),
    );
  }
}

/// 启动时根据是否有已保存的计划，决定显示哪个页面
class _LandingPage extends StatelessWidget {
  const _LandingPage();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();

    // 如果已有恢复的计划（studyWeeks 不为空），直接进入计划页面
    if (appState.studyWeeks.isNotEmpty) {
      return const MainAppPage();
    }

    return const InputPage();
  }
}
