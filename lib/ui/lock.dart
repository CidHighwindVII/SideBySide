import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../engine/models.dart';
import '../../l10n/gen/app_localizations.dart';

/// v0.3.0 (#3): salted PIN hash lives inside sidebyside.json —
/// one-file invariant holds, no secure-storage second surface.
String newPinSalt() =>
    base64Url.encode(List.generate(8, (_) => Random.secure().nextInt(256)));

String hashPin(String salt, String pin) =>
    sha256.convert(utf8.encode('$salt$pin')).toString();

/// Biometric attempt via local_auth; any failure (unsupported, cancelled,
/// exception on non-Android targets) returns false → PIN fallback.
Future<bool> tryBiometric(BuildContext context) async {
  try {
    return await LocalAuthentication()
        .authenticate(
          localizedReason: AppL.of(context).lockBiometricReason,
          biometricOnly: true,
        )
        .timeout(const Duration(seconds: 30));
  } catch (_) {
    return false;
  }
}

/// PIN prompt: [setup]=true asks twice and returns the new PIN;
/// setup=false asks once and returns it for verification.
Future<String?> askPin(BuildContext context,
    {bool setup = false, String? title}) async {
  final l = AppL.of(context);
  final c1 = TextEditingController();
  final c2 = TextEditingController();
  final err = ValueNotifier<String?>(null);
  final pin = RegExp(r'^\d{4,6}$');
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title ?? (setup ? l.lockPinSet : l.lockPinField)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: c1,
            obscureText: true,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            decoration: InputDecoration(labelText: l.lockPinField),
          ),
          if (setup)
            TextField(
              controller: c2,
              obscureText: true,
              keyboardType: TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              decoration: InputDecoration(labelText: l.lockPinConfirm),
            ),
          ValueListenableBuilder(
            valueListenable: err,
            builder: (_, e, _) => e == null
                ? const SizedBox.shrink()
                // §A.2: monochrome — icon + weight carry the error, not red.
                  : Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 16, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(e,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.error))),
                      ],
                    ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            if (!pin.hasMatch(c1.text) ||
                (setup && !pin.hasMatch(c2.text))) {
              err.value = l.lockPinSet;
              return;
            }
            if (setup && c1.text != c2.text) {
              err.value = l.lockPinMismatch;
              return;
            }
            Navigator.pop(ctx, c1.text);
          },
          child: Text(l.save),
        ),
      ],
    ),
  );
  // no dispose: the pop animation still reads these after showDialog returns
  return result;
}

/// Full-screen gate shown on cold start and after backgrounding.
class LockScreen extends StatefulWidget {
  final Settings settings;
  final VoidCallback onUnlock;
  const LockScreen({required this.settings, required this.onUnlock, super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pin = TextEditingController();
  String? _error;
  bool _bioTried = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _biometric());
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _biometric() async {
    if (_bioTried) return;
    setState(() => _bioTried = true);
    if (await tryBiometric(context)) widget.onUnlock();
  }

  void _verify() {
    final salt = widget.settings.pinSalt;
    final hash = widget.settings.pinHash;
    if (salt != null && hash != null && hashPin(salt, _pin.text) == hash) {
      widget.onUnlock();
    } else {
      setState(() => _error = AppL.of(context).lockPinBad);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 12),
                Text(l.lockTitleScreen,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 24),
                TextField(
                  controller: _pin,
                  obscureText: true,
                  keyboardType:
                      TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  onSubmitted: (_) => _verify(),
                  decoration: InputDecoration(
                    labelText: l.lockPinField,
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                    onPressed: _verify,
                    child: Text(_error == null ? l.lockUnlock : l.lockPinField)),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _biometric,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(l.lockBiometric),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
