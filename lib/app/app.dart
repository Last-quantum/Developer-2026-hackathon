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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const InputPage(),
      ),
    );
  }
}
