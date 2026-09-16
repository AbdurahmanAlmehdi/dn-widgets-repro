import 'package:dartnative/dartnative.dart';

import '../dartnative_plugin_registrant.dart';

/// The same `letterSpacing: 12` on a Text and on a TextField.
///
///   dn run -t lib/cases/text_field_letter_spacing.dart
const _spaced = TextStyle(color: Color(0xFF111111), fontSize: 28, letterSpacing: 12);
const _plain = TextStyle(color: Color(0xFF111111), fontSize: 28);
const _label = TextStyle(color: Color(0xFF6B6B70), fontSize: 13);

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const SpacingScreen());
}

class SpacingScreen extends StatefulWidget {
  const SpacingScreen({super.key});

  @override
  State<SpacingScreen> createState() => _SpacingScreenState();
}

class _SpacingScreenState extends State<SpacingScreen> {
  final _spacedField = TextEditingController(text: '583208');
  final _plainField = TextEditingController(text: '583208');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Text, letterSpacing: 12', style: _label),
            const Text('583208', style: _spaced),
            const SizedBox(height: 24),
            const Text('TextField, letterSpacing: 12', style: _label),
            TextField(controller: _spacedField, style: _spaced),
            const SizedBox(height: 24),
            const Text('TextField, no letterSpacing', style: _label),
            TextField(controller: _plainField, style: _plain),
          ],
        ),
      ),
    );
  }
}
