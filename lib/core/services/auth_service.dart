import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';

class AuthService {

  final Dio dio = Dio();

  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login({

    required String email,
    required String password,

  }) async {

    try {

      final response = await dio.post(

        '${ApiConstants.baseUrl}${ApiConstants.login}',

        data: {

          'email': email,
          'password': password,

        },

      );

      print(response.data);

      // simpan token
      await storage.write(

        key: 'token',

        value: response.data['token'],

      );

      return response.data;

    } on DioException catch (e) {

      print(e.response?.data);

      // HANDLE ERROR DENGAN AMAN
      if (e.response != null) {

        final data = e.response!.data;

        // kalau response berbentuk Map
        if (data is Map<String, dynamic>) {

          throw Exception(
            data['message'] ?? 'Login gagal'
          );

        }

        // kalau response String
        throw Exception(data.toString());

      }

      throw Exception('Tidak dapat terhubung ke server');

    }

  }

}