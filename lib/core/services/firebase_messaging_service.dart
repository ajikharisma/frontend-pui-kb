import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();

  factory FirebaseMessagingService() => _instance;

  FirebaseMessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // =========================================================
  // MINTA IZIN NOTIFIKASI (wajib untuk iOS, dianjurkan Android 13+)
  // =========================================================
  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
  }

  // =========================================================
  // AMBIL FCM TOKEN UNTUK DEVICE INI
  // =========================================================
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('[FCM] Token: $token');
      return token;
    } catch (e) {
      debugPrint('[FCM] Gagal ambil token: $e');
      return null;
    }
  }

  // =========================================================
  // LISTEN PERUBAHAN TOKEN (token bisa berubah sewaktu-waktu)
  // =========================================================
  void onTokenRefresh(Function(String) callback) {
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token diperbarui: $newToken');
      callback(newToken);
    });
  }

  // =========================================================
  // SETUP LISTENER NOTIFIKASI MASUK
  // Dipanggil sekali saat aplikasi pertama kali start (di main.dart)
  // =========================================================
  void setupListeners({
    required Function(RemoteMessage) onForegroundMessage,
    required Function(RemoteMessage) onMessageOpenedApp,
  }) {
    // Saat notifikasi masuk SEMENTARA app sedang dibuka (foreground)
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Notifikasi diterima (foreground): ${message.notification?.title}');
      onForegroundMessage(message);
    });

    // Saat user TAP notifikasi dan app terbuka dari background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Notifikasi dibuka dari background: ${message.notification?.title}');
      onMessageOpenedApp(message);
    });
  }
}