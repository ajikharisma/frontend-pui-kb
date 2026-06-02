class UserModel {
  final String id;
  final String nama;
  final String email;
  final String token;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      id: (json['id_user'] ?? json['id'] ?? '').toString(), // 👈 Ubah dari json['id'] menjadi json['id_user']
      nama: json['nama'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      token: token,
    );
  }
}