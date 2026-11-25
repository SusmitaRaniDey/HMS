class ApiEndpoints {
  // Medicines
  static const String MEDICINES = '/medicine-data';
  static const String MEDICINE_SEARCH = '/medicine-data/search';
  static String medicineBySl(int sl) => '/medicine-data/$sl';

  // Authentication
  static const String LOGIN = '/admin-auth/login';
  static const String CREATE_ADMIN = '/admin-auth/create';
  static const String ALL_ADMINS = '/admin-auth/all-admin';

  // Doctors
  static const String DOCTORS = '/admin-auth/doctors';
  static String doctorById(int id) => '/admin-auth/doctors/$id';
  static String doctorAppointments(int id) =>
      '/admin-auth/doctors/$id/appointments';
  static const String DOCTORS_WITH_APPOINTMENTS =
      '/admin-auth/doctors-with-appointments';

  // Diagnostics
  static const String DIAGNOSTICS = '/admin-auth/diagnostics';
  static const String DIAGNOSTICS_GROUPED = '/admin-auth/diagnostics/grouped';
  static String diagnosticsByItemCode(String itemCode) =>
      '/admin-auth/diagnostics/item/$itemCode';
  static String diagnosticById(int id) => '/admin-auth/diagnostics/$id';
  static String diagnosticStatus(int id) =>
      '/admin-auth/diagnostics/$id/status';
  static const String DIAGNOSTICS_IMPORT = '/admin-auth/diagnostics/import';
  static const String DIAGNOSTICS_EXPORT = '/admin-auth/diagnostics/export';

  // Appointments
  static const String APPOINTMENTS = '/admin-auth/appointments';
  static String doctorTimeSlots(int doctorId) =>
      '/appointments/doctor/$doctorId/time-slots';
  static String appointmentById(int id) => '/admin-auth/appointments/$id';
  static String appointmentInvoice(int id) =>
      '/admin-auth/appointments/$id/invoice';
  static String appointmentReschedule(int id) =>
      '/admin-auth/appointments/$id/reschedule';
  static String appointmentStatus(int id) =>
      '/admin-auth/appointments/$id/status';
  static String appointmentCancel(int id) =>
      '/admin-auth/appointments/$id/cancel';
  static String appointmentReassign(int id) =>
      '/admin-auth/appointments/$id/reassign';
  static const String APPOINTMENTS_BULK_STATUS =
      '/admin-auth/appointments/bulk-status';

  // Refunds
  static const String ADMIN_REFUNDS = '/admin/refunds';
  static String adminRefundProcessing(int id) =>
      '/admin/refunds/$id/processing';
  static String adminRefundProcess(int id) => '/admin/refunds/$id/process';
  static String adminRefundReject(int id) => '/admin/refunds/$id/reject';
  static String adminRefundInitiate(int appointmentId) =>
      '/admin/refunds/initiate/$appointmentId';

  // Diagnostic Bookings
  static const String DIAGNOSTIC_BOOKINGS = '/admin-auth/diagnostic-bookings';
  static String diagnosticBookingById(int id) =>
      '/admin-auth/diagnostic-bookings/$id';
  static String diagnosticBookingInvoice(int id) =>
      '/admin-auth/diagnostic-bookings/$id/invoice';
  static String diagnosticBookingCancel(int id) =>
      '/admin-auth/diagnostic-bookings/$id/cancel';
  static const String DIAGNOSTIC_BOOKINGS_BULK_STATUS =
      '/admin-auth/diagnostic-bookings/bulk-status';
  static String diagnosticBookingApprove(int id) =>
      '/admin-auth/diagnostic-bookings/$id/approve';
  static String diagnosticBookingReject(int id) =>
      '/admin-auth/diagnostic-bookings/$id/reject';

  // Billing
  static const String ADMIN_BILLING = '/admin/billing';
  static String billingById(int id) => '/admin/billing/$id';
  static String billingInvoicePdf(int id) => '/admin/billing/$id/invoice.pdf';
  static String billingByInvoiceNumber(String invoiceNumber) =>
      '/admin/billing/invoice/$invoiceNumber';
  static String billingByPatient(int patientId) =>
      '/admin/billing/patient/$patientId';

  // Users
  static const String USERS = '/admin-auth/users';
  static String userById(int id) => '/admin-auth/users/$id';

  // Staff (Admins)
  static const String STAFF = '/admin-auth/all-admin';
  static const String STAFF_CREATE = '/admin-auth/create';
  static String staffById(int id) => '/admin-auth/admins/$id';

  // Role Management
  static String assignRole(int adminId) =>
      '/admin-auth/admins/$adminId/assign-role';
  static String adminRole(int adminId) => '/admin-auth/admins/$adminId/role';
  static const String ADMINS_WITH_ROLES = '/admin-auth/admins-with-roles';
  static const String ALL_ROLES = '/admin-auth/roles';
  static String rolePermissions(String role) =>
      '/admin-auth/roles/$role/permissions';
}
