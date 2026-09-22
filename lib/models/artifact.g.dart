// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArtifactAdapter extends TypeAdapter<Artifact> {
  @override
  final int typeId = 8;

  @override
  Artifact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Artifact(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      emoji: fields[3] as String,
      imageUrl: fields[4] as String,
      type: fields[5] as String,
      culturalNote: fields[6] as String?,
      tier: fields[7] as ArtifactTier,
      rarity: fields[8] as int,
      requirementType: fields[9] as ArtifactRequirementType,
      currentProgress: fields[10] as int,
      targetValue: fields[11] as int,
      isEarned: fields[12] as bool,
      crystalCost: fields[13] as int,
      passiveBonus: fields[14] as String?,
      isAvailableInShop: fields[15] as bool,
      earnedAt: fields[16] as DateTime?,
      legend: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Artifact obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.emoji)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.culturalNote)
      ..writeByte(7)
      ..write(obj.tier)
      ..writeByte(8)
      ..write(obj.rarity)
      ..writeByte(9)
      ..write(obj.requirementType)
      ..writeByte(10)
      ..write(obj.currentProgress)
      ..writeByte(11)
      ..write(obj.targetValue)
      ..writeByte(12)
      ..write(obj.isEarned)
      ..writeByte(13)
      ..write(obj.crystalCost)
      ..writeByte(14)
      ..write(obj.passiveBonus)
      ..writeByte(15)
      ..write(obj.isAvailableInShop)
      ..writeByte(16)
      ..write(obj.earnedAt)
      ..writeByte(17)
      ..write(obj.legend);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ArtifactTierAdapter extends TypeAdapter<ArtifactTier> {
  @override
  final int typeId = 6;

  @override
  ArtifactTier read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ArtifactTier.common;
      case 1:
        return ArtifactTier.rare;
      case 2:
        return ArtifactTier.epic;
      case 3:
        return ArtifactTier.legendary;
      case 4:
        return ArtifactTier.sacred;
      case 5:
        return ArtifactTier.ancient;
      default:
        return ArtifactTier.common;
    }
  }

  @override
  void write(BinaryWriter writer, ArtifactTier obj) {
    switch (obj) {
      case ArtifactTier.common:
        writer.writeByte(0);
        break;
      case ArtifactTier.rare:
        writer.writeByte(1);
        break;
      case ArtifactTier.epic:
        writer.writeByte(2);
        break;
      case ArtifactTier.legendary:
        writer.writeByte(3);
        break;
      case ArtifactTier.sacred:
        writer.writeByte(4);
        break;
      case ArtifactTier.ancient:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactTierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ArtifactRequirementTypeAdapter
    extends TypeAdapter<ArtifactRequirementType> {
  @override
  final int typeId = 7;

  @override
  ArtifactRequirementType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ArtifactRequirementType.xp;
      case 1:
        return ArtifactRequirementType.lessons;
      case 2:
        return ArtifactRequirementType.words;
      case 3:
        return ArtifactRequirementType.streak;
      case 4:
        return ArtifactRequirementType.mistCrystals;
      default:
        return ArtifactRequirementType.xp;
    }
  }

  @override
  void write(BinaryWriter writer, ArtifactRequirementType obj) {
    switch (obj) {
      case ArtifactRequirementType.xp:
        writer.writeByte(0);
        break;
      case ArtifactRequirementType.lessons:
        writer.writeByte(1);
        break;
      case ArtifactRequirementType.words:
        writer.writeByte(2);
        break;
      case ArtifactRequirementType.streak:
        writer.writeByte(3);
        break;
      case ArtifactRequirementType.mistCrystals:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactRequirementTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
