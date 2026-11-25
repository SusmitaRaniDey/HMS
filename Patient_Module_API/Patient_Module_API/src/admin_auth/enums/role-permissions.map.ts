import { AdminPermission } from './admin-permission.enum';
import { AdminRole } from './admin-role.enum';

export const ROLE_PERMISSIONS: Record<AdminRole, AdminPermission[]> = {
  // ✅ SUPER_ADMIN: Has ALL permissions
  [AdminRole.SUPER_ADMIN]: Object.values(AdminPermission),

  // ✅ ADMIN: Can manage most resources but cannot manage other admins
  [AdminRole.ADMIN]: [
    AdminPermission.MANAGE_ADMIN,
    // Diagnostic permissions
    AdminPermission.CREATE_DIAGNOSTIC,
    AdminPermission.READ_DIAGNOSTIC,
    AdminPermission.UPDATE_DIAGNOSTIC,
    AdminPermission.DELETE_DIAGNOSTIC,
    AdminPermission.MANAGE_DIAGNOSTIC_STATUS,
    AdminPermission.IMPORT_DIAGNOSTIC,
    AdminPermission.EXPORT_DIAGNOSTIC,

    // Doctor permissions
    AdminPermission.CREATE_DOCTOR,
    AdminPermission.READ_DOCTOR,
    AdminPermission.UPDATE_DOCTOR,
    AdminPermission.DELETE_DOCTOR,

    // Appointment permissions
    AdminPermission.READ_APPOINTMENT,
    AdminPermission.UPDATE_APPOINTMENT,
    AdminPermission.DELETE_APPOINTMENT,
    AdminPermission.CANCEL_APPOINTMENT,
    AdminPermission.REASSIGN_APPOINTMENT,
    AdminPermission.BULK_UPDATE_APPOINTMENT,

    // Booking permissions
    AdminPermission.READ_BOOKING,
    AdminPermission.UPDATE_BOOKING,
    AdminPermission.DELETE_BOOKING,
    AdminPermission.CANCEL_BOOKING,
    AdminPermission.BULK_UPDATE_BOOKING,

    // User permissions
    AdminPermission.READ_USER,
    AdminPermission.UPDATE_USER,
    AdminPermission.DELETE_USER,

    // Billing permissions
    AdminPermission.READ_BILLING,
    AdminPermission.MANAGE_BILLING,

    // Can view audit logs
    AdminPermission.VIEW_AUDIT_LOG,
  ],

  // ✅ MANAGER: Can read and update, but cannot delete or manage critical operations
  [AdminRole.MANAGER]: [
    // Diagnostic permissions (no delete)
    AdminPermission.CREATE_DIAGNOSTIC,
    AdminPermission.READ_DIAGNOSTIC,
    AdminPermission.UPDATE_DIAGNOSTIC,
    AdminPermission.MANAGE_DIAGNOSTIC_STATUS,
    AdminPermission.EXPORT_DIAGNOSTIC,

    // Doctor permissions (no delete)
    AdminPermission.CREATE_DOCTOR,
    AdminPermission.READ_DOCTOR,
    AdminPermission.UPDATE_DOCTOR,

    // Appointment permissions (no delete)
    AdminPermission.READ_APPOINTMENT,
    AdminPermission.UPDATE_APPOINTMENT,
    AdminPermission.CANCEL_APPOINTMENT,
    AdminPermission.REASSIGN_APPOINTMENT,

    // Booking permissions (no delete)
    AdminPermission.READ_BOOKING,
    AdminPermission.UPDATE_BOOKING,
    AdminPermission.CANCEL_BOOKING,

    // User permissions (read and update only)
    AdminPermission.READ_USER,
    AdminPermission.UPDATE_USER,

    // Billing permissions (read-only)
    AdminPermission.READ_BILLING,

    // Can view audit logs
    AdminPermission.VIEW_AUDIT_LOG,
  ],

  // ✅ VIEWER: Read-only access to all resources
  [AdminRole.VIEWER]: [
    // Diagnostic permissions (read-only)
    AdminPermission.READ_DIAGNOSTIC,
    AdminPermission.EXPORT_DIAGNOSTIC,

    // Doctor permissions (read-only)
    AdminPermission.READ_DOCTOR,

    // Appointment permissions (read-only)
    AdminPermission.READ_APPOINTMENT,

    // Booking permissions (read-only)
    AdminPermission.READ_BOOKING,

    // User permissions (read-only)
    AdminPermission.READ_USER,

    // Billing permissions (read-only)
    AdminPermission.READ_BILLING,

    // Can view audit logs
    AdminPermission.VIEW_AUDIT_LOG,
  ],
};
