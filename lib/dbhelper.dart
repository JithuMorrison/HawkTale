import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'habit.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habits.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''  
      CREATE TABLE stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER,
        date TEXT,
        correct INTEGER,
        wrong INTEGER,
        days TEXT,
        FOREIGN KEY (habit_id) REFERENCES habits (id)
      )
    ''');

    await db.execute('''  
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        type TEXT,
        target_value INTEGER,
        unit TEXT,
        frequency TEXT,
        days TEXT,
        reminder_time TEXT,
        created_at TEXT
      )
    ''');
  }

  Future<Map<String, dynamic>> getCategoryStats(int habitId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(correct) as total_correct,
        SUM(wrong) as total_wrong
      FROM stats
      WHERE habit_id = ?
    ''', [habitId]);

    return {
      'total_correct': result.first['total_correct'] ?? 0,
      'total_wrong': result.first['total_wrong'] ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getAllHabitCompletionHistory(int habitId) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT date, correct, wrong
    FROM stats
    WHERE habit_id = ?
    ORDER BY date ASC
  ''', [habitId]);
  }

  // Habit operations
  Future<int> createHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getAllHabits() async {
    final db = await database;
    final result = await db.query('habits');
    return result.map((json) => Habit.fromMap(json)).toList();
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> recordHabitCompletion(int habitId, bool completed) async {
    final db = await database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Check if a record exists for today
    final existing = await db.query(
      'stats',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, today],
    );

    if (existing.isNotEmpty) {
      // Update existing record
      return await db.update(
        'stats',
        {
          'correct': completed ? 1 : 0,
          'wrong': completed ? 0 : 1,
          'days': today,
        },
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, today],
      );
    } else {
      // Insert new record
      return await db.insert('stats', {
        'habit_id': habitId,
        'date': today,
        'correct': completed ? 1 : 0,
        'wrong': completed ? 0 : 1,
        'days': today,
      });
    }
  }

  Future<Map<String, dynamic>> getHabitStats(int habitId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(correct) as completed,
        SUM(wrong) as missed,
        COUNT(*) as total_days
      FROM stats
      WHERE habit_id = ?
    ''', [habitId]);

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getHabitCompletionHistory(int habitId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT date, correct, wrong
      FROM stats
      WHERE habit_id = ?
      ORDER BY date DESC
    ''', [habitId]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
