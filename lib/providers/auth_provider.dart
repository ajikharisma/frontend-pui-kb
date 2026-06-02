import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '/core/constants/api_constants.dart';


class AuthProvider with ChangeNotifier {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  UserModel? _user;
  UserModel? get user => _user;

  // 🔥 PASTI KAN BARIS INI ADA DI SINI (Gunting dan tempel kode ini)
  bool get isLoggedIn => _user != null;

  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? get dashboardData => _dashboardData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 🔥 PROSES LOGIN API — VERSI FIX KURUNG & SINKRONISASI JSON
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.login}',
        data: {'email': email, 'password': password},
      );

      // Konversi ke Map JSON jika terdeteksi berupa String mentah
      final Map<String, dynamic> responseData = response.data is String 
          ? jsonDecode(response.data) 
          : response.data;
          print(responseData);

      if (responseData['success'] == true) {
        final String token = responseData['token'] ?? '';
        final Map<String, dynamic> userJson = responseData['user'];
        
        // Buat objek user
        _user = UserModel.fromJson(userJson, token);

        // Simpan ke lokal secure storage dalam bentuk string JSON yang sah
        await _storage.write(
          key: 'user_session',
          value: jsonEncode({
            'user': userJson,
            'token': token,
          }),
        );

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

  // 🔥 AMBIL DATA DARI DATABASE LARAVEL (SINKRONISASI REAL-TIME)
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
        // ── TAMBAHKAN DEBUG INI TEPAT DI SINI ──
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
        // ── AKHIR DEBUG ──
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

      if (sessionStr == null) return; // belum pernah login

      final sessionData = jsonDecode(sessionStr);
      final token       = sessionData['token'] ?? '';
      final userJson    = sessionData['user']  ?? {};

      if (token.isNotEmpty) {
        _user = UserModel.fromJson(userJson, token);
        notifyListeners();

        // Langsung fetch data dashboard setelah session dimuat
        await fetchDashboardData();
      }

    } catch (e) {
      // Session rusak/expired — hapus dan paksa login ulang
      await _storage.delete(key: 'user_session');
      _user = null;
      notifyListeners();
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