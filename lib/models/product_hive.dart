import 'package:hive/hive.dart';
import 'product_model.dart';

part 'product_hive.g.dart';

@HiveType(typeId: 0)
class ProductHive extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String nama;

  @HiveField(2)
  final String kategoriId;

  @HiveField(3)
  final int harga;

  @HiveField(4)
  final int hargaDasar;

  @HiveField(5)
  final int stok;

  @HiveField(6)
  final int minStok;

  @HiveField(7)
  final String barcode;

  @HiveField(8)
  final bool isJasa;

  @HiveField(9)
  final String? image;

  @HiveField(10)
  final bool isDeleted;

  ProductHive({
    required this.id,
    required this.nama,
    required this.kategoriId,
    required this.harga,
    required this.hargaDasar,
    required this.stok,
    required this.minStok,
    required this.barcode,
    this.isJasa = false,
    this.image,
    this.isDeleted = false,
  });

  factory ProductHive.fromMap(Map<String, dynamic> map) {
    return ProductHive(
      id: map['id'].toString(),
      nama: map['nama'],
      kategoriId: (map['kategori_id'] ?? map['kategoriId'])?.toString() ?? '',
      harga: map['harga'] ?? 0,
      hargaDasar: map['harga_dasar'] ?? 0,
      stok: map['stok'] ?? 0,
      minStok: map['min_stok'] ?? 0,
      barcode: map['barcode'] ?? '',
      isJasa: map['is_jasa'] ?? false,
      image: map['image'],
      isDeleted: map['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kategori_id': kategoriId,
      'harga': harga,
      'harga_dasar': hargaDasar,
      'stok': stok,
      'min_stok': minStok,
      'barcode': barcode,
      'is_jasa': isJasa,
      'image': image,
      'is_deleted': isDeleted,
    };
  }

  Barang toBarang() {
    return Barang(
      id: id,
      nama: nama,
      kategoriId: kategoriId,
      harga: harga,
      hargaDasar: hargaDasar,
      stok: stok,
      minStok: minStok,
      barcode: barcode,
      isJasa: isJasa,
      image: image,
    );
  }
}
