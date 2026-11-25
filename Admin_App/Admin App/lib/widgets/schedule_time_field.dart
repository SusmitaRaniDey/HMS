import 'package:flutter/material.dart';

String formatScheduleTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

String _format12HourTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String formatScheduleTimeForDisplay(BuildContext context, String value) {
  final parts = value.split(':');
  if (parts.length < 2) return value;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null || hour > 23 || minute > 59) return value;

  return _format12HourTime(TimeOfDay(hour: hour, minute: minute));
}

class ScheduleTimeField extends StatefulWidget {
  const ScheduleTimeField({
    super.key,
    required this.label,
    required this.initialTime,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<ScheduleTimeField> createState() => _ScheduleTimeFieldState();
}

class _ScheduleTimeFieldState extends State<ScheduleTimeField> {
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime;
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected == null || !mounted) return;

    setState(() => _time = selected);
    widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _selectTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(_format12HourTime(_time)),
      ),
    );
  }
}
