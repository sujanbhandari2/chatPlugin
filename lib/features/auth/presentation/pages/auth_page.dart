import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_card.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.listenManual(authControllerProvider, (previous, next) {
      if (next.isAuthenticated && mounted) {
        context.go('/chat');
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthCard(
                    mode: authState.mode,
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    isLoading: authState.isLoading,
                    onModeChanged: (mode) {
                      ref.read(authControllerProvider.notifier).setMode(mode);
                    },
                    onSubmit: () {
                      ref
                          .read(authControllerProvider.notifier)
                          .authenticate(
                            username: _usernameController.text,
                            password: _passwordController.text,
                          );
                    },
                  ),
                  if (authState.error != null)
                    ErrorBanner(message: authState.error!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
