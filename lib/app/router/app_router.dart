import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/splash_gate_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashGatePage()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatPage()),
    ],
  );
});
