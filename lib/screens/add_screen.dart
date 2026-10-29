import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/categories.dart';

class AddScreen extends StatefulWidget {
  final Transaction? tx;
  AddScreen({this.tx});
  @override
  _AddScreenState createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int _type = 1; // 0 = income, 1 = expense
  String _cat = 'Еда';
  DateTime _date = DateTime.now();
  @override
  void initState() {
    super.initState();
    if (widget.tx != null) {
      var t = widget.tx!;
      _titleCtrl.text = t.title;
      _amountCtrl.text = t.amount.toString();
      _noteCtrl.text = t.note;
      _type = t.type;
      _cat = t.category;
      _date = t.date;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    var t = Transaction(
      id: widget.tx?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text),
      category: _cat,
      type: _type,
      date: _date,
      note: _noteCtrl.text.trim(),
    );
    Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    var cats = _type == 0 ? incomeCats : expenseCats;
    if (!cats.contains(_cat)) _cat = cats.first;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tx == null ? 'Новая запись' : 'Редактировать'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text('Расход'),
                      selected: _type == 1,
                      onSelected: (v) => setState(() {
                        _type = 1;
                        _cat = expenseCats.first;
                      }),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text('Доход'),
                      selected: _type == 0,
                      onSelected: (v) => setState(() {
                        _type = 0;
                        _cat = incomeCats.first;
                      }),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите название' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Сумма',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите сумму';
                  if (double.tryParse(v) == null) return 'Некорректная сумма';
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _cat,
                decoration: InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                ),
                items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _cat = v);
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  labelText: 'Описание (необязательно)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today),
                title: Text('Дата'),
                subtitle: Text(
                  '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                ),
                onTap: () async {
                  var p = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (p != null) setState(() => _date = p);
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.tx == null ? 'Добавить' : 'Сохранить',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}