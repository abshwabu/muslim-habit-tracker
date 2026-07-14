import 'package:hive/hive.dart';

/// How often a habit is due.
enum FrequencyType {
  daily,
  specificWeekdays,
}

class FrequencyTypeAdapter extends TypeAdapter<FrequencyType> {
  @override
  final int typeId = 0;

  @override
  FrequencyType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FrequencyType.daily;
      case 1:
        return FrequencyType.specificWeekdays;
      default:
        return FrequencyType.daily;
    }
  }

  @override
  void write(BinaryWriter writer, FrequencyType obj) {
    switch (obj) {
      case FrequencyType.daily:
        writer.writeByte(0);
      case FrequencyType.specificWeekdays:
        writer.writeByte(1);
    }
  }
}
