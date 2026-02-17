// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_week.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudyWeekAdapter extends TypeAdapter<StudyWeek> {
  @override
  final int typeId = 1;

  @override
  StudyWeek read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyWeek(
      weekNumber: fields[0] as int,
      title: fields[1] as String,
      content: fields[2] as String,
    )..days = (fields[3] as List).cast<StudyDay>();
  }

  @override
  void write(BinaryWriter writer, StudyWeek obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.weekNumber)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.days);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyWeekAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
