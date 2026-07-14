import 'package:hive/hive.dart';

class HabitLog {
  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    this.completed = false,
  });

  final String id;
  final String habitId;

  /// Date key in `"yyyy-MM-dd"` format.
  final String date;
  final bool completed;

  HabitLog copyWith({
    String? id,
    String? habitId,
    String? date,
    bool? completed,
  }) {
    return HabitLog(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
    );
  }
}

class HabitLogAdapter extends TypeAdapter<HabitLog> {
  @override
  final int typeId = 2;

  @override
  HabitLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitLog(
      id: fields[0] as String,
      habitId: fields[1] as String,
      date: fields[2] as String,
      completed: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HabitLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.habitId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.completed);
  }
}
