import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../widgets/pin_input.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isSettingUp = false;
  bool _isConfirming = false;
  String _firstPin = '';
  Timer? _lockoutTimer;
  String? _lastError;

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _startLockoutTimer(int seconds) {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = seconds - timer.tick;
      if (remaining <= 0) {
        timer.cancel();
        context.read<AuthBloc>().add(AuthCheckStatus());
      } else {
        setState(() {});
      }
    });
  }

  void _onPinComplete(String pin) {
    final authBloc = context.read<AuthBloc>();
    final state = authBloc.state;

    if (state.status == AuthStatus.pinNotSet || _isSettingUp) {
      if (!_isConfirming) {
        setState(() {
          _isSettingUp = true;
          _firstPin = pin;
          _isConfirming = true;
          _lastError = null;
        });
      } else {
        if (pin == _firstPin) {
          authBloc.add(AuthSetupPin(pin));
        } else {
          setState(() {
            _isConfirming = false;
            _firstPin = '';
            _lastError = 'PIN tidak cocok. Silakan coba lagi.';
          });
        }
      }
    } else {
      _lastError = null;
      authBloc.add(AuthAttemptPin(pin));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.lockout && state.lockoutRemaining != null) {
          _startLockoutTimer(state.lockoutRemaining!.inSeconds);
        }
        if (state.status == AuthStatus.locked && _isConfirming) {
          setState(() {
            _isConfirming = false;
            _firstPin = '';
          });
        }
        // Detect wrong PIN - when errorMessage appears and we have no active error
        if (state.errorMessage != null && _lastError == null) {
          _lastError = state.errorMessage;
        } else if (state.errorMessage == null) {
          _lastError = null;
        }
      },
      builder: (context, state) {
        final isLockout = state.status == AuthStatus.lockout;
        final isPinNotSet = state.status == AuthStatus.pinNotSet;

        String subtitle;
        if (isLockout) {
          subtitle = 'Terlalu banyak percobaan.';
        } else if (_isConfirming) {
          subtitle = AppStrings.confirmSubtitle;
        } else if (isPinNotSet || _isSettingUp) {
          subtitle = AppStrings.setupSubtitle;
        } else {
          subtitle = AppStrings.lockSubtitle;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Lock icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    // Error message
                    if (_lastError != null && !isLockout)
                      Text(
                        _lastError!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),
                    // Lockout countdown
                    if (isLockout) ...[
                      const Icon(
                        Icons.lock_clock,
                        size: 56,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<int>(
                        stream: Stream.periodic(
                          const Duration(seconds: 1),
                          (count) => (state.lockoutRemaining?.inSeconds ?? 30) - count,
                        ).take(30),
                        builder: (context, snapshot) {
                          final remaining = state.lockoutRemaining?.inSeconds ?? 30;
                          return Text(
                            '${snapshot.data ?? remaining}',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'detik',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else ...[
                      // PIN input - key changes on error to trigger reset
                      PinInput(
                        key: ValueKey('pin_${_lastError ?? 'ok'}'),
                        onPinComplete: _onPinComplete,
                        isError: _lastError != null,
                        isDisabled: isLockout,
                      ),
                    ],
                    const SizedBox(height: 40),
                    // Footer
                    const Text(
                      'Foto terenkripsi.\nTidak ada yang bisa membukanya tanpa PIN.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}