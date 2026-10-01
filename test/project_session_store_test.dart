import 'dart:io';

import 'package:app_ui_designer/src/model/app_ui_project.dart';
import 'package:app_ui_designer/src/platform/designer_target.dart';
import 'package:app_ui_designer/src/project/project_session_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late ProjectSessionStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'app_ui_canvas_session_test_',
    );
    store = ProjectSessionStore(
      directoryProvider: () async => directory,
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('recent projects keep most recently used path first', () async {
    final first = File(
      '${directory.path}${Platform.pathSeparator}first.appui',
    );
    final second = File(
      '${directory.path}${Platform.pathSeparator}second.appui',
    );
    await first.writeAsString('{}');
    await second.writeAsString('{}');

    await store.rememberRecentProject(first.path);
    await store.rememberRecentProject(second.path);
    await store.rememberRecentProject(first.path);

    expect(
      await store.loadRecentProjects(),
      [first.path, second.path],
    );
  });

  test('missing recent projects are removed automatically', () async {
    final existing = File(
      '${directory.path}${Platform.pathSeparator}existing.appui',
    );
    await existing.writeAsString('{}');
    final missing =
        '${directory.path}${Platform.pathSeparator}missing.appui';

    await store.rememberRecentProject(missing);
    await store.rememberRecentProject(existing.path);

    expect(await store.loadRecentProjects(), [existing.path]);
  });

  test('recovery snapshot roundtrips and clears', () async {
    final project = AppUiProject.empty(DesignerTarget.windows);
    const sourcePath = r'C:\Projects\sample.appui';

    await store.writeRecovery(
      project: project,
      target: DesignerTarget.windows,
      sourcePath: sourcePath,
    );

    final recovery = await store.loadRecovery(DesignerTarget.windows);
    expect(recovery, isNotNull);
    expect(recovery!.project.name, project.name);
    expect(recovery.sourcePath, sourcePath);

    await store.clearRecovery(DesignerTarget.windows);
    expect(
      await store.loadRecovery(DesignerTarget.windows),
      isNull,
    );
  });
}
