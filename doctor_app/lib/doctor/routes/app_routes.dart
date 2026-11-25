class AppRoutes {
  // Welcome & Auth
  static const String WELCOME = '/';
  static const String LOGIN = '/doctor/login';

  // Main App
  static const String DASHBOARD = '/doctor/dashboard';
  static const String APPOINTMENTS = '/doctor/appointments';
  static const String PROFILE = '/doctor/profile';
  static const String EMERGENCY_CONSULTATION = '/doctor/emergency-consultation';

  // Appointment Routes
  static const String APPOINTMENT_DETAIL = '/doctor/appointment-detail';
  static const String PENDING_REQUESTS = '/doctor/pending-requests';
  static const String CONFIRMED_APPOINTMENTS = '/doctor/confirmed-appointments';
  static const String TODAY_APPOINTMENTS = '/doctor/today-appointments';
  static const String UPCOMING_APPOINTMENTS = '/doctor/upcoming-appointments';
  static const String APPOINTMENT_HISTORY = '/doctor/appointment-history';

  // Profile Routes
  static const String SETTINGS = '/doctor/settings';
  static const String CHANGE_PASSWORD = '/doctor/change-password';

  // Prescription
  static const String PRESCRIPTION_FORM = '/doctor/prescription-form';
}
