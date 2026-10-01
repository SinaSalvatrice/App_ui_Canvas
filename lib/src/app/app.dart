import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../editor/editor_controller.dart';
import '../editor/editor_shell.dart';
import '../model/app_ui_project.dart';
import '../platform/designer_target.dart';
import '../project/project_file_service.dart';

class AppUiDesignerApp extends StatefulWidget {
  const AppUiDesignerApp({required this.target, super.key});

  final DesignerTarget target;

  @override
  State<AppUiDesignerApp> createState() => _AppUiDesignerAppState();
}

class _AppUiDesignerAppState extends State<AppUiDesignerApp>
    with WindowListener {
  late final EditorController controller;
  final ProjectFileService _files = ProjectFileService();

  String? _projectPath;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    controller = EditorController(AppUiProject.empty(widget.target));
    if (Platform.isWindows) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
    }
    controller.dispose();
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    if (_closing || !mounted) return;

    if (!controller.isDirty) {
      _closing = true;
      await windowManager.destroy();
      return;
    }

    final choice = await _askUnsavedChanges();
    if (!mounted || choice == _UnsavedChoice.cancel) return;

    if (choice == _UnsavedChoice.save) {
      final saved = await _saveProject();
      if (!saved) return;
    }

    _closing = true;
    await windowManager.destroy();
  }

  Future<void> _newProject() async {
    if (!await _canReplaceProject()) return;
    controller.replaceProject(AppUiProject.empty(widget.target));
    setState(() => _projectPath = null);
  }

  Future<void> _openProject() async {
    if (!await _canReplaceProject()) return;

    try {
      final opened = await _files.openProject();
      if (opened == null || !mounted) return;

      if (opened.project.target != widget.target) {
        _showError(
          'This project targets ${opened.project.target.label}. '
          'Open it with the ${opened.project.target.label} build of App UI Canvas.',
        );
        return;
      }

      controller.replaceProject(opened.project);
      setState(() => _projectPath = opened.path);
    } catch (error) {
      _showError('Could not open project: $error');
    }
  }

  Future<bool> _saveProject() async {
    try {
      final currentPath = _projectPath;
      if (currentPath == null) return _saveProjectAs();

      await _files.saveProject(controller.project, currentPath);
      controller.markClean();
      return true;
    } catch (error) {
      _showError('Could not save project: $error');
      return false;
    }
  }

  Future<bool> _saveProjectAs() async {
    try {
      final path = await _files.saveProjectAs(controller.project);
      if (path == null || !mounted) return false;

      setState(() => _projectPath = path);
      controller.markClean();
      return true;
    } catch (error) {
      _showError('Could not save project: $error');
      return false;
    }
  }

  Future<bool> _canReplaceProject() async {
    if (!controller.isDirty) return true;

    final choice = await _askUnsavedChanges();
    if (choice == _UnsavedChoice.cancel) return false;
    if (choice == _UnsavedChoice.discard) return true;
    return _saveProject();
  }

  Future<_UnsavedChoice> _askUnsavedChanges() async {
    if (!mounted) return _UnsavedChoice.cancel;

    final result = await showDialog<_UnsavedChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: Text(
          'Save changes to "${controller.project.name}" before continuing?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_UnsavedChoice.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_UnsavedChoice.discard),
            child: const Text("Don't save"),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_UnsavedChoice.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result ?? _UnsavedChoice.cancel;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleAndroidBack() async {
    if (!controller.isDirty) {
      await SystemNavigator.pop();
      return;
    }

    final choice = await _askUnsavedChanges();
    if (!mounted || choice == _UnsavedChoice.cancel) return;
    if (choice == _UnsavedChoice.save && !await _saveProject()) return;
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'App UI Canvas',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && Platform.isAndroid) {
              _handleAndroidBack();
            }
          },
          child: EditorShell(
            target: widget.target,
            controller: controller,
            projectPath: _projectPath,
            onNewProject: _newProject,
            onOpenProject: _openProject,
            onSaveProject: () async {
              await _saveProject();
            },
            onSaveProjectAs: () async {
              await _saveProjectAs();
            },
          ),
        ),
      );
}

enum _UnsavedChoice {
  save,
  discard,
  cancel,
}
