// add_habit_page.dart
import 'package:flutter/material.dart';

import 'dbhelper.dart';
import 'habit.dart';

class AddHabitPage extends StatefulWidget {
  final Habit? habit;

  AddHabitPage({this.habit});

  @override
  _AddHabitPageState createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _trackType = 'task';
  int _targetValue = 1;
  String _unit = 'times';
  String _frequency = 'daily';
  final List<String> _selectedDays = [];
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      final habit = widget.habit!;
      _nameController.text = habit.name;
      _descController.text = habit.description ?? '';
      _trackType = habit.type;
      _targetValue = habit.targetValue;
      _unit = habit.unit;
      _frequency = habit.frequency;
      _selectedDays.addAll(habit.days);
      _reminderTime = habit.reminderTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customize Your Habits'),
        actions: [
          IconButton(
            icon: Text('Save'),
            onPressed: _saveHabit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Habit Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Add description',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 24),
              Text('Track', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _buildTrackOption('task', 'Task'),
                  _buildTrackOption('amount', 'Amount'),
                  _buildTrackOption('time', 'Time'),
                ],
              ),
              if (_trackType == 'amount' || _trackType == 'time') ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        initialValue: _targetValue.toString(),
                        onChanged: (value) {
                          _targetValue = int.tryParse(value) ?? 1;
                        },
                        decoration: InputDecoration(
                          labelText: 'Target value',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _unit,
                        items: _getUnitOptions(),
                        onChanged: (value) {
                          setState(() {
                            _unit = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 24),
              Text('Repeat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _buildFrequencyOption('daily', 'Daily'),
                  _buildFrequencyOption('weekly', 'Weekly'),
                  _buildFrequencyOption('monthly', 'Monthly'),
                ],
              ),
              if (_frequency == 'weekly') ...[
                SizedBox(height: 16),
                Text('On these days', style: TextStyle(fontSize: 16)),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildDayOption('Sun'),
                    _buildDayOption('Mon'),
                    _buildDayOption('Tue'),
                    _buildDayOption('Wed'),
                    _buildDayOption('Thu'),
                    _buildDayOption('Fri'),
                    _buildDayOption('Sat'),
                  ],
                ),
              ],
              SizedBox(height: 24),
              ListTile(
                title: Text('Reminder'),
                trailing: _reminderTime != null
                    ? Text(_reminderTime!.format(context))
                    : Text('None'),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _reminderTime = time;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackOption(String value, String label) {
    return Expanded(
      child: RadioListTile<String>(
        title: Text(label),
        value: value,
        groupValue: _trackType,
        onChanged: (value) {
          setState(() {
            _trackType = value!;
          });
        },
      ),
    );
  }

  Widget _buildFrequencyOption(String value, String label) {
    return Expanded(
      child: RadioListTile<String>(
        title: Text(label),
        value: value,
        groupValue: _frequency,
        onChanged: (value) {
          setState(() {
            _frequency = value!;
            if (value != 'weekly') {
              _selectedDays.clear();
            }
          });
        },
      ),
    );
  }

  Widget _buildDayOption(String day) {
    final isSelected = _selectedDays.contains(day);
    return ChoiceChip(
      label: Text(day),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedDays.add(day);
          } else {
            _selectedDays.remove(day);
          }
        });
      },
    );
  }

  List<DropdownMenuItem<String>> _getUnitOptions() {
    if (_trackType == 'time') {
      return ['minutes', 'hours'].map((unit) {
        return DropdownMenuItem(
          value: unit,
          child: Text(unit),
        );
      }).toList();
    } else {
      return ['times', 'items', 'pages', 'glasses'].map((unit) {
        return DropdownMenuItem(
          value: unit,
          child: Text(unit),
        );
      }).toList();
    }
  }

  Future<void> _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      final updatedHabit = Habit(
        id: widget.habit?.id, // Important for updates
        name: _nameController.text,
        description: _descController.text,
        type: _trackType,
        targetValue: _targetValue,
        unit: _unit,
        frequency: _frequency,
        days: _selectedDays,
        reminderTime: _reminderTime,
      );

      if (widget.habit != null) {
        await DatabaseHelper.instance.updateHabit(updatedHabit);
      } else {
        await DatabaseHelper.instance.createHabit(updatedHabit);
      }

      Navigator.pop(context, true);
    }
  }
}