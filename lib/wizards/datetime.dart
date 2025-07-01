import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _DateTimeSelectionWizardState extends State<DateTimeSelectionWizard>
    with TickerProviderStateMixin {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Normalize incoming DateTime to local date only
    _selectedDate = widget.selectedDate != null
        ? DateTime(widget.selectedDate!.year, widget.selectedDate!.month, widget.selectedDate!.day)
        : null;
    _selectedTime = widget.selectedTime;
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _pickDate() {
    DatePicker.showDatePicker(
      context,
      pickerTheme: DateTimePickerTheme(
        showTitle: true,
        confirm: Text(
          'Confirmar',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1A819A),
            fontWeight: FontWeight.w600,
          ),
        ),
        cancel: Text(
          'Cancelar',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF44336),
            fontWeight: FontWeight.w600,
          ),
        ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: const Color(0xFF1A819A),
              hourMinuteColor: const Color(0xFF1A819A).withOpacity(0.1),
              dialHandColor: const Color(0xFF1A819A),
              dialBackgroundColor: const Color(0xFF1A819A).withOpacity(0.1),
              dialTextColor: const Color(0xFF1A819A),
              entryModeIconColor: const Color(0xFF1A819A),
            ),
          ),
          child: child!,
        );
      },
    ).then((time) {
      if (time != null) {
        setState(() {
          _selectedTime = time;
          widget.onTimeSelected(time);
        });
      }
    });
  }

  Widget _buildDateTimeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF1A819A), Color(0xFF0D4A5A)],
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF1A819A).withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: isSelected
                ? null
                : Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFF1A819A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFF1A819A),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1A819A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'es_ES');
    final timeFormat = DateFormat.Hm();

    String dateLabel = _selectedDate != null
        ? dateFormat.format(_selectedDate!)
        : 'Selecciona fecha';

    String timeLabel;
    if (_selectedTime != null) {
      // Construct a dummy DateTime with only hour/minute to format
      final dt = DateTime(0, 1, 1, _selectedTime!.hour, _selectedTime!.minute);
      timeLabel = timeFormat.format(dt);
    } else {
      timeLabel = 'Selecciona hora';
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A819A), Color(0xFF0D4A5A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A819A).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Programa tu servicio',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona la fecha y hora que mejor te convenga',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Selectores de fecha y hora
              Row(
                children: [
                  _buildDateTimeCard(
                    title: 'Fecha',
                    subtitle: dateLabel,
                    icon: Icons.calendar_today,
                    onTap: _pickDate,
                    isSelected: _selectedDate != null,
                  ),
                  _buildDateTimeCard(
                    title: 'Hora',
                    subtitle: timeLabel,
                    icon: Icons.access_time,
                    onTap: _pickTime,
                    isSelected: _selectedTime != null,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A819A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1A819A).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF1A819A),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Horarios disponibles',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A819A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Los profesionales están disponibles de lunes a domingo, de 8:00 AM a 8:00 PM.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF1A819A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Resumen de selección
              if (_selectedDate != null || _selectedTime != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Servicio programado',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                            if (_selectedDate != null && _selectedTime != null)
                              Text(
                                '${dateFormat.format(_selectedDate!)} a las ${timeFormat.format(DateTime(0, 1, 1, _selectedTime!.hour, _selectedTime!.minute))}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.green[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}