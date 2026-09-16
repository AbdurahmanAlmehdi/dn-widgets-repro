import 'package:dartnative/dartnative.dart';

import '../dartnative_plugin_registrant.dart';

/// `AnnotatedRegion<SystemUiOverlayStyle>` around a Scaffold, exactly as the
/// AnnotatedRegion API doc shows it. `--dart-define=WRAP=false` runs the same
/// Scaffold without the region.
///
///   dn run -t lib/cases/annotated_region.dart [--dart-define=WRAP=false]
const wrap = bool.fromEnvironment('WRAP', defaultValue: true);

void main() {
  DartNativePluginRegistrant.registerAll();
  const screen = Scaffold(
    backgroundColor: Color(0xFFB85C1A),
    body: Center(
      child: Text(
        'Scaffold body',
        style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 24),
      ),
    ),
  );
  runApp(
    wrap
        ? const AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: screen,
          )
        : screen,
  );
}
