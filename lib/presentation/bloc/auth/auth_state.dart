import 'package:equatable/equatable.dart';

enum AuthStatus { initial, pinNotSet, locked, unlocked, lockout, showOnboarding }

class AuthState extends Equatable {
  final AuthStatus status;
  final int remainingAttempts;
  final Duration? lockoutRemaining;
  final String? errorMessage;
  final bool hasCompletedOnboarding;

  const AuthState({
    this.status = AuthStatus.initial,
    this.remainingAttempts = 3,
    this.lockoutRemaining,
    this.errorMessage,
    this.hasCompletedOnboarding = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    int? remainingAttempts,
    Duration? lockoutRemaining,
    String? errorMessage,
    bool clearLockout = false,
    bool? hasCompletedOnboarding,
  }) {
    return AuthState(
      status: status ?? this.status,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
      lockoutRemaining: clearLockout ? null : (lockoutRemaining ?? this.lockoutRemaining),
      errorMessage: errorMessage,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  @override
  List<Object?> get props =>
      [status, remainingAttempts, lockoutRemaining, errorMessage, hasCompletedOnboarding];
}