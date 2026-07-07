// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction()
      ..amount = fields[0] as double
      ..date = fields[1] as DateTime
      ..tags = (fields[2] as List).cast<String>()
      ..group = (fields[3] as List).cast<String>()
      ..party = fields[4] as String
      ..isCredit = fields[5] as bool
      ..note = fields[6] as String?
      ..smsId = fields[7] as String?;
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.tags)
      ..writeByte(3)
      ..write(obj.group)
      ..writeByte(4)
      ..write(obj.party)
      ..writeByte(5)
      ..write(obj.isCredit)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.smsId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
