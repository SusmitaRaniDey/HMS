import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controller/emergency_controller.dart';
import '../../widgets/admin_sidebar.dart';

class EmergencyDashboardScreen extends GetView<EmergencyController> {
  const EmergencyDashboardScreen({super.key});

  List<dynamic> _items(String key) =>
      (controller.dashboard[key] as List?) ?? const [];

  Future<void> _showCreate(BuildContext context) async {
    if (controller.doctors.isEmpty) return;
    await Get.dialog(
      _CreateEmergencyAvailabilityDialog(
        doctors: controller.doctors,
        onSave: controller.createAvailability,
      ),
    );
  }

  Widget _metric(String label, int value, Color color) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(selectedRoute: '/emergency-doctors'),
          Expanded(
            child: Obx(
              () => controller.isLoading.value && controller.dashboard.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: controller.refreshData,
                      child: ListView(
                        padding: const EdgeInsets.all(28),
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Emergency Consultations',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () => _showCreate(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Create Availability'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _metric(
                                'Available Doctors',
                                _items('availableDoctors').length,
                                Colors.green,
                              ),
                              _metric(
                                'Active',
                                _items('active').length,
                                Colors.orange,
                              ),
                              _metric(
                                'Completed',
                                _items('completed').length,
                                Colors.blue,
                              ),
                              _metric(
                                'Cancelled',
                                _items('cancelled').length,
                                Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Currently Available',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._items('availableDoctors').map(
                            (item) => Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.emergency),
                                ),
                                title: Text(item['name'] ?? 'Doctor'),
                                subtitle: Text(
                                  '${item['department'] ?? ''} • Until ${item['availableUntil']}',
                                ),
                                trailing: TextButton(
                                  onPressed: () =>
                                      controller.disable(item['doctorId']),
                                  child: const Text('Turn Off'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Consultation History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PaginatedDataTable(
                            header: const Text('Emergency Bookings'),
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Doctor')),
                              DataColumn(label: Text('Patient')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Created')),
                            ],
                            source: _EmergencySource(_items('history')),
                            rowsPerPage: _items('history').length.clamp(1, 10),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateEmergencyAvailabilityDialog extends StatefulWidget {
  final List<Map<String, dynamic>> doctors;
  final Future<void> Function(int, DateTime, DateTime, double?) onSave;

  const _CreateEmergencyAvailabilityDialog({
    required this.doctors,
    required this.onSave,
  });

  @override
  State<_CreateEmergencyAvailabilityDialog> createState() =>
      _CreateEmergencyAvailabilityDialogState();
}

class _CreateEmergencyAvailabilityDialogState
    extends State<_CreateEmergencyAvailabilityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _feeController = TextEditingController();
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  Map<String, dynamic>? _doctor;
  DateTime _from = DateTime.now();
  late DateTime _until = _from.add(const Duration(hours: 1));
  bool _submitted = false;

  String _qualification(Map<String, dynamic> doctor) {
    final qualification =
        doctor['qualification'] ??
        doctor['qualifications'] ??
        doctor['degree'] ??
        'MBBS';
    final specialty = doctor['specialty'] ?? doctor['department'];
    return specialty == null || specialty.toString().trim().isEmpty
        ? qualification.toString()
        : '$qualification (${specialty.toString()})';
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _submitted = true);
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || !_until.isAfter(_from)) return;
    final doctorId = int.tryParse('${_doctor?['id']}');
    if (doctorId == null) return;
    widget.onSave(
      doctorId,
      _from,
      _until,
      double.tryParse(_feeController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateError = _submitted && !_until.isAfter(_from)
        ? 'Available Until must be later than Available From'
        : null;
    return Dialog(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 32),
                  const Text(
                    'Doctor Selection',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _doctorField(),
                  const SizedBox(height: 28),
                  const Text(
                    'Availability',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _availabilityFields(),
                  if (dateError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      dateError,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _feeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final input = value?.trim() ?? '';
                      if (input.isEmpty) return null;
                      final fee = double.tryParse(input);
                      if (fee == null) {
                        return 'Emergency fee must be numeric';
                      }
                      if (fee < 0) return 'Emergency fee cannot be negative';
                      return null;
                    },
                    decoration:
                        _inputDecoration(
                          label: 'Emergency Fee',
                          hint: 'Enter emergency fee',
                          prefixIcon: Icons.payments_outlined,
                        ).copyWith(
                          suffixText: 'BDT',
                          helperText:
                              'Leave empty if no additional fee is required.',
                        ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(height: 1, color: Color(0xFFE4E7EC)),
                  const SizedBox(height: 24),
                  _footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFFEAF2FF),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.medical_services_outlined,
          color: Color(0xFF2563EB),
        ),
      ),
      const SizedBox(width: 16),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Emergency Availability',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172033),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Set when the doctor is available for emergency appointments.',
              style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _doctorField() => Autocomplete<Map<String, dynamic>>(
    displayStringForOption: (doctor) => doctor['name']?.toString() ?? 'Doctor',
    optionsBuilder: (value) {
      final query = value.text.trim().toLowerCase();
      return widget.doctors.where((doctor) {
        if (query.isEmpty) return true;
        return '${doctor['name'] ?? ''} ${_qualification(doctor)}'
            .toLowerCase()
            .contains(query);
      });
    },
    optionsViewBuilder: (context, onSelected, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 696, maxHeight: 280),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final doctor = options.elementAt(index);
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF2FF),
                  child: Icon(Icons.person_outline, color: Color(0xFF2563EB)),
                ),
                title: Text(doctor['name']?.toString() ?? 'Doctor'),
                subtitle: Text(_qualification(doctor)),
                onTap: () => onSelected(doctor),
              );
            },
          ),
        ),
      ),
    ),
    onSelected: (doctor) => setState(() => _doctor = doctor),
    fieldViewBuilder: (context, textController, focusNode, onSubmitted) =>
        TextFormField(
          controller: textController,
          focusNode: focusNode,
          onChanged: (_) => setState(() => _doctor = null),
          onFieldSubmitted: (_) => onSubmitted(),
          validator: (_) =>
              _doctor == null ? 'Please search for and select a doctor' : null,
          decoration:
              _inputDecoration(
                hint: 'Search doctor by name or specialty',
                prefixIcon: Icons.person_outline,
              ).copyWith(
                suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                helperText: _doctor == null ? null : _qualification(_doctor!),
              ),
        ),
  );

  Widget _availabilityFields() => LayoutBuilder(
    builder: (context, constraints) {
      final fromField = _dateField(
        label: 'Available From',
        value: _from,
        onTap: () async {
          final value = await _pickDateTime(_from);
          if (value != null) {
            setState(() {
              _from = value;
              if (!_until.isAfter(_from)) {
                _until = _from.add(const Duration(hours: 1));
              }
            });
          }
        },
      );
      final untilField = _dateField(
        label: 'Available Until',
        value: _until,
        onTap: () async {
          final value = await _pickDateTime(_until);
          if (value != null) setState(() => _until = value);
        },
      );
      if (constraints.maxWidth < 600) {
        return Column(
          children: [fromField, const SizedBox(height: 16), untilField],
        );
      }
      return Row(
        children: [
          Expanded(child: fromField),
          const SizedBox(width: 16),
          Expanded(child: untilField),
        ],
      );
    },
  );

  Widget _dateField({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: InputDecorator(
      decoration: _inputDecoration(
        label: label,
        prefixIcon: Icons.calendar_today_outlined,
      ).copyWith(suffixIcon: const Icon(Icons.access_time_rounded)),
      child: Text(
        _dateFormat.format(value),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
  );

  InputDecoration _inputDecoration({
    String? label,
    String? hint,
    required IconData prefixIcon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(prefixIcon, color: const Color(0xFF667085)),
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD92D20)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  );

  Widget _footer() => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      SizedBox(
        height: 46,
        child: OutlinedButton(
          onPressed: Get.back,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: const Text('Cancel'),
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(
        height: 46,
        child: FilledButton.icon(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ),
    ],
  );
}

class _EmergencySource extends DataTableSource {
  final List<dynamic> rows;
  _EmergencySource(this.rows);
  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) return null;
    final row = rows[index];
    return DataRow(
      cells: [
        DataCell(Text('${row['id']}')),
        DataCell(Text(row['doctor']?['name'] ?? '${row['doctorId']}')),
        DataCell(Text(row['patient']?['name'] ?? '${row['patientId']}')),
        DataCell(Text(row['status'] ?? '')),
        DataCell(Text(row['createdAt'] ?? '')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => rows.length;
  @override
  int get selectedRowCount => 0;
}
