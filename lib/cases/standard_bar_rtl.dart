import 'package:dartnative/dartnative.dart';

import '../dartnative_plugin_registrant.dart';

/// Run with the device language set to Arabic (the app declares `ar` in
/// CFBundleLocalizations / android:supportsRtl). Push each screen and compare
/// where the back chevron and the action sit.
///
///   dn run -t lib/cases/standard_bar_rtl.dart
const _ink = TextStyle(color: Color(0xFF111111), fontSize: 17);

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const HomeScreen());
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [Text('START', style: _ink), SizedBox(width: 24), Text('END', style: _ink)],
            ),
            const SizedBox(height: 24),
            Button(
              title: 'System bar',
              onPressed: () => _push(context, systemBar: true),
            ),
            const SizedBox(height: 12),
            Button(
              title: 'Standard bar',
              onPressed: () => _push(context, systemBar: false),
            ),
          ],
        ),
      ),
    );
  }
}

void _push(BuildContext context, {required bool systemBar}) {
  Navigator.of(context).push<void>(
    PageRoute<void>(builder: (_) => BarScreen(systemBar: systemBar)),
  );
}

class BarScreen extends StatelessWidget {
  const BarScreen({super.key, required this.systemBar});

  final bool systemBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Text(systemBar ? 'System bar' : 'Standard bar', style: _ink),
        // A widget action keeps the bar on the standard host; the system-bar
        // screen has none, since a forced system bar with actions didn't push.
        actions: systemBar
            ? null
            : [
                GestureDetector(
                  onTap: () {},
                  child: const Text('Action', style: _ink),
                ),
              ],
        ios: AppBarIOSConfig(systemBar: systemBar),
      ),
      body: Center(
        child: Text(
          'Bar screen',
          style: _ink,
        ),
      ),
    );
  }
}
