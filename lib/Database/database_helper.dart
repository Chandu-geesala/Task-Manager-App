
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'package:altstack/Database/profile.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'profiles_database.db');
    return await openDatabase(path, version: 1, onCreate: _createDb);
  }


  Future<Profile> getProfile(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Profile(
        id: maps[0]['id'],
        name: maps[0]['name'],
        imagePath: maps[0]['imagePath'],
      );
    }
    throw Exception('Profile not found');
  }


  void _createDb(Database db, int newVersion) async {
    await db.execute('''
      CREATE TABLE profiles(
        id INTEGER PRIMARY KEY,
        name TEXT,
        imagePath TEXT,
        imageData BLOB
      )
    ''');
  }

  Future<int> insertProfile(Profile profile) async {
    Database db = await database;
    return await db.insert('profiles', profile.toMap());
  }

  Future<List<Profile>> profiles() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('profiles');
    return List.generate(maps.length, (i) {
      return Profile(
        id: maps[i]['id'],
        name: maps[i]['name'],
        imagePath: maps[i]['imagePath'],
      );
    });
  }


  Future<int> updateProfile(Profile profile) async {
    Database db = await database;
    return await db.update(
      'profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }




}

