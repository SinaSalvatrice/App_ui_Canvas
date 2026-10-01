import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../model/app_ui_project.dart';

class OpenedAppUiProject {
  const OpenedAppUiProject({
    required this.project,
    required this.path,
  });

  final AppUiProject project;
  final String path;
}

class ProjectFileService {
  static const _typeGroup = XTypeGroup(
    label: 'App UI Canvas project',
    extensions: <String>['appui'],
  );

  Future<OpenedAppUiProject?> openProject() async {
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[_typeGroup],
    );
    if (file == null) return null;

    final contents = await file.readAsString();
    final decoded = jsonDecode(contents);
    if (decoded is! Map) {
      throw const FormatException('Invalid .appui project root.');
    }

    return OpenedAppUiProject(
      project: AppUiProject.fromJson(
        Map<String, Object?>.from(decoded),
      ),
      path: file.path,
    );
  }

  Future<String?> saveProjectAs(AppUiProject project) async {
    final suggestedName = _fileNameFor(project);

    if (Platform.isWindows) {
      final location = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: const <XTypeGroup>[_typeGroup],
      );
      if (location == null) return null;
      final path = _withExtension(location.path);
      await _write(project, path);
      return path;
    }

    if (Platform.isAndroid) {
      final directory = await getDirectoryPath();
      if (directory == null) return null;
      final separator =
          directory.endsWith(Platform.pathSeparator) ? '' : Platform.pathSeparator;
      final path = '$directory$separator$suggestedName';
      await _write(project, path);
      return path;
    }

    throw UnsupportedError('Only Windows and Android are supported.');
  }

  Future<void> saveProject(AppUiProject project, String path) =>
      _write(project, _withExtension(path));

  Future<void> _write(AppUiProject project, String path) async {
    final json = const JsonEncoder.withIndent('  ').convert(project.toJson());
    final bytes = Uint8List.fromList(utf8.encode('$json\n'));
    final file = XFile.fromData(
      bytes,
      mimeType: 'application/json',
      name: _basename(path),
    );
    await file.saveTo(path);
  }

  String _fileNameFor(AppUiProject project) =>
      '${_safeName(project.name)}.appui';

  String _withExtension(String path) =>
      path.toLowerCase().endsWith('.appui') ? path : '$path.appui';

  String _safeName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? 'untitled' : cleaned;
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.substring(normalized.lastIndexOf('/') + 1);
  }
}
