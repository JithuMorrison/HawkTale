import 'package:flutter/material.dart';

import 'addhabit.dart';
import 'dbhelper.dart';
import 'habit.dart';
import 'habitdetails.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HabitTracker(),
    );
  }
}

// habit_tracker.dart
class HabitTracker extends StatefulWidget {
  @override
  _HabitTrackerState createState() => _HabitTrackerState();
}

class _HabitTrackerState extends State<HabitTracker> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Habit> _habits = [];
  String _timeRange = 'Today';

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await _dbHelper.getAllHabits();
    setState(() {
      _habits = habits;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HawkTale'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _timeRange = value;
              });
            },
            itemBuilder: (context) => [
              'Today', 'Weekly', 'Monthly', 'Overall'
            ].map((range) {
              return PopupMenuItem(
                value: range,
                child: Text(range),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Organize Your Life Easily',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: _timeRange == 'Overall' ? 2 : 4.4,
              ),
              itemCount: _habits.length,
              itemBuilder: (context, index) {
                return _HabitCard(
                  habit: _habits[index],
                  timeRange: _timeRange,
                  onTap: () => _showHabitDetails(_habits[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddHabitDialog(),
      ),
    );
  }

  Future<void> _showAddHabitDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddHabitPage()),
    );
    if (result == true) {
      _loadHabits();
    }
  }

  Future<void> _showHabitDetails(Habit habit) async {
    final result = await showModalBottomSheet(
      context: context,
      builder: (context) => HabitDetailsBottomSheet(habit: habit),
    );
    if (result == true) {
      _loadHabits();
    }
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final String timeRange;
  final VoidCallback onTap;

  const _HabitCard({
    required this.habit,
    required this.timeRange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseHelper.instance.getHabitStats(habit.id!),
      builder: (context, snapshot) {
        final daysCompleted = snapshot.data?['completed'] ?? 0;
        final totalDays = snapshot.data?['total_days'] ?? 0;
        final progress = (totalDays > 0) ? daysCompleted / totalDays : 0.0;

        return GestureDetector(
          onTap: onTap,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  timeRange == 'Overall'
                      ? _buildGitHubStyleGrid(context)
                      : Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGitHubStyleGrid(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getAllHabitCompletionHistory(habit.id!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final completionHistory = snapshot.data!;
        final Set<String> completedDates = completionHistory
            .where((record) => record['completed'] == 1)
            .map<String>((record) => record['date'] as String)
            .toSet();

        const int numRows = 7; // Sunday to Saturday
        const int numColumns = 6; // last 6 weeks

        final DateTime today = DateTime.now();
        // Find most recent Sunday
        final int weekdayOffset = today.weekday % 7; // Sunday = 0
        final DateTime lastSunday = today.subtract(Duration(days: weekdayOffset));

        // Generate dates: left to right columns, top to bottom rows (Sunday to Saturday)
        final List<DateTime> allDates = List.generate(
          numColumns * numRows,
              (index) {
            final column = index ~/ numRows;
            final row = index % numRows;
            return lastSunday.subtract(Duration(days: (numColumns - 1 - column) * 7 - row));
          },
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(numColumns, (colIndex) {
            return Column(
              children: List.generate(numRows, (rowIndex) {
                final index = colIndex * numRows + rowIndex;
                if (index >= allDates.length) return SizedBox(height: 14);
                final date = allDates[index];
                final isCompleted = completedDates.contains(date.toIso8601String().split('T')[0]);

                return Container(
                  width: 12,
                  height: 12,
                  margin: EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            );
          }),
        );
      },
    );
  }
}