import 'package:flutter/material.dart';

import '../state/auth_state.dart';

class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.mode,
    required this.usernameController,
    required this.passwordController,
    required this.isLoading,
    required this.onModeChanged,
    required this.onSubmit,
  });

  final AuthMode mode;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isLoading;
  final ValueChanged<AuthMode> onModeChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Healthcare Messenger',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Register or login with a unique username and password',
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: mode == AuthMode.login
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFF8FBFF),
                      foregroundColor: mode == AuthMode.login
                          ? Colors.white
                          : const Color(0xFF334155),
                    ),
                    onPressed: () => onModeChanged(AuthMode.login),
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: mode == AuthMode.register
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFF8FBFF),
                      foregroundColor: mode == AuthMode.register
                          ? Colors.white
                          : const Color(0xFF334155),
                    ),
                    onPressed: () => onModeChanged(AuthMode.register),
                    child: const Text('Register'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isLoading
                      ? (mode == AuthMode.register
                            ? 'Creating account...'
                            : 'Signing in...')
                      : (mode == AuthMode.register ? 'Register' : 'Login'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
