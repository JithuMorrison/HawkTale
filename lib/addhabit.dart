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
        title: Text('Customize Your Habit'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Habit Details'),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Habit Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a habit name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              _buildSectionTitle('Track Type'),
              _buildTrackOptions(),
              if (_trackType == 'amount' || _trackType == 'time') _buildTargetInput(),

              Divider(height: 32),
              _buildSectionTitle('Repeat Frequency'),
              _buildFrequencyOptions(),
              if (_frequency == 'weekly') _buildWeeklyDays(),

              Divider(height: 32),
              _buildSectionTitle('Reminder'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.alarm),
                title: Text(_reminderTime != null
                    ? 'Reminder set at ${_reminderTime!.format(context)}'
                    : 'No reminder set'),
                trailing: Icon(Icons.keyboard_arrow_right),
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

              SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _saveHabit,
                  icon: Icon(Icons.save),
                  label: Text('Save Habit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal[700]),
      ),
    );
  }

  Widget _buildTrackOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTrackOption('task', 'Task'),
        _buildTrackOption('amount', 'Amount'),
        _buildTrackOption('time', 'Time'),
      ],
    );
  }

  Widget _buildTargetInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              keyboardType: TextInputType.number,
              initialValue: _targetValue.toString(),
              onChanged: (value) {
                _targetValue = int.tryParse(value) ?? 1;
              },
              decoration: InputDecoration(
                labelText: 'Target',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(width: 12),
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
    );
  }

  Widget _buildFrequencyOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFrequencyOption('daily', 'Daily'),
        _buildFrequencyOption('weekly', 'Weekly'),
        _buildFrequencyOption('monthly', 'Monthly'),
      ],
    );
  }

  Widget _buildWeeklyDays() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8,
        children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
            .map((day) => _buildDayOption(day))
            .toList(),
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