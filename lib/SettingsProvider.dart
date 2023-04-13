import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Map<String, int> _barcode = {}; // 바코드 카운트 배열

class SettingsProvider extends ChangeNotifier {
  final String _key = 'myKey'; //SharedPreferences 키
  //String _value = ''; //SharedPreferences 값
  SharedPreferences? prefs;

  Future<void> _loadData() async {
    prefs = await SharedPreferences.getInstance();
    final jsonString = prefs?.getString(_key) ?? '{}';
    final map = json.decode(jsonString);
    _barcode = Map<String, int>.from(map);
  }

  Future<void> _saveData(Map<String, int> map) async {
    prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(map);
    prefs?.setString(_key, jsonString);
  }
}
