import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';

/// Root routing widget. Listens to [AuthProvider.status] and shows the
/// login flow for signed-out users or the Home screen for signed-in users —
/// this is the "screen protection" mechanism the assignment asks for.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        // Bind the task stream to the now-known uid exactly once per change.
        context.read<TaskProvider>().bindToUser(auth.user!.uid);
        return const HomeScreen();
    }
  }
}
