// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonTaskAdapter extends TypeAdapter<LessonTask> {
  @override
  final int typeId = 5;

  @override
  LessonTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonTask(
      id: fields[0] as String,
      type: fields[1] as TaskType,
      questionText: fields[2] as String,
      options: (fields[3] as List).cast<String>(),
      correctAnswerIndex: fields[4] as int,
      pairs: (fields[5] as List)
          .map((dynamic e) => (e as Map).cast<String, String>())
          .toList(),
      sentenceParts: (fields[6] as List).cast<String>(),
      expectedSentence: fields[7] as String,
      nativeWord: fields[8] as String,
      phoneticGuide: fields[9] as String,
      hintMetadata: fields[10] as String,
      audioUrl: fields[11] as String?,
      imageUrl: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LessonTask obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.questionText)
      ..writeByte(3)
      ..write(obj.options)
      ..writeByte(4)
      ..write(obj.correctAnswerIndex)
      ..writeByte(5)
      ..write(obj.pairs)
      ..writeByte(6)
      ..write(obj.sentenceParts)
      ..writeByte(7)
      ..write(obj.expectedSentence)
      ..writeByte(8)
      ..write(obj.nativeWord)
      ..writeByte(9)
      ..write(obj.phoneticGuide)
      ..writeByte(10)
      ..write(obj.hintMetadata)
      ..writeByte(11)
      ..write(obj.audioUrl)
      ..writeByte(12)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskTypeAdapter extends TypeAdapter<TaskType> {
  @override
  final int typeId = 4;

  @override
  TaskType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskType.multipleChoice;
      case 1:
        return TaskType.listening;
      case 2:
        return TaskType.matching;
      case 3:
        return TaskType.sentenceReordering;
      case 4:
        return TaskType.pronunciation;
      case 5:
        return TaskType.vocabulary;
      case 6:
        return TaskType.scenario;
      default:
        return TaskType.multipleChoice;
    }
  }

  @override
  void write(BinaryWriter writer, TaskType obj) {
    switch (obj) {
      case TaskType.multipleChoice:
        writer.writeByte(0);
        break;
      case TaskType.listening:
        writer.writeByte(1);
        break;
      case TaskType.matching:
        writer.writeByte(2);
        break;
      case TaskType.sentenceReordering:
        writer.writeByte(3);
        break;
      case TaskType.pronunciation:
        writer.writeByte(4);
        break;
      case TaskType.vocabulary:
        writer.writeByte(5);
        break;
      case TaskType.scenario:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}


