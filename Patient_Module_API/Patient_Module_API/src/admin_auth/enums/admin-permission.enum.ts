export enum AdminPermission {
  // Diagnostic permissions
  CREATE_DIAGNOSTIC = 'create_diagnostic',
  READ_DIAGNOSTIC = 'read_diagnostic',
  UPDATE_DIAGNOSTIC = 'update_diagnostic',
  DELETE_DIAGNOSTIC = 'delete_diagnostic',
  MANAGE_DIAGNOSTIC_STATUS = 'manage_diagnostic_status',
  IMPORT_DIAGNOSTIC = 'import_diagnostic',
  EXPORT_DIAGNOSTIC = 'export_diagnostic',

  // Doctor permissions
  CREATE_DOCTOR = 'create_doctor',
  READ_DOCTOR = 'read_doctor',
  UPDATE_DOCTOR = 'update_doctor',
  DELETE_DOCTOR = 'delete_doctor',

  // Appointment permissions
  READ_APPOINTMENT = 'read_appointment',
  UPDATE_APPOINTMENT = 'update_appointment',
  DELETE_APPOINTMENT = 'delete_appointment',
  CANCEL_APPOINTMENT = 'cancel_appointment',
  REASSIGN_APPOINTMENT = 'reassign_appointment',
  BULK_UPDATE_APPOINTMENT = 'bulk_update_appointment',

  // Booking permissions
  READ_BOOKING = 'read_booking',
  UPDATE_BOOKING = 'update_booking',
  DELETE_BOOKING = 'delete_booking',
  CANCEL_BOOKING = 'cancel_booking',
  BULK_UPDATE_BOOKING = 'bulk_update_booking',

  // User permissions
  READ_USER = 'read_user',
  UPDATE_USER = 'update_user',
  DELETE_USER = 'delete_user',

  // Billing permissions
  READ_BILLING = 'read_billing',
  MANAGE_BILLING = 'manage_billing',

  // Admin management permissions
  MANAGE_ADMIN = 'manage_admin',
  VIEW_AUDIT_LOG = 'view_audit_log',
  MANAGE_ROLES = 'manage_roles',
}
