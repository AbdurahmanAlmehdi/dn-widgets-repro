import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';

/// Pushes a screen whose AppBar is forced onto the iOS 26 system bar
/// (`systemBar: true`). Tap each button: the screen without actions pushes;
/// with a BarButtonItem or a widget action, nothing appears and nothing is
/// logged.
///
///   dn run
const _ink = TextStyle(color: Color(0xFF111111), fontSize: 17);

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const HomeScreen());
}

enum Actions { none, barButtonItem, widget, barButtonItemDefaultHost }

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
            for (final a in Actions.values) ...[
              Button(
                title: 'Push: ${a.name}',
                onPressed: () {
                  print('push ${a.name}');
                  Navigator.of(context).push<void>(
                    PageRoute<void>(builder: (_) => BarScreen(actions: a)),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class BarScreen extends StatelessWidget {
  const BarScreen({super.key, required this.actions});

  final Actions actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Text('actions: ${actions.name}', style: _ink),
        actions: switch (actions) {
          Actions.none => null,
          Actions.barButtonItem => [
            BarButtonItem(title: 'Edit', onPressed: () {}),
          ],
          Actions.widget => [
            GestureDetector(onTap: () {}, child: const Text('Edit', style: _ink)),
          ],
          Actions.barButtonItemDefaultHost => [
            BarButtonItem(title: 'Edit', onPressed: () {}),
          ],
        },
        // The last case leaves the host to the framework's default.
        ios: actions == Actions.barButtonItemDefaultHost
            ? null
            : const AppBarIOSConfig(systemBar: true),
      ),
      body: Center(child: Text('Pushed (${actions.name})', style: _ink)),
    );
  }
}
