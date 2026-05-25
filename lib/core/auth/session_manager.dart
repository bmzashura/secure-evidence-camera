import 'dart:async';

/// Session manager for auto-lock after background timeout
class SessionManager {
  static const Duration sessionTimeout = Duration(minutes: 2);
  static const Duration lockoutDuration = Duration(seconds: 30);

  static const int maxAttempts = 3;

  DateTime? _lastActiveTime;
  int _failedAttempts = 0;
  bool _isLocked = false;
  DateTime? _lockoutEndTime;
  Timer? _lockoutTimer;
  Timer? _sessionTimer;

  Function()? onSessionExpired;
  Function()? onLockoutEnded;

  bool get isLocked => _isLocked;
  int get failedAttempts => _failedAttempts;
  int get remainingAttempts => maxAttempts - _failedAttempts;
  Duration? get lockoutRemaining {
    if (!_isLocked || _lockoutEndTime == null) return null;
    final remaining = _lockoutEndTime!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Call when app goes to foreground
  void onAppResumed() {
    _lastActiveTime = DateTime.now();
    _checkSessionExpiry();
    _checkLockoutExpiry();
  }

  /// Call when app goes to background
  void onAppPaused() {
    _lastActiveTime = DateTime.now();
  }

  /// Record user activity (resets session timer)
  void recordActivity() {
    _lastActiveTime = DateTime.now();
    _sessionTimer?.cancel();
    _startSessionTimer();
  }

  /// Check if PIN attempt is allowed
  bool canAttemptPin() {
    if (_isLocked) {
      _checkLockoutExpiry();
      return !_isLocked;
    }
    return true;
  }

  /// Record failed PIN attempt
  void recordFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _startLockout();
    }
  }

  /// Record successful PIN entry
  void recordSuccess() {
    _failedAttempts = 0;
    _isLocked = false;
    _lockoutTimer?.cancel();
    recordActivity();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(sessionTimeout, () {
      onSessionExpired?.call();
    });
  }

  void _checkSessionExpiry() {
    if (_lastActiveTime == null) return;
    final elapsed = DateTime.now().difference(_lastActiveTime!);
    if (elapsed >= sessionTimeout) {
      onSessionExpired?.call();
    }
  }

  void _startLockout() {
    _isLocked = true;
    _lockoutEndTime = DateTime.now().add(lockoutDuration);
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer(lockoutDuration, () {
      _endLockout();
    });
  }

  void _checkLockoutExpiry() {
    if (!_isLocked || _lockoutEndTime == null) return;
    if (DateTime.now().isAfter(_lockoutEndTime!)) {
      _endLockout();
    }
  }

  void _endLockout() {
    _isLocked = false;
    _lockoutEndTime = null;
    _lockoutTimer?.cancel();
    _failedAttempts = 0;
    onLockoutEnded?.call();
  }

  void dispose() {
    _sessionTimer?.cancel();
    _lockoutTimer?.cancel();
  }
}