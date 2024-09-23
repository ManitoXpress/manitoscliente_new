import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_cupertino_date_picker_fork/flutter_cupertino_date_picker_fork.dart';

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

  void _pickDate() {
    DatePicker.showDatePicker(
      context,
      pickerTheme: DateTimePickerTheme(
        showTitle: true,
        confirm: Text('Confirmar', style: TextStyle(color: Colors.blue)),
        cancel: Text('Cancelar', style: TextStyle(color: Colors.red)),
      ),
      minDateTime: DateTime.now().subtract(const Duration(days: 365)),
      maxDateTime: DateTime.now().add(const Duration(days: 365)),
      initialDateTime: _selectedDate ?? DateTime.now(),
      dateFormat: 'yyyy-MM-dd',
      onConfirm: (date, _) {
        setState(() {
          _selectedDate = date;
          widget.onDateSelected(_selectedDate);
        });
      },
    );
  }

  void _pickTime() {
    DatePicker.showDatePicker(
      context,
      pickerMode: DateTimePickerMode.time, // Cambiamos el modo para el selector de tiempo
      pickerTheme: DateTimePickerTheme(
        showTitle: true,
        confirm: Text('Confirmar', style: TextStyle(color: Colors.blue)),
        cancel: Text('Cancelar', style: TextStyle(color: Colors.red)),
      ),
      initialDateTime: DateTime(
        1,
        1,
        1,
        _selectedTime?.hour ?? TimeOfDay.now().hour,
        _selectedTime?.minute ?? TimeOfDay.now().minute,
      ),
      dateFormat: 'HH:mm',
      onConfirm: (time, _) {
        setState(() {
          _selectedTime = TimeOfDay(hour: time.hour, minute: time.minute);
          widget.onTimeSelected(_selectedTime);
        });
      },
    );
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
