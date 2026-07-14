import 'package:hive/hive.dart';

class HabitStreak {
  HabitStreak({
    required this.habitId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDueDate,
  });

  final String habitId;
  final int currentStreak;
  final int longestStreak;

  /// Last due date the habit was completed, `"yyyy-MM-dd"`.
  final String? lastCompletedDueDate;

  HabitStreak copyWith({
    String? habitId,
    int? currentStreak,
    int? longestStreak,
    String? lastCompletedDueDate,
  }) {
    return HabitStreak(
      habitId: habitId ?? this.habitId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDueDate:
          lastCompletedDueDate ?? this.lastCompletedDueDate,
    );
  }
}

class HabitStreakAdapter extends TypeAdapter<HabitStreak> {
  @override
  final int typeId = 3;

  @override
  HabitStreak read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitStreak(
      habitId: fields[0] as String,
      currentStreak: fields[1] as int,
      longestStreak: fields[2] as int,
      lastCompletedDueDate: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HabitStreak obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.habitId)
      ..writeByte(1)
      ..write(obj.currentStreak)
      ..writeByte(2)
      ..write(obj.longestStreak)
      ..writeByte(3)
      ..write(obj.lastCompletedDueDate);
  }
}
