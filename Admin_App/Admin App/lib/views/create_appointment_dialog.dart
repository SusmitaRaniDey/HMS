import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../config/api_endpoints.dart';
import '../services/api_services.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';

class CreateAppointmentDialog extends StatefulWidget {
  const CreateAppointmentDialog({super.key});

  @override
  State<CreateAppointmentDialog> createState() =>
      _CreateAppointmentDialogState();
}

class _CreateAppointmentDialogState extends State<CreateAppointmentDialog> {
  final ApiService _api = Get.find<ApiService>();
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  final _patientField = TextEditingController();
  final _providerField = TextEditingController();
  final _newPatientName = TextEditingController();
  final _newPatientAge = TextEditingController();
  final _newPatientContact = TextEditingController();
  List<Map<String, dynamic>> patients = [],
      doctors = [],
      diagnostics = [],
      slots = [];
  int? patientId, doctorId, diagnosticId;
  Map<String, dynamic>? selectedProvider;
  String mode = 'doctor', type = 'offline';
  String patientType = 'registered';
  String? timeSlot;
  DateTime? date;
  bool loading = true, submitting = false, loadingSlots = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _notes.dispose();
    _patientField.dispose();
    _providerField.dispose();
    _newPatientName.dispose();
    _newPatientAge.dispose();
    _newPatientContact.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _items(dynamic value) {
    final raw = value is Map ? (value['data'] ?? value['items'] ?? []) : value;
    return (raw as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _loadOptions() async {
    try {
      final responses = await Future.wait([
        _api.get(ApiEndpoints.USERS, queryParameters: {'limit': 1000}),
        _api.get(ApiEndpoints.DOCTORS, queryParameters: {'limit': 1000}),
        _api.get(ApiEndpoints.DIAGNOSTICS, queryParameters: {'limit': 1000}),
      ]);
      if (!mounted) return;
      setState(() {
        patients = _items(responses[0].data);
        doctors = _items(responses[1].data);
        diagnostics = _items(responses[2].data);
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
      Helpers.showErrorSnackbar('Error', 'Could not load booking options');
    }
  }

  Future<void> _loadSlots() async {
    if (doctorId == null || date == null) return;
    setState(() {
      loadingSlots = true;
      timeSlot = null;
      slots = [];
    });
    try {
      final response = await _api.get(
        ApiEndpoints.doctorTimeSlots(doctorId!),
        queryParameters: {
          'date': DateFormat('yyyy-MM-dd').format(date!),
          'type': type,
        },
      );
      final data = response.data;
      final raw = data is Map ? (data['slots'] ?? []) : data;
      if (mounted) {
        setState(
          () => slots = (raw as List? ?? [])
              .map(
                (e) => e is Map
                    ? Map<String, dynamic>.from(e)
                    : {'timeSlot': e.toString()},
              )
              .toList(),
        );
      }
    } catch (_) {
      Helpers.showErrorSnackbar(
        'Unavailable',
        'Could not load available time slots',
      );
    } finally {
      if (mounted) setState(() => loadingSlots = false);
    }
  }

  String _slotLabel(Map<String, dynamic> slot) =>
      (slot['timeSlot'] ??
              slot['label'] ??
              slot['time'] ??
              slot['startTime'] ??
              '')
          .toString();

  Set<String> get _doctorWorkingDays {
    final provider = selectedProvider;
    if (provider == null) return const {};

    final rawSchedule = type == 'online'
        ? (provider['onlineSchedule'] ?? provider['online_schedule'])
        : (provider['workingDays'] ?? provider['working_days']);

    return (rawSchedule as List? ?? const [])
        .whereType<Map>()
        .map((schedule) => schedule['day']?.toString().trim().toLowerCase())
        .whereType<String>()
        .where((day) => day.isNotEmpty)
        .toSet();
  }

  bool _isDoctorWorkingDay(DateTime candidate) => _doctorWorkingDays.contains(
    DateFormat('EEEE').format(candidate).toLowerCase(),
  );

  DateTime? _firstSelectableDate(DateTime firstDate, DateTime lastDate) {
    for (
      var candidate = firstDate;
      !candidate.isAfter(lastDate);
      candidate = candidate.add(const Duration(days: 1))
    ) {
      if (_isDoctorWorkingDay(candidate)) return candidate;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final firstDate = DateUtils.dateOnly(DateTime.now());
    final lastDate = firstDate.add(const Duration(days: 365));
    DateTime initialDate = date ?? firstDate;
    bool Function(DateTime)? selectableDayPredicate;

    if (mode == 'doctor') {
      if (selectedProvider == null) {
        Helpers.showErrorSnackbar('Required', 'Please select a doctor first');
        return;
      }

      final firstWorkingDate = _firstSelectableDate(firstDate, lastDate);
      if (firstWorkingDate == null) {
        Helpers.showErrorSnackbar(
          'Unavailable',
          'This doctor has no configured $type working days',
        );
        return;
      }

      selectableDayPredicate = _isDoctorWorkingDay;
      if (!_isDoctorWorkingDay(initialDate)) initialDate = firstWorkingDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: selectableDayPredicate,
    );
    if (picked != null) {
      setState(() => date = picked);
      if (mode == 'doctor') await _loadSlots();
    }
  }

  Future<void> _submit() async {
    if (patientType == 'registered' && patientId == null) {
      Helpers.showErrorSnackbar('Required', 'Please select a patient');
      return;
    }
    if (mode == 'doctor' && doctorId == null) {
      Helpers.showErrorSnackbar('Required', 'Please select a doctor');
      return;
    }
    if (mode == 'diagnostic' && diagnosticId == null) {
      Helpers.showErrorSnackbar('Required', 'Please select a diagnostic test');
      return;
    }
    if (!_formKey.currentState!.validate() || date == null) {
      if (date == null) {
        Helpers.showErrorSnackbar('Required', 'Please select a date');
      }
      return;
    }
    final amount = _amount;
    if (amount <= 0) {
      Helpers.showErrorSnackbar(
        'Invalid fee',
        'The selected service has no valid price',
      );
      return;
    }
    setState(() => submitting = true);
    try {
      // Admin collects every booking fee at the hospital counter. No gateway
      // or pending payment state is used in this flow.
      const paymentStatus = 'completed';
      const isPaid = 'paid';
      if (mode == 'doctor') {
        await _api.post(
          ApiEndpoints.APPOINTMENTS,
          data: {
            if (patientType == 'registered') 'patientId': patientId,
            if (patientType == 'new') 'newPatient': _newPatientPayload(),
            'doctorId': doctorId,
            'date': DateFormat('yyyy-MM-dd').format(date!),
            'type': type,
            if (timeSlot != null) 'timeSlot': timeSlot,
            if (timeSlot != null)
              'startTime': DateTime(
                date!.year,
                date!.month,
                date!.day,
                int.parse(timeSlot!.split(':')[0]),
                int.parse(timeSlot!.split(':')[1]),
              ).toUtc().toIso8601String(),
            'appointmentFor': 'self',
            'isPaid': isPaid,
            'paymentMethod': 'pay_in_hospital',
            'paymentStatus': paymentStatus,
            'paidAmount': amount,
          },
        );
      } else {
        await _api.post(
          ApiEndpoints.DIAGNOSTIC_BOOKINGS,
          data: {
            if (patientType == 'registered') 'patientId': patientId,
            if (patientType == 'new') 'newPatient': _newPatientPayload(),
            'diagnosticId': diagnosticId,
            'scheduleDate': DateFormat('yyyy-MM-dd').format(date!),
            'status': 'confirmed',
            'notes': _notes.text.trim(),
            'isPaid': isPaid,
            'paymentMethod': 'pay_in_hospital',
            'paymentStatus': paymentStatus,
            'paidAmount': amount,
          },
        );
      }
      Helpers.showSuccessSnackbar(
        'Success',
        mode == 'doctor' ? 'Appointment created' : 'Diagnostic booking created',
      );
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final data = e.response?.data;
      Helpers.showErrorSnackbar(
        'Could not create',
        data is Map
            ? (data['message']?.toString() ?? 'Booking failed')
            : 'Booking failed',
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  int _id(Map<String, dynamic> item) => int.parse(item['id'].toString());

  double get _amount {
    final provider = selectedProvider;
    if (provider == null) return 0;
    final value = mode == 'doctor'
        ? (type == 'online'
              ? provider['onlineFee'] ?? provider['fee']
              : provider['offlineFee'] ?? provider['fee'])
        : provider['price'];
    return value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  }

  Map<String, dynamic> _newPatientPayload() => {
    'name': _newPatientName.text.trim(),
    'age': int.parse(_newPatientAge.text.trim()),
    'contactNumber': _newPatientContact.text.trim(),
  };

  String _patientLabel(Map<String, dynamic> patient) {
    final contact =
        patient['phone'] ?? patient['contactNumber'] ?? patient['email'];
    return '${patient['name'] ?? 'Patient'}${contact == null ? '' : ' — $contact'}';
  }

  String _doctorLabel(Map<String, dynamic> doctor) {
    final phone = doctor['phone'] ?? doctor['contactNumber'];
    final specialty = doctor['specialty'];
    final details = [specialty, phone]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .join(' • ');
    return '${doctor['name'] ?? 'Doctor'}${details.isEmpty ? '' : ' — $details'}';
  }

  String _diagnosticLabel(Map<String, dynamic> diagnostic) {
    final name =
        diagnostic['test_name'] ?? diagnostic['testName'] ?? 'Diagnostic';
    final category = diagnostic['category'] ?? diagnostic['department'];
    return '$name${category == null ? '' : ' — $category'}';
  }

  Widget _searchableDropdown({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) itemLabel,
    required ValueChanged<Map<String, dynamic>?> onSelected,
    String hintText = 'Search by name or mobile number',
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => DropdownMenu<Map<String, dynamic>>(
        controller: controller,
        width: constraints.maxWidth,
        requestFocusOnTap: true,
        enableFilter: true,
        enableSearch: true,
        leadingIcon: Icon(icon),
        label: Text(label),
        hintText: hintText,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        dropdownMenuEntries: items
            .map(
              (item) => DropdownMenuEntry<Map<String, dynamic>>(
                value: item,
                label: itemLabel(item),
              ),
            )
            .toList(),
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create appointment'),
      content: SizedBox(
        width: 560,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'doctor',
                            label: Text('Doctor appointment'),
                            icon: Icon(Icons.medical_services_outlined),
                          ),
                          ButtonSegment(
                            value: 'diagnostic',
                            label: Text('Diagnostic booking'),
                            icon: Icon(Icons.science_outlined),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (v) => setState(() {
                          mode = v.first;
                          date = null;
                          timeSlot = null;
                          doctorId = null;
                          diagnosticId = null;
                          selectedProvider = null;
                          _providerField.clear();
                        }),
                      ),
                      const SizedBox(height: 20),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'registered',
                            label: Text('Registered patient'),
                            icon: Icon(Icons.person_search_outlined),
                          ),
                          ButtonSegment(
                            value: 'new',
                            label: Text('New patient'),
                            icon: Icon(Icons.person_add_alt_outlined),
                          ),
                        ],
                        selected: {patientType},
                        onSelectionChanged: (value) => setState(() {
                          patientType = value.first;
                          patientId = null;
                          _patientField.clear();
                        }),
                      ),
                      const SizedBox(height: 14),
                      if (patientType == 'registered')
                        _searchableDropdown(
                          controller: _patientField,
                          label: 'Patient',
                          icon: Icons.person_search_outlined,
                          items: patients,
                          itemLabel: _patientLabel,
                          onSelected: (patient) => setState(
                            () => patientId = patient == null
                                ? null
                                : _id(patient),
                          ),
                        )
                      else ...[
                        TextFormField(
                          controller: _newPatientName,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Patient name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              patientType == 'new' &&
                                  (value == null || value.trim().isEmpty)
                              ? 'Enter the patient name'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _newPatientAge,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            prefixIcon: Icon(Icons.cake_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (patientType != 'new') return null;
                            final age = int.tryParse(value?.trim() ?? '');
                            return age == null || age < 1 || age > 120
                                ? 'Enter an age between 1 and 120'
                                : null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _newPatientContact,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact number',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              patientType == 'new' &&
                                  (value == null || value.trim().isEmpty)
                              ? 'Enter a contact number'
                              : null,
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (mode == 'doctor') ...[
                        _searchableDropdown(
                          controller: _providerField,
                          label: 'Doctor',
                          icon: Icons.medical_services_outlined,
                          items: doctors,
                          itemLabel: _doctorLabel,
                          onSelected: (doctor) {
                            selectedProvider = doctor;
                            setState(
                              () => doctorId = doctor == null
                                  ? null
                                  : _id(doctor),
                            );
                            _loadSlots();
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: type,
                          decoration: const InputDecoration(
                            labelText: 'Appointment type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'offline',
                              child: Text('Offline'),
                            ),
                            DropdownMenuItem(
                              value: 'online',
                              child: Text('Online'),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() => type = v!);
                            _loadSlots();
                          },
                        ),
                      ] else
                        _searchableDropdown(
                          controller: _providerField,
                          label: 'Diagnostic',
                          icon: Icons.science_outlined,
                          items: diagnostics,
                          itemLabel: _diagnosticLabel,
                          hintText: 'Search by test name or category',
                          onSelected: (diagnostic) => setState(() {
                            selectedProvider = diagnostic;
                            diagnosticId = diagnostic == null
                                ? null
                                : _id(diagnostic);
                          }),
                        ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            date == null
                                ? 'Select date'
                                : DateFormat('dd MMM yyyy').format(date!),
                          ),
                        ),
                      ),
                      if (mode == 'doctor' && date != null) ...[
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            '$doctorId-${date?.toIso8601String()}-$type',
                          ),
                          initialValue: timeSlot,
                          decoration: InputDecoration(
                            labelText: loadingSlots
                                ? 'Loading slots…'
                                : 'Available time slot',
                            border: const OutlineInputBorder(),
                          ),
                          items: slots.where((s) => s['isBooked'] != true).map((
                            s,
                          ) {
                            final label = _slotLabel(s);
                            final end = s['endTime']?.toString();
                            return DropdownMenuItem(
                              value: label,
                              child: Text(
                                end == null ? label : '$label - $end',
                              ),
                            );
                          }).toList(),
                          onChanged: loadingSlots
                              ? null
                              : (v) => setState(() => timeSlot = v),
                          validator: (v) =>
                              v == null ? 'Select a time slot' : null,
                        ),
                      ],
                      if (mode == 'diagnostic') ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _notes,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Amount: ৳${_amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: submitting ? null : _submit,
          icon: submitting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(
            mode == 'doctor'
                ? 'Pay now ৳${_amount.toStringAsFixed(0)} '
                : 'Pay now ৳${_amount.toStringAsFixed(0)} ',
          ),
        ),
      ],
    );
  }
}
