import 'package:flutter/widgets.dart';

import 'src/app/app.dart';
import 'src/platform/designer_target.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppUiDesignerApp(target: DesignerTarget.current));
}
