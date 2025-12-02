import 'package:flutter/material.dart';

import '../models/planner_item.dart';
import '../services/planner_repository.dart';
import 'home_page.dart';
import 'item_form_page.dart';
import 'planner_controller.dart';

class PlannerFlutterApp extends StatefulWidget {
  const PlannerFlutterApp({super.key, required this.repository});

  final PlannerRepository repository;

  @override
  State<PlannerFlutterApp> createState() => _PlannerFlutterAppState();
}

class _PlannerFlutterAppState extends State<PlannerFlutterApp> {
  late final PlannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlannerController(repository: widget.repository);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => PlannerHomePage(controller: _controller),
      },
      onGenerateRoute: (settings) {
        if (settings.name == PlannerFormPage.routeName) {
          final args = settings.arguments as PlannerFormArguments?;
          return MaterialPageRoute<void>(
            builder: (context) => PlannerFormPage(
              controller: _controller,
              existingItem: args?.existing,
            ),
          );
        }
        return null;
      },
    );
  }
}
