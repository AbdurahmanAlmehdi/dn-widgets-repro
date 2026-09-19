import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';

/// Short content in a SingleChildScrollView inside Center: the usual way to
/// centre a form that must still scroll with the keyboard up.
/// `--dart-define=SCROLL=false` runs the same Center > Column without the
/// scroll view.
///
///   dn run [--dart-define=SCROLL=false]
const scroll = bool.fromEnvironment('SCROLL', defaultValue: true);

const _ink = TextStyle(color: Color(0xFF111111), fontSize: 20);

void main() {
  DartNativePluginRegistrant.registerAll();
  const column = Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('Line one', style: _ink),
      SizedBox(height: 16),
      Text('Line two', style: _ink),
      SizedBox(height: 16),
      Text('Line three', style: _ink),
    ],
  );
  runApp(
    const Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Center(
        child: scroll
            ? SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: column,
              )
            : column,
      ),
    ),
  );
}
