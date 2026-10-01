import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../editor/editor_controller.dart';
import '../editor/editor_shell.dart';
import '../model/app_ui_project.dart';
import '../platform/designer_target.dart';
import '../project/project_file_service.dart';
import '../project/project_session_store.dart';

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
  final ProjectSessionStore _session = ProjectSessionStore();

  String? _projectPath;
  List<String> _recentProjects = const [];
  bool _closing = false;
  Timer? _autosaveTimer;

  @override
  void initState() {
    super.initState();
    controller = EditorController(AppUiProject.empty(widget.target));
    controller.addListener(_scheduleRecovery);

    if (Platform.isWindows) {
      windowManager.addListener(this);
    }

    _loadRecentProjects();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkRecovery());
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    controller.removeListener(_scheduleRecovery);
    if (Platform.isWindows) {
      windowManager.removeListener(this);
    }
    controller.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() {
    _handleWindowClose();
  }

  Future<void> _loadRecentProjects() async {
    final recent = await _session.loadRecentProjects();
    if (!mounted) return;
    setState(() => _recentProjects = recent);
  }

  Future<void> _rememberRecent(String path) async {
    final recent = await _session.rememberRecentProject(path);
    if (!mounted) return;
    setState(() => _recentProjects = recent);
  }

  void _scheduleRecovery() {
    if (!controller.isDirty) return;
    if (_autosaveTimer?.isActive ?? false) return;

    _autosaveTimer = Timer(
      const Duration(seconds: 3),
      () async {
        if (!controller.isDirty) return;
        try {
          await _session.writeRecovery(
            project: controller.project,
            target: widget.target,
            sourcePath: _projectPath,
          );
        } catch (_) {
          // Recovery failure must never interrupt editing.
        }
      },
    );
  }

  Future<void> _clearRecovery() async {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    try {
      await _session.clearRecovery(widget.target);
    } catch (_) {
      // A cleanup failure should not block save/close.
    }
  }

  Future<void> _checkRecovery() async {
    final recovery = await _session.loadRecovery(widget.target);
    if (recovery == null || !mounted) return;

    if (recovery.project.target != widget.target) {
      await _clearRecovery();
      return;
    }

    final sourcePath = recovery.sourcePath;
    if (sourcePath != null) {
      final source = File(sourcePath);
      if (await source.exists()) {
        final modified = await source.lastModified();
        if (!recovery.savedAt.isAfter(modified)) {
          await _clearRecovery();
          return;
        }
      }
    }

    final recover = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Recovery found'),
        content: Text(
          'An autosaved version of "${recovery.project.name}" from '
          '${_formatRecoveryTime(recovery.savedAt)} was found.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard recovery'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Recover'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (recover != true) {
      await _clearRecovery();
      return;
    }

    controller.replaceProject(
      recovery.project,
      markClean: false,
    );

    String? recoveredPath;
    if (recovery.sourcePath case final path?) {
      if (await File(path).exists()) {
        recoveredPath = path;
        await _rememberRecent(path);
      }
    }
    if (mounted) {
      setState(() => _projectPath = recoveredPath);
    }
  }

  String _formatRecoveryTime(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _handleWindowClose() async {
    if (_closing || !mounted) return;

    if (!controller.isDirty) {
      await _clearRecovery();
      _closing = true;
      await windowManager.destroy();
      return;
    }

    final choice = await _askUnsavedChanges();
    if (!mounted || choice == _UnsavedChoice.cancel) return;

    if (choice == _UnsavedChoice.save) {
      final saved = await _saveProject();
      if (!saved) return;
    } else {
      await _clearRecovery();
    }

    _closing = true;
    await windowManager.destroy();
  }

  Future<void> _newProject() async {
    if (!await _canReplaceProject()) return;
    await _clearRecovery();
    controller.replaceProject(AppUiProject.empty(widget.target));
    setState(() => _projectPath = null);
  }

  Future<void> _openProject() async {
    if (!await _canReplaceProject()) return;

    try {
      final opened = await _files.openProject();
      if (opened == null || !mounted) return;
      await _activateOpenedProject(opened);
    } catch (error) {
      _showError('Could not open project: $error');
    }
  }

  Future<void> _openRecentProject(String path) async {
    if (!await _canReplaceProject()) return;

    try {
      if (!await File(path).exists()) {
        final recent = await _session.removeRecentProject(path);
        if (mounted) {
          setState(() => _recentProjects = recent);
          _showError('Recent project no longer exists.');
        }
        return;
      }

      final opened = await _files.openProjectPath(path);
      if (!mounted) return;
      await _activateOpenedProject(opened);
    } catch (error) {
      _showError('Could not open project: $error');
    }
  }

  Future<void> _activateOpenedProject(OpenedAppUiProject opened) async {
    if (opened.project.target != widget.target) {
      _showError(
        'This project targets ${opened.project.target.label}. '
        'Open it with the ${opened.project.target.label} build of App UI Canvas.',
      );
      return;
    }

    await _clearRecovery();
    controller.replaceProject(opened.project);
    setState(() => _projectPath = opened.path);
    await _rememberRecent(opened.path);
  }

  Future<bool> _saveProject() async {
    try {
      final currentPath = _projectPath;
      if (currentPath == null) return _saveProjectAs();

      await _files.saveProject(controller.project, currentPath);
      controller.markClean();
      await _clearRecovery();
      await _rememberRecent(currentPath);
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
      await _clearRecovery();
      await _rememberRecent(path);
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
      await _clearRecovery();
      await SystemNavigator.pop();
      return;
    }

    final choice = await _askUnsavedChanges();
    if (!mounted || choice == _UnsavedChoice.cancel) return;
    if (choice == _UnsavedChoice.save) {
      if (!await _saveProject()) return;
    } else {
      await _clearRecovery();
    }
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
            recentProjects: _recentProjects,
            onNewProject: _newProject,
            onOpenProject: _openProject,
            onOpenRecentProject: _openRecentProject,
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
