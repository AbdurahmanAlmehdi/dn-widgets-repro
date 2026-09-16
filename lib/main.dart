import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';

/// Red band after a root swap — minimal case.
///
/// The root swaps its only child from A to B, and A calls setState in the
/// same turn (a login button's `finally` resetting its spinner). DartNative
/// then builds A after its dispose(). Flutter never does; Riverpod's
/// ConsumerState throws there ("Using ref after the widget was disposed"),
/// and A's build below throws the same way. DartNative puts a red
/// placeholder in A's slot, and it stays on screen over B.
///
/// `--dart-define=THROW=false` only logs the late build: no band, but the
/// log shows the build still happens.
const throwAfterDispose = bool.fromEnvironment('THROW', defaultValue: true);

const _ink = TextStyle(color: Color(0xFF111111), fontSize: 17);

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const SwapRoot());
}

class SwapRoot extends StatefulWidget {
  const SwapRoot({super.key});

  @override
  State<SwapRoot> createState() => _SwapRootState();
}

class _SwapRootState extends State<SwapRoot> {
  bool _showB = false;

  @override
  Widget build(BuildContext context) {
    if (_showB) return const RootB();
    return RootA(onDone: () => setState(() => _showB = true));
  }
}

class RootA extends StatefulWidget {
  const RootA({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<RootA> createState() => _RootAState();
}

class _RootAState extends State<RootA> {
  bool _disposed = false;
  int _taps = 0;

  void _tap() {
    widget.onDone();
    setState(() => _taps++);
  }

  @override
  void dispose() {
    print('RootA dispose');
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_disposed) {
      print('RootA build after dispose (taps $_taps)');
      if (throwAfterDispose) throw StateError('RootA built after dispose()');
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Root A', style: _ink),
            const SizedBox(height: 16),
            Button(title: 'Swap to B', onPressed: _tap),
          ],
        ),
      ),
    );
  }
}

class RootB extends StatelessWidget {
  const RootB({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Center(child: Text('Root B', style: _ink)),
    );
  }
}
