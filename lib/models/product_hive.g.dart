// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductHiveAdapter extends TypeAdapter<ProductHive> {
  @override
  final int typeId = 0;

  @override
  ProductHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductHive(
      id: fields[0] as String,
      nama: fields[1] as String,
      kategoriId: fields[2] as String,
      harga: fields[3] as int,
      hargaDasar: fields[4] as int,
      stok: fields[5] as int,
      minStok: fields[6] as int,
      barcode: fields[7] as String,
      isJasa: fields[8] as bool,
      image: fields[9] as String?,
      isDeleted: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ProductHive obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nama)
      ..writeByte(2)
      ..write(obj.kategoriId)
      ..writeByte(3)
      ..write(obj.harga)
      ..writeByte(4)
      ..write(obj.hargaDasar)
      ..writeByte(5)
      ..write(obj.stok)
      ..writeByte(6)
      ..write(obj.minStok)
      ..writeByte(7)
      ..write(obj.barcode)
      ..writeByte(8)
      ..write(obj.isJasa)
      ..writeByte(9)
      ..write(obj.image)
      ..writeByte(10)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
