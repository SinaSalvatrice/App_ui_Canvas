import 'package:flutter/material.dart';

import '../editor/editor_controller.dart';
import '../editor/editor_shell.dart';
import '../model/app_ui_project.dart';
import '../platform/designer_target.dart';

class AppUiDesignerApp extends StatefulWidget {
  const AppUiDesignerApp({required this.target, super.key});

  final DesignerTarget target;

  @override
  State<AppUiDesignerApp> createState() => _AppUiDesignerAppState();
}

class _AppUiDesignerAppState extends State<AppUiDesignerApp> {
  late final EditorController controller;

  @override
  void initState() {
    super.initState();
    controller = EditorController(AppUiProject.empty(widget.target));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'App UI Designer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: EditorShell(target: widget.target, controller: controller),
      );
}
