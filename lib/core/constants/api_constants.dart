class ApiConstants {
  static const String baseUrl = 'http://192.168.18.59:8000/api';
  static const String login = '/login';

  // 🔥 CUKUP GUNAKAN SATU FUNGSI INI SAJA (Gabungan helper proxy + debug print)
  static String fotoUrl(String? fotoPath) {
    if (fotoPath == null || fotoPath.isEmpty) return '';
    if (fotoPath.startsWith('http')) return fotoPath;
    
    final url = '$baseUrl/foto/$fotoPath';
    
    // Ini tetap mencetak log ke terminal untuk kamu pantau jalurnya
    print('=== FOTO URL GENERATED: $url ==='); 
    
    return url;
  }
}