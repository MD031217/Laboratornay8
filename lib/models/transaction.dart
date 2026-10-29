import 'package:hive/hive.dart';
part 'transaction.g.dart';
enum TxType { income, expense }
@HiveType(typeId: 0)
class Transaction {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  double amount;
  @HiveField(3)
  String category;
  @HiveField(4)
  int type; 
  @HiveField(5)
  DateTime date;
  @HiveField(6)
  String note;
  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.note = '',
  });
  TxType get txType => type == 0 ? TxType.income : TxType.expense;
}