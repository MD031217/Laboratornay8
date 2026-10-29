import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../repository/repo.dart';
import '../utils/categories.dart';
import 'add_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> txs = [];
  String filter = 'Все';
  final fmt = NumberFormat.currency(locale: 'ru_RU', symbol: ' P', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      txs = Repo.getAll();
    });
  }

  void _add(Transaction t) async {
    await Repo.add(t);
    _load();
  }

  void _update(Transaction t) async {
    await Repo.update(t);
    _load();
  }

  void _delete(String id) async {
    await Repo.delete(id);
    _load();
  }

  List<Transaction> get filtered {
    if (filter == 'Все') return txs;
    return txs.where((t) => t.category == filter).toList();
  }

  String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    var inc = Repo.sumIncome();
    var exp = Repo.sumExpense();
    var bal = Repo.balance();

    return Scaffold(
      appBar: AppBar(
        title: Text('Финансы'),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart, size: 24),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StatsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade700],
              ),
            ),
            child: Column(
              children: [
                Text('Баланс', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 8),
                Text(
                  fmt.format(bal),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Доходы', style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 4),
                        Text(
                          fmt.format(inc),
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Расходы', style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 4),
                        Text(
                          fmt.format(exp),
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                _chip('Все'),
                ...allCats.map((c) => _chip(c)),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('Нет записей', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      var t = filtered[i];
                      var isInc = t.type == 0;
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isInc ? Colors.green.shade100 : Colors.red.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isInc ? Icons.arrow_upward : Icons.arrow_downward,
                              color: isInc ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(t.title, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${t.category} \u2022 ${_fmtDate(t.date)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isInc ? '+' : '-'}${fmt.format(t.amount)}',
                                style: TextStyle(
                                  color: isInc ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              IconButton(
                                icon: Icon(Icons.edit, size: 20),
                                onPressed: () async {
                                  var r = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddScreen(tx: t),
                                    ),
                                  );
                                  if (r != null) _update(r);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _confirmDelete(t),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          var r = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddScreen()),
          );
          if (r != null) _add(r);
        },
      ),
    );
  }

  Widget _chip(String label) {
    var sel = filter == label;
    return Padding(
      padding: EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => setState(() => filter = label),
      ),
    );
  }

  void _confirmDelete(Transaction t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить запись?'),
        content: Text('${t.title} - ${fmt.format(t.amount)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _delete(t.id);
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}