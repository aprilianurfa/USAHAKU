import 'package:hive/hive.dart';
import 'purchase_model.dart';
import 'purchase_item_model.dart';

part 'purchase_hive.g.dart';

@HiveType(typeId: 10)
class PurchaseHive extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime tanggal;

  @HiveField(2)
  final String supplier;

  @HiveField(3)
  final int totalBiaya;

  @HiveField(4)
  final String keterangan;

  @HiveField(5)
  final List<PurchaseItemHive> items;

  @HiveField(6)
  final bool isSynced;

  PurchaseHive({
    required this.id,
    required this.tanggal,
    required this.supplier,
    required this.totalBiaya,
    required this.keterangan,
    required this.items,
    this.isSynced = false,
  });

  factory PurchaseHive.fromPembelian(Pembelian p) {
    return PurchaseHive(
      id: p.id,
      tanggal: p.tanggal,
      supplier: p.supplier,
      totalBiaya: p.totalBiaya,
      keterangan: p.keterangan,
      items: p.items.map((i) => PurchaseItemHive.fromPembelianItem(i)).toList(),
      isSynced: true, // If it comes from Pembelian (server), it's synced
    );
  }

  Pembelian toPembelian() {
    return Pembelian(
      id: id,
      tanggal: tanggal,
      supplier: supplier,
      totalBiaya: totalBiaya,
      keterangan: keterangan,
      // mapping items if needed
    );
  }
}

@HiveType(typeId: 11)
class PurchaseItemHive extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final int jumlah;

  @HiveField(3)
  final int hargaBeli;

  PurchaseItemHive({
    required this.productId,
    required this.productName,
    required this.jumlah,
    required this.hargaBeli,
  });

  factory PurchaseItemHive.fromPembelianItem(PembelianItem i) {
    return PurchaseItemHive(
      productId: i.productId,
      productName: i.productName ?? "",
      jumlah: i.jumlah,
      hargaBeli: i.hargaBeli,
    );
  }
}
