import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';

/// Isolation harness for the red band (run with `dn run -t
/// lib/red_band_steps.dart`). The runApp root is a StatefulWidget that
/// replaces its one child when a button is tapped. None of the combinations
/// below shows the band: nothing here throws when built after dispose(),
/// which is the trigger `lib/main.dart` reproduces.
///
/// `--dart-define=STEP=n` adds the app's ingredients back one at a time
/// (each step keeps the previous ones):
///   1  two trivial roots: a Scaffold body with a label and a button
///   2  + a BottomNavigationBar on root B
///   3  + a TextField on root A (focus it before swapping)
///   4  + SystemChrome.setSystemUIOverlayStyle in root B's initState
///   5  + Scaffold.backgroundColor on both roots
///   6  + Scaffold.appBar on root B, pinned to the standard bar
///      (`AppBarIOSConfig(systemBar: false)`); `SYSTEM_BAR=true` leaves it
///      on the iOS 26 system bar instead
///   7  + Navigator.popUntil(isFirst) after every swap, post-frame
///   8  + registerRoutes and SystemChrome.defaultStyle at boot
///   9  + setAppBrightness(Brightness.light) and Scaffold.brightness
/// `--dart-define=KEYED=true` wraps the child in a KeyedSubtree.
/// `--dart-define=SPINNER=true` makes A's button show a
/// CircularProgressIndicator for a second before it swaps, like a login
/// button waiting on the network.
/// `--dart-define=OBSCURE=true` makes A's TextField a password field.
/// `--dart-define=SEGMENT=true` adds a SegmentedControl to A (pick "Two"
/// before swapping).
/// `--dart-define=LOGIN=true` gives A the shape of the port's login screen:
/// SafeArea > ListView > SegmentedControl + a keyed subtree per segment
/// holding a Pressable button that shows a spinner while busy.
const step = int.fromEnvironment('STEP', defaultValue: 1);
const keyed = bool.fromEnvironment('KEYED');
const systemBar = bool.fromEnvironment('SYSTEM_BAR');
const spinner = bool.fromEnvironment('SPINNER');
const obscure = bool.fromEnvironment('OBSCURE');
const segment = bool.fromEnvironment('SEGMENT');
const login = bool.fromEnvironment('LOGIN');

const _kraft = Color(0xFFECE3CF);
const _ink = TextStyle(color: Color(0xFF111111), fontSize: 17);

void main() {
  DartNativePluginRegistrant.registerAll();
  if (step >= 9) setAppBrightness(Brightness.light);
  if (step >= 8) {
    SystemChrome.defaultStyle = SystemUiOverlayStyle.dark;
    registerRoutes({'/pushed': (_) => const Scaffold(body: Text('Pushed'))});
  }
  runApp(const SwapRoot());
}

class SwapRoot extends StatefulWidget {
  const SwapRoot({super.key});

  @override
  State<SwapRoot> createState() => _SwapRootState();
}

class _SwapRootState extends State<SwapRoot> {
  bool _showB = false;

  void _swap() {
    setState(() => _showB = !_showB);
    print('SWAP -> ${_showB ? 'B' : 'A'} (step $step, keyed $keyed)');
    if (step >= 7) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _showB ? RootB(onSwap: _swap) : RootA(onSwap: _swap);
    if (!keyed) return child;
    return KeyedSubtree(key: ValueKey(_showB), child: child);
  }
}

class RootA extends StatefulWidget {
  const RootA({super.key, required this.onSwap});

  final VoidCallback onSwap;

  @override
  State<RootA> createState() => _RootAState();
}

class _RootAState extends State<RootA> {
  bool _busy = false;
  int _segment = 0;

  Future<void> _tap() async {
    if (!spinner) return widget.onSwap();
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    widget.onSwap();
    // What a login button's `finally` does: the outgoing root rebuilds in the
    // frame that removes it.
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (login) return _loginShape();
    return Scaffold(
      brightness: step >= 9 ? Brightness.light : null,
      backgroundColor: step >= 5 ? _kraft : null,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Root A · step $step${keyed ? ' · keyed' : ''}', style: _ink),
          const SizedBox(height: 16),
          if (segment)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SegmentedControl(
                segments: const ['One', 'Two'],
                selectedIndex: _segment,
                onValueChanged: (i) => setState(() => _segment = i),
              ),
            ),
          if (step >= 3)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: TextField(
                obscureText: obscure,
                decoration: InputDecoration(hintText: 'Focus me, then swap'),
              ),
            ),
          const SizedBox(height: 16),
          if (_busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Button(title: 'Swap to B', onPressed: _tap),
        ],
      ),
    );
  }
}

extension on _RootAState {
  Widget _loginShape() {
    return Scaffold(
      backgroundColor: step >= 5 ? _kraft : null,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SegmentedControl(
              segments: const ['Phone', 'Email'],
              selectedIndex: _segment,
              onValueChanged: (i) => setState(() => _segment = i),
            ),
            const SizedBox(height: 22),
            KeyedSubtree(
              key: ValueKey(_segment),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _BusyButton(
                    label: 'Swap to B',
                    busy: _busy,
                    onPressed: _busy ? null : _tap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The port's DaftarButton, reduced: a Pressable surface whose label becomes
/// a spinner while busy.
class _BusyButton extends StatelessWidget {
  const _BusyButton({required this.label, required this.busy, this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    final content = SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: busy
            ? const [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: white),
                ),
              ]
            : [Text(label, style: const TextStyle(color: white, fontSize: 16))],
      ),
    );
    return Row(
      children: [
        Expanded(
          child: Pressable(
            onTap: onPressed,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFB85C1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: content,
            ),
          ),
        ),
      ],
    );
  }
}

/// Copied from the port: scales to 0.96 on tap-down, fires on tap-up.
class Pressable extends StatefulWidget {
  const Pressable({super.key, this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 200),
  );

  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.96)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    if (widget.onTap == null) return;
    _controller.forward();
  }

  void _release() {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  void _activate() {
    _release();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press(),
      onTapUp: (_) => _activate(),
      onTapCancel: _release,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

class RootB extends StatefulWidget {
  const RootB({super.key, required this.onSwap});

  final VoidCallback onSwap;

  @override
  State<RootB> createState() => _RootBState();
}

class _RootBState extends State<RootB> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    if (step >= 4) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      brightness: step >= 9 ? Brightness.light : null,
      backgroundColor: step >= 5 ? _kraft : null,
      appBar: step >= 6
          ? AppBar(
              title: const Text('Root B', style: _ink),
              ios: AppBarIOSConfig(systemBar: systemBar),
            )
          : null,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Root B · step $step${keyed ? ' · keyed' : ''}', style: _ink),
          const SizedBox(height: 16),
          Button(title: 'Swap to A', onPressed: widget.onSwap),
        ],
      ),
      bottomNavigationBar: step >= 2
          ? BottomNavigationBar(
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              items: const [
                BottomNavigationBarItem(label: 'One'),
                BottomNavigationBarItem(label: 'Two'),
              ],
            )
          : null,
    );
  }
}
