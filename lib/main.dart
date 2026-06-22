import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/perkembangan/perkembangan_screen.dart';
import 'screens/perkembangan/detail_perkembangan_screen.dart';
import 'screens/analisis/analisis_screen.dart';
import 'screens/analisis/detail_analisis_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/catatan/catatan_rumah_screen.dart';
import 'screens/notifikasi/notifikasi_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('[FCM BACKGROUND] Notifikasi diterima: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    _setupForegroundListener();
  }

  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM FOREGROUND] ${message.notification?.title}');

      final context = navigatorKey.currentContext;
      if (context == null) return;

      final judul = message.notification?.title ?? 'Notifikasi Baru';
      final isi   = message.notification?.body  ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0E7490),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(12),
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isi,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Lihat',
            textColor: Colors.white,
            onPressed: () {
              navigatorKey.currentState?.pushNamed('/notifikasi');
            },
          ),
        ),
      );

      final auth = context.read<AuthProvider>();
      auth.fetchDashboardData();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Notifikasi dibuka dari background');
      navigatorKey.currentState?.pushNamed('/notifikasi');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: "KB Nurul'Ain",
        theme: ThemeData(
          fontFamily: 'PlusJakartaSans',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0E7490),
          ),
          useMaterial3: true,
        ),
        home: const SplashWrapper(),
        routes: {
          '/login'     : (_) => const LoginScreen(),
          '/dashboard' : (_) => const DashboardScreen(),
          '/perkembangan' : (_) => const PerkembanganScreen(),
          '/detail-perkembangan': (_) => const DetailPerkembanganScreen(),
          '/analisis':       (_) => const AnalisisScreen(),
          '/detail-analisis': (_) => const DetailAnalisisScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/catatan-rumah': (context) => const CatatanRumahScreen(),
          '/notifikasi': (_) => const NotifikasiScreen(), 
        },
      ),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await context.read<AuthProvider>().loadSession();

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E7490),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_rounded, color: Colors.white, size: 64),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      );
    }

    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    return isLoggedIn ? const DashboardScreen() : const LoginScreen();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isLoggedIn ? const DashboardScreen() : const LoginScreen();
  }
}