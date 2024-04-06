import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:altstack/Tasks/Tasks.dart';

class ClassEventDatabaseHelper {
  static final ClassEventDatabaseHelper _instance = ClassEventDatabaseHelper._internal();
  factory ClassEventDatabaseHelper() => _instance;

  static Database? _database;

  ClassEventDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> updateCompletionStatus(int eventId, String isCompleted) async {
    final db = await database;
    await db.update(
      'task_events',
      {'is_completed': isCompleted},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'task_events_database.db');
    return openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<List<TaskEvent>> getAllClassEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('task_events');
    return List.generate(maps.length, (i) {
      return TaskEvent.fromMap(maps[i]);
    });
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE task_events(
        id INTEGER PRIMARY KEY,
        task_name TEXT,
        description TEXT,
        is_completed TEXT DEFAULT 'NO'
      )
    ''');
  }

  Future<void> insertClassEvent(TaskEvent classEvent) async {
    final db = await database;
    await db.insert('task_events', classEvent.toMap());
  }

  Future<void> updateClassEvent(TaskEvent classEvent) async {
    final db = await database;
    await db.update(
      'task_events',
      classEvent.toMap(),
      where: 'id = ?',
      whereArgs: [classEvent.id],
    );
  }

  Future<void> deleteClassEvent(int id) async {
    final db = await database;
    await db.delete(
      'task_events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
