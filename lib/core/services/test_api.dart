import 'package:dio/dio.dart';

class TestApi {

  final Dio dio = Dio();

  Future<void> testConnection() async {

    try {

      print("TEST API DIMULAI");

      final response = await dio.get(
        'http://192.168.18.59:8000/api'
      );

      print("BERHASIL");
      print(response.data);

    } catch (e) {

      print("ERROR API");
      print(e);

    }
  }
}