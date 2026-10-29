import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../repository/repo.dart';

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final fmt = NumberFormat.currency(locale: 'ru_RU', symbol: ' P', decimalDigits: 0);
  final fmtDate = DateFormat('dd.MM.yyyy');
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();

  @override
  void initState() {
    super.initState();
    _setCurrentMonth();
  }

  void _setCurrentMonth() {
    var now = DateTime.now();
    setState(() {
      _from = DateTime(now.year, now.month, 1);
      _to = DateTime(now.year, now.month + 1, 0);
    });
  }

  Future<void> _pickFrom() async {
    var picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _from = picked;
        if (_from.isAfter(_to)) {
          _to = _from;
        }
      });
    }
  }

  Future<void> _pickTo() async {
    var picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _to = picked;
        if (_to.isBefore(_from)) {
          _from = _to;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var incByCat = Repo.byCategoryInPeriod(0, _from, _to);
    var expByCat = Repo.byCategoryInPeriod(1, _from, _to);
    var incByDay = Repo.byDayInPeriod(0, _from, _to);
    var expByDay = Repo.byDayInPeriod(1, _from, _to);
    var totalInc = Repo.sumIncomeInPeriod(_from, _to);
    var totalExp = Repo.sumExpenseInPeriod(_from, _to);
    return Scaffold(
      appBar: AppBar(
        title: Text('Статистика'),
        actions: [
          IconButton(
            icon: Icon(Icons.today),
            tooltip: 'Текущий месяц',
            onPressed: _setCurrentMonth,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Период',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _dateField('С', _from, _pickFrom),
                ),
                SizedBox(width: 8),
                Text('—', style: TextStyle(fontSize: 20, color: Colors.grey)),
                SizedBox(width: 8),
                Expanded(
                  child: _dateField('По', _to, _pickTo),
                ),
              ],
            ),
            SizedBox(height: 16),
            _sectionTitle('Динамика за период'),
            SizedBox(height: 8),
            _combinedLineChart(incByDay, expByDay),
            SizedBox(height: 24),
            _sectionTitle('Расходы по категориям'),
            SizedBox(height: 8),
            expByCat.isEmpty
                ? _emptyBox('Нет данных о расходах')
                : _pieChart(expByCat),
            SizedBox(height: 24),
            _sectionTitle('Доходы по категориям'),
            SizedBox(height: 8),
            incByCat.isEmpty
                ? _emptyBox('Нет данных о доходах')
                : _pieChart(incByCat),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(
          fmtDate.format(date),
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(text, style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _combinedLineChart(
    List<Map<String, dynamic>> incData,
    List<Map<String, dynamic>> expData,
  ) {
    if (incData.isEmpty && expData.isEmpty) {
      return _emptyBox('Нет данных за выбранный период');
    }
    var maxVal = 0.0;
    for (var d in incData) {
      if (d['sum'] > maxVal) maxVal = d['sum'];
    }
    for (var d in expData) {
      if (d['sum'] > maxVal) maxVal = d['sum'];
    }
    if (maxVal == 0) maxVal = 100;
    var incSpots = <FlSpot>[];
    var expSpots = <FlSpot>[];
    for (int i = 0; i < incData.length; i++) {
      incSpots.add(FlSpot(i.toDouble(), incData[i]['sum']));
    }
    for (int i = 0; i < expData.length; i++) {
      expSpots.add(FlSpot(i.toDouble(), expData[i]['sum']));
    }
    return Container(
      height: 250,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)],
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxVal * 1.2,
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _getInterval(incData.length),
                getTitlesWidget: (v, meta) {
                  var i = v.toInt();
                  if (i >= 0 && i < incData.length) {
                    var d = incData[i]['date'] as DateTime;
                    return Text(
                      '${d.day}.${d.month}',
                      style: TextStyle(fontSize: 10),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: incSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.15),
              ),
            ),
            LineChartBarData(
              spots: expSpots,
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
  double _getInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 31) return 5;
    return 10;
  }

  Widget _pieChart(Map<String, double> data) {
    var entries = data.entries.toList();
    var total = entries.fold(0.0, (s, e) => s + e.value);
    var colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.pink, Colors.amber,
      Colors.indigo, Colors.cyan,
    ];
    var sections = <PieChartSectionData>[];
    for (int i = 0; i < entries.length; i++) {
      var e = entries[i];
      var percent = (e.value / total * 100).toStringAsFixed(0);
      sections.add(
        PieChartSectionData(
          value: e.value,
          title: '$percent%',
          color: colors[i % colors.length],
          radius: 80,
          titleStyle: TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    }
    return Column(
      children: [
        Container(
          height: 220,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)],
          ),
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: entries.asMap().entries.map((e) {
            var i = e.key;
            var entry = e.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '${entry.key}: ${fmt.format(entry.value)}',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}