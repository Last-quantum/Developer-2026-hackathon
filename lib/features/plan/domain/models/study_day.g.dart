// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_day.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudyDayAdapter extends TypeAdapter<StudyDay> {
  @override
  final int typeId = 0;

  @override
  StudyDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyDay(
      dayNumber: fields[0] as int,
      title: fields[1] as String,
      duration: fields[2] as String,
      videoLink: fields[3] as String,
    )
      ..detailedContent = fields[4] as String
      ..isAddedToCalendar = fields[5] as bool;
  }

  @override
  void write(BinaryWriter writer, StudyDay obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.dayNumber)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.videoLink)
      ..writeByte(4)
      ..write(obj.detailedContent)
      ..writeByte(5)
      ..write(obj.isAddedToCalendar);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
