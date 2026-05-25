import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/auth/pin_service.dart';
import 'core/auth/session_manager.dart';
import 'core/crypto/encryption_service.dart';
import 'core/constants/colors.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/screens/lock_screen.dart';
import 'presentation/screens/camera_screen.dart';
import 'presentation/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final pinService = PinService();
  final encryptionService = EncryptionService();
  await encryptionService.initialize();

  runApp(
    SecureEvidenceCameraApp(
      pinService: pinService,
      encryptionService: encryptionService,
    ),
  );
}

class SecureEvidenceCameraApp extends StatefulWidget {
  final PinService pinService;
  final EncryptionService encryptionService;

  const SecureEvidenceCameraApp({
    super.key,
    required this.pinService,
    required this.encryptionService,
  });

  @override
  State<SecureEvidenceCameraApp> createState() =>
      _SecureEvidenceCameraAppState();
}

class _SecureEvidenceCameraAppState extends State<SecureEvidenceCameraApp> {
  late final SessionManager _sessionManager;

  @override
  void initState() {
    super.initState();
    _sessionManager = SessionManager();
  }

  @override
  void dispose() {
    _sessionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(
            pinService: widget.pinService,
            sessionManager: _sessionManager,
          )..add(AuthCheckStatus()),
        ),
      ],
      child: MaterialApp(
        title: 'Secure Evidence Camera',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primary,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surface,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
          ),
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state.status == AuthStatus.initial) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            switch (state.status) {
              case AuthStatus.pinNotSet:
              case AuthStatus.locked:
              case AuthStatus.lockout:
                return const LockScreen();
              case AuthStatus.showOnboarding:
                return OnboardingScreen(
                  onContinue: () {
                    context.read<AuthBloc>().add(AuthCompleteOnboarding());
                  },
                );
              case AuthStatus.unlocked:
                return _AppLifecycleHandler(
                  encryptionService: widget.encryptionService,
                  child: CameraScreen(encryptionService: widget.encryptionService),
                );
              default:
                return const LockScreen();
            }
          },
        ),
      ),
    );
  }
}

/// Separate widget to handle app lifecycle — placed INSIDE provider tree
class _AppLifecycleHandler extends StatefulWidget {
  final Widget child;
  final EncryptionService encryptionService;

  const _AppLifecycleHandler({
    required this.child,
    required this.encryptionService,
  });

  @override
  State<_AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<_AppLifecycleHandler>
    with WidgetsBindingObserver {
  AppLifecycleState _previousState = AppLifecycleState.detached;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final authBloc = context.read<AuthBloc>();

    if (state == AppLifecycleState.resumed) {
      // Only clear terminated flag if coming from paused (background), not cold-start
      if (_previousState == AppLifecycleState.paused) {
        authBloc.add(AuthAppResumed(fromBackground: true));
      } else {
        authBloc.add(AuthAppResumed(fromBackground: false));
      }
    } else if (state == AppLifecycleState.paused) {
      authBloc.add(AuthAppPaused());
    }

    _previousState = state;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}