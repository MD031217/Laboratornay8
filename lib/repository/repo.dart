import 'package:hive/hive.dart';
import '../models/transaction.dart';

class Repo {
  static Box<Transaction> get box => Hive.box<Transaction>('txs');

  static Future<void> add(Transaction t) async {
    await box.put(t.id, t);
  }

  static Future<void> update(Transaction t) async {
    await box.put(t.id, t);
  }

  static Future<void> delete(String id) async {
    await box.delete(id);
  }

  static List<Transaction> getAll() {
    var list = box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static List<Transaction> getByType(int type) {
    return getAll().where((t) => t.type == type).toList();
  }

  static List<Transaction> getByCategory(String cat) {
    return getAll().where((t) => t.category == cat).toList();
  }

  static List<Transaction> getByPeriod(DateTime from, DateTime to) {
    return getAll().where((t) {
      return t.date.isAfter(from.subtract(Duration(days: 1))) &&
             t.date.isBefore(to.add(Duration(days: 1)));
    }).toList();
  }

  static double sumIncome() {
    return getByType(0).fold(0.0, (s, t) => s + t.amount);
  }

  static double sumExpense() {
    return getByType(1).fold(0.0, (s, t) => s + t.amount);
  }

  static double balance() => sumIncome() - sumExpense();

  static Map<String, double> byCategory(int type) {
    var map = <String, double>{};
    for (var t in getByType(type)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  static Map<String, double> byCategoryInPeriod(int type, DateTime from, DateTime to) {
    var map = <String, double>{};
    for (var t in getByPeriod(from, to)) {
      if (t.type == type) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  static List<Map<String, dynamic>> byDayInPeriod(int type, DateTime from, DateTime to) {
    var result = <Map<String, dynamic>>[];
    var current = DateTime(from.year, from.month, from.day);
    var end = DateTime(to.year, to.month, to.day);
    while (!current.isAfter(end)) {
      var dayTxs = getAll().where((t) {
        return t.type == type &&
               t.date.year == current.year &&
               t.date.month == current.month &&
               t.date.day == current.day;
      });
      var sum = dayTxs.fold(0.0, (s, t) => s + t.amount);
      result.add({'date': current, 'sum': sum});
      current = current.add(Duration(days: 1));
    }
    return result;
  }

  static double sumIncomeInPeriod(DateTime from, DateTime to) {
    return getByPeriod(from, to)
        .where((t) => t.type == 0)
        .fold(0.0, (s, t) => s + t.amount);
  }

  static double sumExpenseInPeriod(DateTime from, DateTime to) {
    return getByPeriod(from, to)
        .where((t) => t.type == 1)
        .fold(0.0, (s, t) => s + t.amount);
  }
}