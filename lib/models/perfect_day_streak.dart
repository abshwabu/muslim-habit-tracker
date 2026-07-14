import 'package:hive/hive.dart';

/// Tracks days where every *due* habit was completed (all habits combined).
class PerfectDayStreak {
  PerfectDayStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPerfectDate,
  });

  final int currentStreak;
  final int longestStreak;

  /// Last date that was a perfect day, `"yyyy-MM-dd"`.
  final String? lastPerfectDate;

  PerfectDayStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    String? lastPerfectDate,
  }) {
    return PerfectDayStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPerfectDate: lastPerfectDate ?? this.lastPerfectDate,
    );
  }
}

class PerfectDayStreakAdapter extends TypeAdapter<PerfectDayStreak> {
  @override
  final int typeId = 4;

  @override
  PerfectDayStreak read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PerfectDayStreak(
      currentStreak: fields[0] as int,
      longestStreak: fields[1] as int,
      lastPerfectDate: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PerfectDayStreak obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.currentStreak)
      ..writeByte(1)
      ..write(obj.longestStreak)
      ..writeByte(2)
      ..write(obj.lastPerfectDate);
  }
}
