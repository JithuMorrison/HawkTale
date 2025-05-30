import 'dart:math';

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
                childAspectRatio: _timeRange == 'Overall' ? 2 : (_timeRange == 'Monthly' ? 2.5 : 3),
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
      floatingActionButtonLocation: _timeRange == 'Overall'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.startFloat,
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
        final currentStreak = snapshot.data?['current_streak'] ?? 0;
        final progress = (daysCompleted > 0) ? currentStreak / daysCompleted : 0.0;
        final List<dynamic> historyList = snapshot.data?['history'] ?? [];
        final Set<String> completedDates = historyList
            .where((record) => record['completed'] == 1)
            .map<String>((record) => record['date'] as String)
            .toSet();

        final String todayStr = DateTime.now().toIso8601String().split('T')[0];
        final bool isTodayCompleted = completedDates.contains(todayStr);

        return GestureDetector(
          onTap: onTap,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (timeRange == 'Overall')
                    _buildGitHubStyleGrid(context)
                  else if (timeRange == 'Weekly')
                    _buildWeeklyCircles(completedDates)
                  else if (timeRange == 'Monthly')
                      _buildMonthlyGrid(completedDates),
                  if (timeRange == 'Today') ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        SizedBox(width: 5),
                        IconButton(
                          icon: Icon(
                            currentStreak > 0
                                ? Icons.local_fire_department
                                : Icons.check_circle_outline,
                            color: currentStreak > 0
                                ? (isTodayCompleted ? Colors.orange : Colors.green)
                                : Colors.red,
                            size: 28,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  currentStreak > 0
                                      ? '🔥 Current Streak: $currentStreak days'
                                      : '✔️ No current streak',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          tooltip: currentStreak > 0 ? 'Current Streak' : 'No Streak',
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
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
        final int numCompleted = completedDates.length;
        final int weeksNeeded = (numCompleted / 7).ceil() + 1;
        const int minColumns = 20;
        final int numColumns = max(minColumns, weeksNeeded);

        final DateTime today = DateTime.now();
        final int weekdayOffset = today.weekday % 7;
        final DateTime lastSunday = today.subtract(Duration(days: weekdayOffset));

        final List<DateTime> allDates = List.generate(
          numColumns * numRows,
              (index) {
            final column = index ~/ numRows;
            final row = index % numRows;
            return lastSunday.subtract(Duration(days: (numColumns - 1 - column) * 7 - row));
          },
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
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
                      border: date.year == today.year &&
                          date.month == today.month &&
                          date.day == today.day
                          ? Border.all(
                        color: isCompleted ? Colors.blue : Colors.red,
                        width: 2,
                      ) : null,
                    ),
                  );
                }),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyCircles(Set<String> completedDates) {
    final today = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: last7Days.map((date) {
        final dateStr = date.toIso8601String().split('T')[0];
        final isCompleted = completedDates.contains(dateStr);
        return Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green : Colors.grey[300],
              ),
              child: Center(
                child: Icon(
                  isCompleted ? Icons.check : Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              ['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7],
              style: TextStyle(fontSize: 12),
            )
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyGrid(Set<String> completedDates) {
    final today = DateTime.now();
    final DateTime firstDayOfMonth = DateTime(today.year, today.month, 1);
    final int daysInMonth = DateTime(today.year, today.month + 1, 0).day;

    final List<DateTime> monthDates = List.generate(
      daysInMonth,
          (i) => DateTime(firstDayOfMonth.year, firstDayOfMonth.month, i + 1),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: monthDates.map((date) {
          final isCompleted = completedDates.contains(date.toIso8601String().split('T')[0]);
          return Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }).toList(),
      ),
    );
  }
}