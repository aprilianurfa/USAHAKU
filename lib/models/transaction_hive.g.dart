// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionHiveAdapter extends TypeAdapter<TransactionHive> {
  @override
  final int typeId = 3;

  @override
  TransactionHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionHive(
      id: fields[0] as String,
      tanggal: fields[1] as DateTime,
      pelangganId: fields[2] as String?,
      namaPelanggan: fields[3] as String?,
      totalBayar: fields[4] as int,
      bayar: fields[5] as int,
      kembalian: fields[6] as int,
      items: (fields[7] as List).cast<TransactionItemHive>(),
      isSynced: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionHive obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tanggal)
      ..writeByte(2)
      ..write(obj.pelangganId)
      ..writeByte(3)
      ..write(obj.namaPelanggan)
      ..writeByte(4)
      ..write(obj.totalBayar)
      ..writeByte(5)
      ..write(obj.bayar)
      ..writeByte(6)
      ..write(obj.kembalian)
      ..writeByte(7)
      ..write(obj.items)
      ..writeByte(8)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionItemHiveAdapter extends TypeAdapter<TransactionItemHive> {
  @override
  final int typeId = 4;

  @override
  TransactionItemHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionItemHive(
      productId: fields[0] as String,
      namaBarang: fields[1] as String,
      harga: fields[2] as int,
      qty: fields[3] as int,
      subtotal: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionItemHive obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.namaBarang)
      ..writeByte(2)
      ..write(obj.harga)
      ..writeByte(3)
      ..write(obj.qty)
      ..writeByte(4)
      ..write(obj.subtotal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionItemHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
