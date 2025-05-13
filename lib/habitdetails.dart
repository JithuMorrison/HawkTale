import 'package:flutter/material.dart';
import 'addhabit.dart';
import 'dbhelper.dart';
import 'habit.dart';

class HabitDetailsBottomSheet extends StatefulWidget {
  final Habit habit;

  const HabitDetailsBottomSheet({required this.habit});

  @override
  _HabitDetailsBottomSheetState createState() => _HabitDetailsBottomSheetState();
}

class _HabitDetailsBottomSheetState extends State<HabitDetailsBottomSheet> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.habit.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          if (widget.habit.description.isNotEmpty)
            Text(widget.habit.description),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  _dbHelper.recordHabitCompletion(widget.habit.id!, true);
                  Navigator.pop(context, true);
                },
                child: Text('Completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _dbHelper.recordHabitCompletion(widget.habit.id!, false);
                  Navigator.pop(context, true);
                },
                child: Text('Missed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _showEditHabitDialog(widget.habit); // ✅ Pass the habit here
            },
            child: Text('Edit Habit'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditHabitDialog(Habit habit) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Habit'),
        content: Text('Would you like to edit or delete this habit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'edit'),
            child: Text('Edit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    if (result == 'edit') {
      final updated = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddHabitPage(habit: habit)),
      );
      if (updated == true) {
        Navigator.pop(context, true); // ✅ Notify parent to reload
      }
    } else if (result == 'delete') {
      await _dbHelper.deleteHabit(habit.id!);
      Navigator.pop(context, true); // ✅ Notify parent to reload
    }
  }
}
