import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Exposes authentication state and actions to the widget tree.
/// Screens never call [AuthService] directly — they call this provider.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService}) : _authService = authService ?? AuthService() {
    _sub = _authService.authStateChanges.listen(_onAuthChanged);
  }

  late final StreamSubscription<User?> _sub;

  AuthStatus status = AuthStatus.unknown;
  User? user;
  bool isLoading = false;
  String? errorMessage;

  void _onAuthChanged(User? firebaseUser) {
    user = firebaseUser;
    status = firebaseUser == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) => _runAuthAction(
        () => _authService.signIn(email: email, password: password),
      );

  Future<bool> signUp(String email, String password, String displayName) => _runAuthAction(
        () => _authService.signUp(email: email, password: password, displayName: displayName),
      );

  Future<void> signOut() async {
    isLoading = true;
    notifyListeners();
    await _authService.signOut();
    isLoading = false;
    notifyListeners();
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = AuthService.messageForCode(e.code);
      return false;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _runAuthAction(Future<User?> Function() action) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = AuthService.messageForCode(e.code);
      return false;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
