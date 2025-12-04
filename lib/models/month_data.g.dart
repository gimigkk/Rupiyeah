// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'month_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonthDataAdapter extends TypeAdapter<MonthData> {
  @override
  final int typeId = 2;

  @override
  MonthData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthData(
      id: fields[0] as String,
      walletCash: fields[1] as double,
      bankBalance: fields[2] as double,
      totalIncome: fields[3] as double,
      totalExpenses: fields[4] as double,
      isAutoDailyBudget: fields[5] as bool,
      manualDailyBudget: fields[6] as double,
      transactionIds: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MonthData obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.walletCash)
      ..writeByte(2)
      ..write(obj.bankBalance)
      ..writeByte(3)
      ..write(obj.totalIncome)
      ..writeByte(4)
      ..write(obj.totalExpenses)
      ..writeByte(5)
      ..write(obj.isAutoDailyBudget)
      ..writeByte(6)
      ..write(obj.manualDailyBudget)
      ..writeByte(7)
      ..write(obj.transactionIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
