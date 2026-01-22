import 'package:hive/hive.dart';

part 'transaction_hive.g.dart';

@HiveType(typeId: 3)
class TransactionHive extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime tanggal;

  @HiveField(2)
  final String? pelangganId;

  @HiveField(3)
  final String? namaPelanggan;

  @HiveField(4)
  final int totalBayar;

  @HiveField(5)
  final int bayar;

  @HiveField(6)
  final int kembalian;

  @HiveField(7)
  final List<TransactionItemHive> items;

  @HiveField(8)
  bool isSynced;

  TransactionHive({
    required this.id,
    required this.tanggal,
    this.pelangganId,
    this.namaPelanggan,
    required this.totalBayar,
    required this.bayar,
    required this.kembalian,
    required this.items,
    this.isSynced = false,
  });
}

@HiveType(typeId: 4)
class TransactionItemHive extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final String namaBarang;

  @HiveField(2)
  final int harga;

  @HiveField(3)
  final int qty;

  @HiveField(4)
  final int subtotal;

  TransactionItemHive({
    required this.productId,
    required this.namaBarang,
    required this.harga,
    required this.qty,
    required this.subtotal,
  });
}
