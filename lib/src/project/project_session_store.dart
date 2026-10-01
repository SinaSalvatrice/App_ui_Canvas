import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../model/app_ui_project.dart';
import '../platform/designer_target.dart';

class RecoverySnapshot {
  const RecoverySnapshot({
    required this.project,
    required this.savedAt,
    this.sourcePath,
  });

  final AppUiProject project;
  final DateTime savedAt;
  final String? sourcePath;
}

class ProjectSessionStore {
  static const _settingsFileName = 'session.json';
  static const _maxRecentProjects = 8;

  Future<List<String>> loadRecentProjects() async {
    final settings = await _readSettings();
    final raw = settings['recentProjects'];
    if (raw is! List) return const [];

    final existing = <String>[];
    for (final item in raw) {
      if (item is! String || existing.contains(item)) continue;
      if (await File(item).exists()) {
        existing.add(item);
      }
      if (existing.length >= _maxRecentProjects) break;
    }

    if (existing.length != raw.length) {
      await _writeSettings(<String, Object?>{
        ...settings,
        'recentProjects': existing,
      });
    }
    return existing;
  }

  Future<List<String>> rememberRecentProject(String path) async {
    final settings = await _readSettings();
    final current = ((settings['recentProjects'] as List?) ?? const [])
        .whereType<String>()
        .where((item) => item != path)
        .toList();

    final next = <String>[path, ...current];
    if (next.length > _maxRecentProjects) {
      next.removeRange(_maxRecentProjects, next.length);
    }

    await _writeSettings(<String, Object?>{
      ...settings,
      'recentProjects': next,
    });
    return next;
  }

  Future<List<String>> removeRecentProject(String path) async {
    final settings = await _readSettings();
    final next = ((settings['recentProjects'] as List?) ?? const [])
        .whereType<String>()
        .where((item) => item != path)
        .toList();

    await _writeSettings(<String, Object?>{
      ...settings,
      'recentProjects': next,
    });
    return next;
  }

  Future<void> writeRecovery({
    required AppUiProject project,
    required DesignerTarget target,
    String? sourcePath,
  }) async {
    final file = await _recoveryFile(target);
    await file.parent.create(recursive: true);
    final payload = <String, Object?>{
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      if (sourcePath != null) 'sourcePath': sourcePath,
      'project': project.toJson(),
    };
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
      flush: true,
    );
  }

  Future<RecoverySnapshot?> loadRecovery(DesignerTarget target) async {
    final file = await _recoveryFile(target);
    if (!await file.exists()) return null;

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      final map = Map<String, Object?>.from(decoded);
      final projectJson = map['project'];
      if (projectJson is! Map) return null;

      return RecoverySnapshot(
        project: AppUiProject.fromJson(
          Map<String, Object?>.from(projectJson),
        ),
        savedAt: DateTime.parse(map['savedAt']! as String).toLocal(),
        sourcePath: map['sourcePath'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearRecovery(DesignerTarget target) async {
    final file = await _recoveryFile(target);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Map<String, Object?>> _readSettings() async {
    final file = await _settingsFile();
    if (!await file.exists()) return <String, Object?>{};

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) {
        return Map<String, Object?>.from(decoded);
      }
    } catch (_) {
      // A damaged settings file should never prevent the editor from opening.
    }
    return <String, Object?>{};
  }

  Future<void> _writeSettings(Map<String, Object?> settings) async {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(settings)}\n',
      flush: true,
    );
  }

  Future<File> _settingsFile() async {
    final directory = await getApplicationSupportDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}$_settingsFileName',
    );
  }

  Future<File> _recoveryFile(DesignerTarget target) async {
    final directory = await getApplicationSupportDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}'
      'recovery_${target.name}.json',
    );
  }
}
