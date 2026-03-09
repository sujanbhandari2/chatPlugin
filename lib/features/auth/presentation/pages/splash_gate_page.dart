import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/gradient_background.dart';
import '../controllers/auth_controller.dart';

class SplashGatePage extends ConsumerWidget {
  const SplashGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (!authState.isInitializing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        context.go(authState.isAuthenticated ? '/chat' : '/auth');
      });
    }

    return const Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Preparing session...'),
            ],
          ),
        ),
      ),
    );
  }
}
