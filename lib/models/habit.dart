import 'package:hive/hive.dart';

import 'frequency_type.dart';

class Habit {
  Habit({
    required this.id,
    required this.name,
    this.arabicName,
    required this.icon,
    required this.colorHex,
    required this.frequencyType,
    List<int>? weekdays,
    this.isCustom = true,
    this.isActive = true,
    DateTime? createdAt,
  })  : weekdays = weekdays ?? const [],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String? arabicName;
  final String icon;
  final String colorHex;
  final FrequencyType frequencyType;

  /// Weekdays 1=Mon .. 7=Sun. Used when [frequencyType] is [FrequencyType.specificWeekdays].
  final List<int> weekdays;
  final bool isCustom;
  final bool isActive;
  final DateTime createdAt;

  Habit copyWith({
    String? id,
    String? name,
    String? arabicName,
    String? icon,
    String? colorHex,
    FrequencyType? frequencyType,
    List<int>? weekdays,
    bool? isCustom,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      arabicName: arabicName ?? this.arabicName,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      frequencyType: frequencyType ?? this.frequencyType,
      weekdays: weekdays ?? this.weekdays,
      isCustom: isCustom ?? this.isCustom,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 1;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      name: fields[1] as String,
      arabicName: fields[2] as String?,
      icon: fields[3] as String,
      colorHex: fields[4] as String,
      frequencyType: fields[5] as FrequencyType,
      weekdays: (fields[6] as List).cast<int>(),
      isCustom: fields[7] as bool,
      isActive: fields[8] as bool,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.arabicName)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.colorHex)
      ..writeByte(5)
      ..write(obj.frequencyType)
      ..writeByte(6)
      ..write(obj.weekdays)
      ..writeByte(7)
      ..write(obj.isCustom)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.createdAt);
  }
}
