import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/pin_service.dart';
import '../../../core/auth/session_manager.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final PinService _pinService;
  final SessionManager _sessionManager;

  AuthBloc({
    required PinService pinService,
    required SessionManager sessionManager,
  })  : _pinService = pinService,
        _sessionManager = sessionManager,
        super(const AuthState()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthSetupPin>(_onSetupPin);
    on<AuthAttemptPin>(_onAttemptPin);
    on<AuthLock>(_onLock);
    on<AuthUnlock>(_onUnlock);
    on<AuthAppResumed>(_onAppResumed);
    on<AuthAppPaused>(_onAppPaused);
    on<AuthCompleteOnboarding>(_onCompleteOnboarding);

    _sessionManager.onSessionExpired = () => add(AuthLock());
    _sessionManager.onLockoutEnded = () {
      add(AuthCheckStatus());
    };
  }

  Future<void> _onCheckStatus(
      AuthCheckStatus event, Emitter<AuthState> emit) async {
    final isPinSet = await _pinService.isPinSet();
    if (!isPinSet) {
      emit(state.copyWith(status: AuthStatus.pinNotSet));
    } else {
      emit(state.copyWith(status: AuthStatus.locked));
    }
  }

  Future<void> _onSetupPin(
      AuthSetupPin event, Emitter<AuthState> emit) async {
    await _pinService.setupPin(event.pin);
    _sessionManager.recordSuccess();
    emit(state.copyWith(
      status: AuthStatus.showOnboarding,
    ));
  }

  Future<void> _onAttemptPin(
      AuthAttemptPin event, Emitter<AuthState> emit) async {
    if (!_sessionManager.canAttemptPin()) {
      emit(state.copyWith(
        status: AuthStatus.lockout,
        lockoutRemaining: _sessionManager.lockoutRemaining,
        remainingAttempts: 0,
      ));
      return;
    }

    final isValid = await _pinService.verifyPin(event.pin);

    if (isValid) {
      _sessionManager.recordSuccess();
      // Show onboarding only if app was previously terminated (persisted flag)
      final wasInBackground = await _pinService.checkAndClearAppWasInBackground();
      if (wasInBackground) {
        emit(state.copyWith(
          status: AuthStatus.showOnboarding,
          remainingAttempts: 3,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.unlocked,
          remainingAttempts: 3,
          errorMessage: null,
        ));
      }
    } else {
      _sessionManager.recordFailedAttempt();
      final remaining = _sessionManager.remainingAttempts;

      if (remaining <= 0) {
        emit(state.copyWith(
          status: AuthStatus.lockout,
          lockoutRemaining: const Duration(seconds: 30),
          remainingAttempts: 0,
          errorMessage: 'Terlalu banyak percobaan. Coba lagi dalam 30 detik.',
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.locked,
          remainingAttempts: remaining,
          errorMessage: 'PIN salah. Sisa $remaining percobaan.',
        ));
      }
    }
  }

  void _onLock(AuthLock event, Emitter<AuthState> emit) {
    emit(state.copyWith(status: AuthStatus.locked));
  }

  void _onUnlock(AuthUnlock event, Emitter<AuthState> emit) {
    if (!state.hasCompletedOnboarding) {
      emit(state.copyWith(status: AuthStatus.showOnboarding));
    } else {
      emit(state.copyWith(status: AuthStatus.unlocked));
    }
  }

  void _onCompleteOnboarding(AuthCompleteOnboarding event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      status: AuthStatus.unlocked,
      hasCompletedOnboarding: true,
    ));
  }

  Future<void> _onAppResumed(AuthAppResumed event, Emitter<AuthState> emit) async {
    _sessionManager.onAppResumed();
    // Clear background flag on normal resume (not terminated)
    await _pinService.checkAndClearAppWasInBackground();
  }

  void _onAppPaused(AuthAppPaused event, Emitter<AuthState> emit) {
    // Mark that app was backgrounded - persisted to secure storage
    _pinService.setAppWasInBackground();
    if (state.status == AuthStatus.unlocked) {
      emit(state.copyWith(status: AuthStatus.locked));
    }
  }

  @override
  Future<void> close() {
    _sessionManager.dispose();
    return super.close();
  }
}