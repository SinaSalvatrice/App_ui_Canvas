import '../model/app_ui_project.dart';
import '../platform/designer_target.dart';

class ExportResult {
  const ExportResult({required this.files, this.warnings = const []});

  final Map<String, String> files;
  final List<String> warnings;
}

abstract interface class AppShellExporter {
  DesignerTarget get target;
  ExportResult generate(AppUiProject project);
}
