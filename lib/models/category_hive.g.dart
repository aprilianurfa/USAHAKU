// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryHiveAdapter extends TypeAdapter<CategoryHive> {
  @override
  final int typeId = 1;

  @override
  CategoryHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryHive(
      id: fields[0] as String,
      nama: fields[1] as String,
      isDeleted: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryHive obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nama)
      ..writeByte(2)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
