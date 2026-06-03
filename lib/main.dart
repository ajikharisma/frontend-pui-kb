import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/perkembangan/perkembangan_screen.dart';
import 'screens/perkembangan/detail_perkembangan_screen.dart';
import 'screens/analisis/analisis_screen.dart';
import 'screens/analisis/detail_analisis_screen.dart';
import 'screens/profile/profile_screen.dart';        // ← TAMBAH
import 'screens/catatan/catatan_rumah_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "KB Nurul'Ain",
        theme: ThemeData(
          fontFamily: 'PlusJakartaSans',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0E7490),
          ),
          useMaterial3: true,
        ),
        // ← Ganti AuthWrapper dengan SplashWrapper
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
        },
      ),
    );
  }
}

// =========================================================
// SPLASH WRAPPER — load session dulu sebelum tampil halaman
// Ditambahkan untuk fix data hilang saat refresh
// =========================================================
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
    // Panggil loadSession() dari AuthProvider
    await context.read<AuthProvider>().loadSession();

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampil splash sementara session dicek
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

    // Session sudah dicek — arahkan sesuai status login
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    return isLoggedIn ? const DashboardScreen() : const LoginScreen();
  }
}

// =========================================================
// AUTH WRAPPER — tetap ada, tidak dihapus
// (tidak dipakai sebagai home lagi, tapi bisa dipakai di tempat lain)
// =========================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isLoggedIn ? const DashboardScreen() : const LoginScreen();
  }
}

// '/detail-analisis': (_) => const DetailAnalisisScreen(),