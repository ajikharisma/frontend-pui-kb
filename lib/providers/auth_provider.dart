import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '/core/constants/api_constants.dart';
import '../core/services/firebase_messaging_service.dart';   // ← TAMBAH

class AuthProvider with ChangeNotifier {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();
  final _fcmService = FirebaseMessagingService();             // ← TAMBAH

  UserModel? _user;
  UserModel? get user => _user;

  bool get isLoggedIn => _user != null;

  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? get dashboardData => _dashboardData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 🔥 PROSES LOGIN API
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.login}',
        data: {'email': email, 'password': password},
      );

      final Map<String, dynamic> responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      print(responseData);

      if (responseData['success'] == true) {
        final String token = responseData['token'] ?? '';
        final Map<String, dynamic> userJson = responseData['user'];

        _user = UserModel.fromJson(userJson, token);

        await _storage.write(
          key: 'user_session',
          value: jsonEncode({
            'user': userJson,
            'token': token,
          }),
        );

        // ← TAMBAH: kirim FCM token setelah login berhasil
        await _registerFcmToken();

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;

    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();

      String message = 'Login gagal';

      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic>) {
          message = data['message'] ?? 'Login gagal';
        } else {
          message = data.toString();
        }
      }

      throw Exception(message);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Terjadi kesalahan sistem');
    }
  }

  // =========================================================
  // 🔥 DAFTARKAN FCM TOKEN KE SERVER (BARU)
  // =========================================================
  Future<void> _registerFcmToken() async {
    if (_user == null) return;

    try {
      // Minta izin notifikasi dulu (terutama untuk Android 13+)
      await _fcmService.requestPermission();

      // Ambil token unik device ini
      final fcmToken = await _fcmService.getToken();

      if (fcmToken == null) {
        print('[FCM] Token tidak tersedia, skip kirim ke server');
        return;
      }

      // Kirim token ke Laravel
      await _dio.post(
        '${ApiConstants.baseUrl}/parent/fcm-token',
        data: {'fcm_token': fcmToken},
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_user!.token}',
            'Accept': 'application/json',
          },
        ),
      );

      print('[FCM] Token berhasil dikirim ke server');

      // Listen kalau token berubah di kemudian hari
      _fcmService.onTokenRefresh((newToken) async {
        await _dio.post(
          '${ApiConstants.baseUrl}/parent/fcm-token',
          data: {'fcm_token': newToken},
          options: Options(
            headers: {
              'Authorization': 'Bearer ${_user!.token}',
              'Accept': 'application/json',
            },
          ),
        );
        print('[FCM] Token baru berhasil dikirim ke server');
      });

    } catch (e) {
      print('[FCM ERROR] Gagal daftarkan token: $e');
    }
  }

  // 🔥 AMBIL DATA DARI DATABASE LARAVEL
  Future<void> fetchDashboardData() async {
    if (_user == null) return;

    print("===== DEBUG DASHBOARD =====");
    print("User : ${_user!.nama}");
    print("Token: ${_user!.token}");

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/parent/dashboard',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_user!.token}',
            'Accept': 'application/json',
          },
        ),
      );

      print("STATUS : ${response.statusCode}");
      print("DATA   : ${response.data}");

      if (response.statusCode == 200) {
        _dashboardData = response.data;
        final dynamic rawPerkembangan = _dashboardData?['perkembangan_list'];
        List<dynamic> listRaw = [];
        if (rawPerkembangan is String) {
          try { listRaw = jsonDecode(rawPerkembangan); } catch (_) {}
        } else if (rawPerkembangan is List) {
          listRaw = rawPerkembangan;
        }
        print('=== DEBUG PERKEMBANGAN ===');
        print('Total item: ${listRaw.length}');
        for (var item in listRaw) {
          final d = item is String ? jsonDecode(item) : Map<String, dynamic>.from(item);
          print('Minggu: ${d['minggu']} | Tema: ${d['tema']}');
        }
        notifyListeners();
      }
    } catch (e) {
      print('ERROR DASHBOARD: $e');
    }
  }

  // =========================================================
  // LOAD SESSION — dipanggil saat app pertama kali dibuka
  // =========================================================
  Future<void> loadSession() async {
    try {
      final sessionStr = await _storage.read(key: 'user_session');

      if (sessionStr == null) return;

      final sessionData = jsonDecode(sessionStr);
      final token       = sessionData['token'] ?? '';
      final userJson    = sessionData['user']  ?? {};

      if (token.isNotEmpty) {
        _user = UserModel.fromJson(userJson, token);
        notifyListeners();

        await fetchDashboardData();

        // ← TAMBAH: pastikan FCM token tetap update saat buka app lagi
        await _registerFcmToken();
      }

    } catch (e) {
      await _storage.delete(key: 'user_session');
      _user = null;
      notifyListeners();
    }
  }

  // 🔥 SIMPAN CATATAN BARU KE DATABASE LARAVEL
  Future<bool> simpanCatatan({
    required String judul,
    required String isi,
    required String tanggal,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/parent/catatan',
        data: {
          'judul_catatan': judul,
          'isi_catatan': isi,
          'tanggal': tanggal,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_user!.token}',
            'Accept': 'application/json',
          },
        ),
      );

      return response.data['success'] == true;

    } catch (e) {
      print(e);
      return false;
    }
  }

  // 🔥 LOGOUT
  Future<void> logout() async {
    _user = null;
    _dashboardData = null;
    await _storage.delete(key: 'user_session');
    notifyListeners();
  }
}