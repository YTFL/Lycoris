import 'package:hive/hive.dart';
import '../../features/tracker/domain/models/additional_expense.dart';
import '../../features/tracker/domain/models/game_entry.dart';
import '../../features/tracker/domain/models/game_status.dart';
import '../../features/tracker/domain/models/storefront.dart';

class StorefrontAdapter extends TypeAdapter<Storefront> {
  @override
  final int typeId = 0;

  @override
  Storefront read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= 0 && index < Storefront.values.length) {
      return Storefront.values[index];
    }
    return Storefront.other;
  }

  @override
  void write(BinaryWriter writer, Storefront obj) {
    writer.writeByte(obj.index);
  }
}

class GameStatusAdapter extends TypeAdapter<GameStatus> {
  @override
  final int typeId = 1;

  @override
  GameStatus read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= 0 && index < GameStatus.values.length) {
      return GameStatus.values[index];
    }
    return GameStatus.backlog;
  }

  @override
  void write(BinaryWriter writer, GameStatus obj) {
    writer.writeByte(obj.index);
  }
}

class AdditionalExpenseAdapter extends TypeAdapter<AdditionalExpense> {
  @override
  final int typeId = 2;

  @override
  AdditionalExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AdditionalExpense(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
    );
  }

  @override
  void write(BinaryWriter writer, AdditionalExpense obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date.millisecondsSinceEpoch);
  }
}

class GameEntryAdapter extends TypeAdapter<GameEntry> {
  @override
  final int typeId = 3;

  @override
  GameEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return GameEntry(
      id: fields[0] as String,
      igdbId: fields[1] as int? ?? 0,
      title: fields[2] as String,
      coverUrl: fields[3] as String?,
      genres: (fields[4] as List?)?.cast<String>() ?? [],
      storefront: fields[5] as Storefront? ?? Storefront.steam,
      status: fields[6] as GameStatus? ?? GameStatus.backlog,
      totalMinutesPlayed: fields[7] as int? ?? 0,
      basePrice: (fields[8] as num?)?.toDouble() ?? 0.0,
      currency: fields[9] as String? ?? 'USD',
      additionalExpenses: (fields[10] as List?)?.cast<AdditionalExpense>() ?? [],
      personalRating: (fields[11] as num?)?.toDouble() ?? 0.0,
      notes: fields[12] as String? ?? '',
      addedAt: DateTime.fromMillisecondsSinceEpoch(fields[13] as int),
      completedAt: fields[14] != null ? DateTime.fromMillisecondsSinceEpoch(fields[14] as int) : null,
      updatedAt: fields[15] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[15] as int)
          : DateTime.fromMillisecondsSinceEpoch(fields[13] as int),
      isCustomEntry: fields[16] as bool? ?? false,
      customCoverPath: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GameEntry obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.igdbId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.coverUrl)
      ..writeByte(4)
      ..write(obj.genres)
      ..writeByte(5)
      ..write(obj.storefront)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.totalMinutesPlayed)
      ..writeByte(8)
      ..write(obj.basePrice)
      ..writeByte(9)
      ..write(obj.currency)
      ..writeByte(10)
      ..write(obj.additionalExpenses)
      ..writeByte(11)
      ..write(obj.personalRating)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.addedAt.millisecondsSinceEpoch)
      ..writeByte(14)
      ..write(obj.completedAt?.millisecondsSinceEpoch)
      ..writeByte(15)
      ..write(obj.updatedAt.millisecondsSinceEpoch)
      ..writeByte(16)
      ..write(obj.isCustomEntry)
      ..writeByte(17)
      ..write(obj.customCoverPath);
  }
}
