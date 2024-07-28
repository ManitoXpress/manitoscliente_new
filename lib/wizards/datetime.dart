import 'package:flutter/material.dart';
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
    _selectedDate = widget.selectedDate;
    _selectedTime = widget.selectedTime;
  }

  Future<void> _pickDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        widget.onDateSelected(_selectedDate);
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
        widget.onTimeSelected(_selectedTime);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat.Hm();

    return Column(
      children: [
        ListTile(
          title: Text(
            _selectedDate != null
                ? dateFormat.format(_selectedDate!)
                : 'Seleccione una fecha',
            style: TextStyle(fontSize: 16.0),
          ),
          trailing: Icon(Icons.calendar_today),
          onTap: _pickDate,
        ),
        ListTile(
          title: Text(
            _selectedTime != null
                ? timeFormat.format(DateTime(1, 1, 1, _selectedTime!.hour, _selectedTime!.minute))
                : 'Seleccione una hora',
            style: TextStyle(fontSize: 16.0),
          ),
          trailing: Icon(Icons.access_time),
          onTap: _pickTime,
        ),
      ],
    );
  }
}
