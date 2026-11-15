import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'government_dashboard_screen.dart';

class GovernmentLoginScreen extends StatefulWidget {
  const GovernmentLoginScreen({super.key});

  @override
  State<GovernmentLoginScreen> createState() => _GovernmentLoginScreenState();
}

class _GovernmentLoginScreenState extends State<GovernmentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _officerId = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _officerId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      // Government officer ID is the email/username assigned by the system administrator.
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _officerId.text.trim(),
        password: _password.text,
      );
      final token = await credential.user!.getIdTokenResult(true);
      if (token.claims?['government'] != true) {
        await FirebaseAuth.instance.signOut();
        throw Exception('This account is not authorized for the government portal.');
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GovernmentDashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Invalid officer ID or password.',
        'too-many-requests' => 'Too many attempts. Please wait and try again.',
        'network-request-failed' => 'Network error. Check your connection.',
        _ => e.message ?? 'Government login failed.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Government Portal')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 58, color: Color(0xFF246B3B)),
                        const SizedBox(height: 12),
                        Text('Authorized Officer Login', textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Sign in with credentials issued by the DIFMS administrator.', textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _officerId,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(labelText: 'Government officer ID / email', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your officer ID' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _hidePassword,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _hidePassword = !_hidePassword))),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                          onFieldSubmitted: (_) => _busy ? null : _login(),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _busy ? null : _login,
                          icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login),
                          label: Text(_busy ? 'Signing in…' : 'Secure login'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        ),
                        const SizedBox(height: 12),
                        const Text('Officer accounts are created and authorized by the system administrator. There is no public government registration.', style: TextStyle(fontSize: 12, color: Color(0xFFFFD166)), textAlign: TextAlign.center),
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
