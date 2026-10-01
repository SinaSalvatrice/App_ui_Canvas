import 'dart:convert';

import '../model/app_ui_project.dart';
import '../platform/designer_target.dart';
import 'exporter.dart';

class FlutterShellExporter implements AppShellExporter {
  const FlutterShellExporter(this.target);

  @override
  final DesignerTarget target;

  @override
  ExportResult generate(AppUiProject project) {
    if (project.target != target) {
      throw StateError('Project target and exporter target differ.');
    }

    final manifest = const JsonEncoder.withIndent('  ').convert(project.toJson());
    return ExportResult(
      files: {
        'app_ui_manifest.json': manifest,
        'lib/generated/app_ui_generated_app.dart': _generatedApp(project),
        'lib/app_logic/app_actions.dart': _actionHooks(),
      },
      warnings: const [
        'Foundation exporter only. Full widget generation is a later milestone.',
      ],
    );
  }

  String _generatedApp(AppUiProject project) {
    final names = project.screens.map((s) => "'${s.name}'").join(', ');
    return '''// GENERATED FILE - DO NOT EDIT.
const appUiProjectName = ${jsonEncode(project.name)};
const appUiTarget = ${jsonEncode(project.target.name)};
const appUiScreens = <String>[$names];
''';
  }

  String _actionHooks() => '''// USER CODE - never overwrite after first export.
abstract class AppActions {
  Future<void> invoke(String actionId, Map<String, Object?> arguments);
}
''';
}
