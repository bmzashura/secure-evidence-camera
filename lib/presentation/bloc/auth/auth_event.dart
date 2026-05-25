import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckStatus extends AuthEvent {}

class AuthSetupPin extends AuthEvent {
  final String pin;

  const AuthSetupPin(this.pin);

  @override
  List<Object?> get props => [pin];
}

class AuthVerifyPin extends AuthEvent {
  final String pin;

  const AuthVerifyPin(this.pin);

  @override
  List<Object?> get props => [pin];
}

class AuthLock extends AuthEvent {}

class AuthUnlock extends AuthEvent {}

class AuthAppResumed extends AuthEvent {
  final bool fromBackground;

  const AuthAppResumed({this.fromBackground = false});

  @override
  List<Object?> get props => [fromBackground];
}

class AuthAppPaused extends AuthEvent {}

class AuthCompleteOnboarding extends AuthEvent {}

class AuthAttemptPin extends AuthEvent {
  final String pin;

  const AuthAttemptPin(this.pin);

  @override
  List<Object?> get props => [pin];
}