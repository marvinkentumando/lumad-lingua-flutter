// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dictionary_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DictionaryEntryAdapter extends TypeAdapter<DictionaryEntry> {
  @override
  final int typeId = 2;

  @override
  DictionaryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DictionaryEntry(
      id: fields[0] as String,
      indigenousWord: fields[1] as String,
      phonetic: fields[2] as String?,
      translation: fields[3] as String,
      translationFilipino: fields[4] as String,
      partOfSpeech: fields[5] as PartOfSpeech,
      language: fields[6] as String,
      usageContext: fields[7] as String,
      usageExampleNative: fields[8] as String?,
      usageExampleTranslation: fields[9] as String?,
      audioUrl: fields[10] as String?,
      status: fields[11] as ValidationStatus,
      validatorRole: fields[12] as String?,
      validatorId: fields[13] as String?,
      validatorFeedback: fields[14] as String?,
      contributorName: fields[15] as String?,
      contributorId: fields[16] as String?,
      validatedAt: fields[17] as DateTime?,
      submittedAt: fields[18] as DateTime?,
      validatorAudioTipUrl: fields[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DictionaryEntry obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.indigenousWord)
      ..writeByte(2)
      ..write(obj.phonetic)
      ..writeByte(3)
      ..write(obj.translation)
      ..writeByte(4)
      ..write(obj.translationFilipino)
      ..writeByte(5)
      ..write(obj.partOfSpeech)
      ..writeByte(6)
      ..write(obj.language)
      ..writeByte(7)
      ..write(obj.usageContext)
      ..writeByte(8)
      ..write(obj.usageExampleNative)
      ..writeByte(9)
      ..write(obj.usageExampleTranslation)
      ..writeByte(10)
      ..write(obj.audioUrl)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.validatorRole)
      ..writeByte(13)
      ..write(obj.validatorId)
      ..writeByte(14)
      ..write(obj.validatorFeedback)
      ..writeByte(15)
      ..write(obj.contributorName)
      ..writeByte(16)
      ..write(obj.contributorId)
      ..writeByte(17)
      ..write(obj.validatedAt)
      ..writeByte(18)
      ..write(obj.submittedAt)
      ..writeByte(19)
      ..write(obj.validatorAudioTipUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictionaryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PartOfSpeechAdapter extends TypeAdapter<PartOfSpeech> {
  @override
  final int typeId = 0;

  @override
  PartOfSpeech read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PartOfSpeech.noun;
      case 1:
        return PartOfSpeech.verb;
      case 2:
        return PartOfSpeech.adjective;
      case 3:
        return PartOfSpeech.phrase;
      default:
        return PartOfSpeech.noun;
    }
  }

  @override
  void write(BinaryWriter writer, PartOfSpeech obj) {
    switch (obj) {
      case PartOfSpeech.noun:
        writer.writeByte(0);
        break;
      case PartOfSpeech.verb:
        writer.writeByte(1);
        break;
      case PartOfSpeech.adjective:
        writer.writeByte(2);
        break;
      case PartOfSpeech.phrase:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartOfSpeechAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ValidationStatusAdapter extends TypeAdapter<ValidationStatus> {
  @override
  final int typeId = 1;

  @override
  ValidationStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ValidationStatus.pending;
      case 1:
        return ValidationStatus.approved;
      case 2:
        return ValidationStatus.flagged;
      case 3:
        return ValidationStatus.rejected;
      default:
        return ValidationStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, ValidationStatus obj) {
    switch (obj) {
      case ValidationStatus.pending:
        writer.writeByte(0);
        break;
      case ValidationStatus.approved:
        writer.writeByte(1);
        break;
      case ValidationStatus.flagged:
        writer.writeByte(2);
        break;
      case ValidationStatus.rejected:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
