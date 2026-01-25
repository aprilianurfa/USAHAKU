// lib/models/user_model.dart

class UserModel {
  final int id;
  final String nama;
  final String email;
  final String? role;
  final int? shopId;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    this.role,
    this.shopId,
  });

  /// Factory untuk mengubah JSON dari Express/Sequelize menjadi Object Dart
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Pastikan tipe data sesuai dengan yang dikirim PostgreSQL (int)
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      
      // Mengambil 'nama' sesuai key yang dikirim dari authController.js
      nama: json['nama'] ?? json['name'] ?? '', 
      
      email: json['email'] ?? '',
      role: json['role'],
      
      // Sequelize secara default menggunakan snake_case untuk foreign key
      shopId: json['shop_id'] is String ? int.tryParse(json['shop_id']) : json['shop_id'],
    );
  }

  /// Method untuk mengubah Object Dart kembali ke JSON 
  /// Sangat berguna jika Anda ingin menyimpan data user ke local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'role': role,
      'shop_id': shopId,
    };
  }

  /// Helper method untuk mempermudah pengecekan role di UI
  bool get isOwner => role == 'owner';
  bool get isKasir => role == 'kasir';
}
