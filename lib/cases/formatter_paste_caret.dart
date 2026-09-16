import 'package:dartnative/dartnative.dart';

import '../dartnative_plugin_registrant.dart';

/// A formatter that rewrites a pasted phone number and returns the caret at
/// the end. Copy `+218 91-234-5678`, paste it into the field, then type `0`.
///
///   dn run -t lib/cases/formatter_paste_caret.dart
class StripToLocal extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('218') ? digits.substring(3) : digits;
    if (local == newValue.text) return newValue;
    final value = TextEditingValue(
      text: local,
      selection: TextSelection.collapsed(offset: local.length),
    );
    print('formatter returned "${value.text}" caret ${value.selection.baseOffset}');
    return value;
  }
}

const _ink = TextStyle(color: Color(0xFF111111), fontSize: 22);

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const PasteScreen());
}

class PasteScreen extends StatefulWidget {
  const PasteScreen({super.key});

  @override
  State<PasteScreen> createState() => _PasteScreenState();
}

class _PasteScreenState extends State<PasteScreen> {
  final _controller = TextEditingController();

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
            TextField(
              controller: _controller,
              style: _ink,
              keyboardType: TextInputType.phone,
              inputFormatters: [StripToLocal()],
              decoration: const InputDecoration(hintText: 'Paste here'),
              onChanged: (text) => print(
                'onChanged "$text" controller caret ${_controller.selection.baseOffset}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
