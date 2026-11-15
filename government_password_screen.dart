import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GovernmentPasswordScreen extends StatefulWidget {
  const GovernmentPasswordScreen({super.key});

  @override
  State<GovernmentPasswordScreen> createState() =>
      _GovernmentPasswordScreenState();
}

class _GovernmentPasswordScreenState
    extends State<GovernmentPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again before changing your password.'),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _current.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_next.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Your current password is incorrect.';
          break;
        case 'requires-recent-login':
          message = 'Please sign in again, then change your password.';
          break;
        case 'weak-password':
          message = 'Choose a stronger password of at least 8 characters.';
          break;
        case 'network-request-failed':
          message = 'Check your internet connection and try again.';
          break;
        default:
          message = e.message ?? 'Could not update password.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _passwordDecoration({
    required String label,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      suffixIcon: IconButton(
        tooltip: hidden ? 'Show password' : 'Hide password',
        icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
        onPressed: onToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change officer password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.lock_reset,
                          size: 48,
                          color: Color(0xFF246B3B),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Verify your current password before changing it.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _current,
                          obscureText: _hideCurrent,
                          decoration: _passwordDecoration(
                            label: 'Current password',
                            hidden: _hideCurrent,
                            onToggle: () => setState(
                                  () => _hideCurrent = !_hideCurrent,
                            ),
                          ),
                          validator: (value) =>
                          value == null || value.isEmpty
                              ? 'Enter your current password'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _next,
                          obscureText: _hideNew,
                          decoration: _passwordDecoration(
                            label: 'New password',
                            hidden: _hideNew,
                            onToggle: () => setState(
                                  () => _hideNew = !_hideNew,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'Use at least 8 characters';
                            }
                            if (value == _current.text) {
                              return 'Choose a different password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirm,
                          obscureText: _hideConfirm,
                          decoration: _passwordDecoration(
                            label: 'Confirm new password',
                            hidden: _hideConfirm,
                            onToggle: () => setState(
                                  () => _hideConfirm = !_hideConfirm,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm your new password';
                            }
                            if (value != _next.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _change,
                          child: _busy
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Text('Update password'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}