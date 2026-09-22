// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineProgressAdapter extends TypeAdapter<OfflineProgress> {
  @override
  final int typeId = 30;

  @override
  OfflineProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineProgress(
      lessonId: fields[0] as String,
      score: fields[1] as int,
      stars: fields[2] as int,
      taskPerformance: (fields[3] as Map).cast<String, int>(),
      bonusXp: fields[4] as int,
      timestamp: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineProgress obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.lessonId)
      ..writeByte(1)
      ..write(obj.score)
      ..writeByte(2)
      ..write(obj.stars)
      ..writeByte(3)
      ..write(obj.taskPerformance)
      ..writeByte(4)
      ..write(obj.bonusXp)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
