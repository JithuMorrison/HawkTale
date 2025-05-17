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

    //await deleteDatabase(path);

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
        completed INTEGER,
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

  Future<List<Map<String, dynamic>>> getAllHabitCompletionHistory(int habitId) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT date, completed
    FROM stats
    WHERE habit_id = ?
    ORDER BY date ASC
    ''', [habitId]);
  }

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
          'completed': completed ? 1 : 0,
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
        'completed': completed ? 1 : 0,
        'days': today,
      });
    }
  }

  Future<Map<String, dynamic>> getHabitStats(int habitId) async {
    final db = await database;

    // Get completed and total days from DB
    final result = await db.rawQuery('''
    SELECT 
      SUM(completed) as completed,
      COUNT(*) as total_days
    FROM stats
    WHERE habit_id = ?
  ''', [habitId]);

    // Get all records ordered by date
    final streakResult = await db.rawQuery('''
    SELECT date, completed
    FROM stats
    WHERE habit_id = ?
    ORDER BY date ASC
  ''', [habitId]);

    int maxStreak = 0;
    int currentStreak = 0;
    int tempStreak = 0;

    DateTime? previousDate;

    for (var row in streakResult) {
      final completed = row['completed'] == 1;
      final date = DateTime.parse(row['date'] as String);

      if (completed) {
        if (previousDate == null ||
            date.difference(previousDate).inDays == 1) {
          // continue streak
          tempStreak++;
        } else {
          // reset streak
          tempStreak = 1;
        }

        maxStreak = tempStreak > maxStreak ? tempStreak : maxStreak;
      } else {
        tempStreak = 0;
      }

      previousDate = date;
    }

    // Now calculate current streak (starting from most recent date backward)
    currentStreak = 0;
    for (int i = streakResult.length - 1; i >= 0; i--) {
      final row = streakResult[i];
      final completed = row['completed'] == 1;
      if (completed) {
        currentStreak++;
      } else {
        break;
      }
    }

    final data = result.first;
    return {
      'completed': data['completed'] ?? 0,
      'total_days': data['total_days'] ?? 0,
      'max_streak': maxStreak,
      'current_streak': currentStreak,
      'history': streakResult,
    };
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
