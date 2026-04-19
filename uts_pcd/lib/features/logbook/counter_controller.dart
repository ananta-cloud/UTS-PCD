import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; 

class CounterController {
  int _counter = 0;
  int _step = 1;
  final List<Map<String, dynamic>> _history = [];
  String? _currentUser; 

  int get value => _counter;
  int get step => _step;
  List<Map<String, dynamic>> get history => _history.reversed.take(5).toList();

  Future<void> loadData(String username) async {
    _currentUser = username;
    final prefs = await SharedPreferences.getInstance();

    final counterKey = '${username}_counter';
    final historyKey = '${username}_history';

    _counter = prefs.getInt(counterKey) ?? 0;

    final List<String>? historyStringList = prefs.getStringList(historyKey);
    _history.clear(); 

    if (historyStringList != null) {
      for (var jsonStr in historyStringList) {
        Map<String, dynamic> item = jsonDecode(jsonStr);
        
        if (item['color'] is int) {
          item['color'] = Color(item['color']);
        }
        _history.add(item);
      }
    }
  }

  Future<void> _saveData() async {
    if (_currentUser == null) return; 
    
    final prefs = await SharedPreferences.getInstance();
    final counterKey = '${_currentUser}_counter';
    final historyKey = '${_currentUser}_history';

    await prefs.setInt(counterKey, _counter);

    List<String> encodedHistory = _history.map((item) {
      Map<String, dynamic> jsonItem = Map.from(item); 
      if (jsonItem['color'] is Color) {
        jsonItem['color'] = (jsonItem['color'] as Color).value; 
      }
      return jsonEncode(jsonItem);
    }).toList();

    await prefs.setStringList(historyKey, encodedHistory);
  }

  void setStep(int newStep) {
    if (newStep > 0) {
      _step = newStep;
    }
  }

  void increment() {
    _counter += _step;
    _addHistory("Nilai ditambah sebesar $_step", Colors.green);
    _saveData();
  }

  void decrement() {
    if (_counter >= _step) {
      _counter -= _step;
      _addHistory("Nilai dikurang sebesar $_step", Colors.red);
      _saveData(); 
    } else if (_counter == 0) {
      _addHistory("Nilai sudah di 0", Colors.red);
      _saveData(); 
    } else if (_counter < _step) {
      _addHistory("Nilai terlalu kecil, tidak bisa dikurang", Colors.red);
      _saveData(); 
    }
  }

  void reset() {
    _counter = 0;
    _addHistory("Nilai direset", Colors.red);
    _saveData(); 
  }

  void _addHistory(String action, Color color) {
    final now = DateFormat.Hm().format(DateTime.now());
    _history.add({"text": action, "color": color, "time": now});
  }
}