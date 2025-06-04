import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_cupertino_date_picker_fork/flutter_cupertino_date_picker_fork.dart';


import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeSelectionWizard extends StatefulWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final Function(DateTime?) onDateSelected;
  final Function(TimeOfDay?) onTimeSelected;
  final Function onNextStep;

  const DateTimeSelectionWizard({
    Key? key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateSelected,
    required this.onTimeSelected,
    required this.onNextStep,
  }) : super(key: key);

  @override
  _DateTimeSelectionWizardState createState() => _DateTimeSelectionWizardState();
}

class _DateTimeSelectionWizardState extends State<DateTimeSelectionWizard> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    // Normalize incoming DateTime to local date only
    _selectedDate = widget.selectedDate != null
        ? DateTime(widget.selectedDate!.year, widget.selectedDate!.month, widget.selectedDate!.day)
        : null;
    _selectedTime = widget.selectedTime;
  }

  void _pickDate() {
    DatePicker.showDatePicker(
      context,
      pickerTheme: DateTimePickerTheme(
        showTitle: true,
        confirm: Text('Confirmar', style: TextStyle(color: const Color(0xFF1A819A))),
        cancel: Text('Cancelar', style: TextStyle(color: Colors.red)),
      ),
      minDateTime: DateTime.now().subtract(const Duration(days: 365)),
      maxDateTime: DateTime.now().add(const Duration(days: 365)),
      initialDateTime: _selectedDate ?? DateTime.now(),
      dateFormat: 'yyyy-MM-dd',
      onConfirm: (date, _) {
        // Drop any timezone offset by reconstructing date-only
        final pureDate = DateTime(date.year, date.month, date.day);
        setState(() {
          _selectedDate = pureDate;
          widget.onDateSelected(pureDate);
        });
      },
    );
  }

  void _pickTime() {
    showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    ).then((time) {
      if (time != null) {
        setState(() {
          _selectedTime = time;
          widget.onTimeSelected(time);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat.Hm();

    String dateLabel = _selectedDate != null
        ? dateFormat.format(_selectedDate!)
        : 'Seleccione fecha';

    String timeLabel;
    if (_selectedTime != null) {
      // Construct a dummy DateTime with only hour/minute to format
      final dt = DateTime(0, 1, 1, _selectedTime!.hour, _selectedTime!.minute);
      timeLabel = timeFormat.format(dt);
    } else {
      timeLabel = 'Seleccione hora';
    }

    return Column(
        children: [
    Row(
    children: [
    Expanded(
    child: ListTile(
        title: Text(dateLabel, style: TextStyle(fontSize: 16.0)),
    trailing: Icon(Icons.calendar_today),
    onTap: _pickDate,
    ),

    ),
      SizedBox(width: 12),
      Expanded(
        child: ListTile(
        title: Text(timeLabel, style: TextStyle(fontSize: 16.0)),
      trailing: Icon(Icons.access_time),
      onTap: _pickTime,
                ),

              ),
              ],
            ),
          ],
        );
       }
}