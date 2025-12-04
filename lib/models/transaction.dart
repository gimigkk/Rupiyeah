import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String tagId;

  @HiveField(3)
  String description;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String type; // 'income', 'expense', 'withdrawal', 'surplus'

  @HiveField(6)
  String? paymentMethod; // 'cash', 'bank'

  @HiveField(7)
  String? attachmentPath; // Path to attached file

  Transaction({
    required this.id,
    required this.amount,
    required this.tagId,
    required this.description,
    required this.date,
    required this.type,
    this.paymentMethod,
    this.attachmentPath,
  });
}
