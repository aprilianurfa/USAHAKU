// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PurchaseHiveAdapter extends TypeAdapter<PurchaseHive> {
  @override
  final int typeId = 10;

  @override
  PurchaseHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseHive(
      id: fields[0] as String,
      tanggal: fields[1] as DateTime,
      supplier: fields[2] as String,
      totalBiaya: fields[3] as int,
      keterangan: fields[4] as String,
      items: (fields[5] as List).cast<PurchaseItemHive>(),
      isSynced: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseHive obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tanggal)
      ..writeByte(2)
      ..write(obj.supplier)
      ..writeByte(3)
      ..write(obj.totalBiaya)
      ..writeByte(4)
      ..write(obj.keterangan)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(6)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PurchaseItemHiveAdapter extends TypeAdapter<PurchaseItemHive> {
  @override
  final int typeId = 11;

  @override
  PurchaseItemHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseItemHive(
      productId: fields[0] as String,
      productName: fields[1] as String,
      jumlah: fields[2] as int,
      hargaBeli: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseItemHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.jumlah)
      ..writeByte(3)
      ..write(obj.hargaBeli);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseItemHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
