import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class PersistenceService {
  static const String _dbName = 'signoi.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'app_data';

  static const String _noiseItemsKey = 'noise_items';
  static const String _shortTermItemsKey = 'short_term_items';
  static const String _sharedItemsKey = 'shared_items';
  static const String _homePageItemsKey = 'home_page_items';
  static const String _levelKey = 'level';
  static const String _experienceKey = 'experience';

  late Database _database;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<String?> _getValue(String key) async {
    final rows = await _database.query(
      _tableName,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _setValue(String key, String value) async {
    await _database.insert(
      _tableName,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getNoiseItems() async {
    final data = await _getValue(_noiseItemsKey);
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNoiseItems(List<String> items) async {
    await _setValue(_noiseItemsKey, jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>> getShortTermItems() async {
    final data = await _getValue(_shortTermItemsKey);
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveShortTermItems(List<Map<String, dynamic>> items) async {
    await _setValue(_shortTermItemsKey, jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>> getSharedItems() async {
    final data = await _getValue(_sharedItemsKey);
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSharedItems(List<Map<String, dynamic>> items) async {
    await _setValue(_sharedItemsKey, jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>> getHomePageItems() async {
    final data = await _getValue(_homePageItemsKey);
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHomePageItems(List<Map<String, dynamic>> items) async {
    await _setValue(_homePageItemsKey, jsonEncode(items));
  }

  Future<int> getLevel() async {
    final data = await _getValue(_levelKey);
    if (data == null) return 1;
    try {
      final decoded = jsonDecode(data);
      return decoded is int ? decoded : (decoded as num).toInt();
    } catch (_) {
      return 1;
    }
  }

  Future<void> saveLevel(int level) async {
    await _setValue(_levelKey, jsonEncode(level));
  }

  Future<double> getExperience() async {
    final data = await _getValue(_experienceKey);
    if (data == null) return 0.0;
    try {
      final decoded = jsonDecode(data);
      return decoded is double ? decoded : (decoded as num).toDouble();
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> saveExperience(double experience) async {
    await _setValue(_experienceKey, jsonEncode(experience));
  }

  Future<void> clearAll() async {
    await _database.delete(_tableName);
  }
}
