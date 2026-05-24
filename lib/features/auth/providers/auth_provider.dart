import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase/supabase_client.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({this.status = AuthStatus.initial, this.user, this.error});

  AuthState copyWith({AuthStatus? status, User? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    Future(() => _init());
  }

  Future<void> _init() async {
    final session = SupabaseManager.client.auth.currentSession;
    if (session?.user != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: session!.user,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }

    SupabaseManager.client.auth.onAuthStateChange.listen((event) {
      if (event.session?.user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: event.session!.user,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await SupabaseManager.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await SupabaseManager.client.auth.signUp(
        email: email,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: '注册成功！请检查邮箱确认。',
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await SupabaseManager.client.auth.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
