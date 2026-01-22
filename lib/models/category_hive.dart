import 'package:hive/hive.dart';
import 'category_model.dart';

part 'category_hive.g.dart';

@HiveType(typeId: 1)
class CategoryHive extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String nama;

  @HiveField(2)
  final bool isDeleted;

  CategoryHive({
    required this.id,
    required this.nama,
    this.isDeleted = false,
  });

  factory CategoryHive.fromMap(Map<String, dynamic> map) {
    return CategoryHive(
      id: map['id'].toString(),
      nama: map['nama'],
      isDeleted: map['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'is_deleted': isDeleted,
    };
  }

  factory CategoryHive.fromKategori(Kategori k) {
    return CategoryHive(
      id: k.id,
      nama: k.nama,
      isDeleted: k.isDeleted,
    );
  }

  Kategori toKategori() {
    return Kategori(
      id: id,
      nama: nama,
      isDeleted: isDeleted,
    );
  }
}
