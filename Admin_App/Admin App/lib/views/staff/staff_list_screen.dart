import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controller/staff_controller.dart';
import '../../models/staff_model.dart';
import '../../routes/admin_routes.dart';
import '../../services/storage_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/helpers.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/custom_textfield.dart';

const _kRoles = ['super_admin', 'admin', 'manager'];

/// Roles selectable in the Add/Edit Staff dropdown for the *current* admin.
/// Only an existing super_admin may grant super_admin to someone else —
/// everyone else sees admin/manager only.
List<String> _selectableRoles() {
  final isSuperAdmin =
      Get.find<StorageService>().getAdminModel()?.isSuperAdmin ?? false;
  return isSuperAdmin
      ? _kRoles
      : _kRoles.where((r) => r != 'super_admin').toList();
}

class StaffListScreen extends StatelessWidget {
  const StaffListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StaffController>();

    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(selectedRoute: AdminRoutes.STAFF),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Column(
                children: [
                  _buildTopBar(context, controller),
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (controller.filteredStaff.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.groups_outlined,
                                size: 80.sp,
                                color: AppColors.textHint,
                              ),
                              SizedBox(height: 16.h),
                              Text('No staff found', style: AppTextStyles.h4),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: [
                          Expanded(child: _buildTable(context, controller)),
                          _buildPagination(controller),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, StaffController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      color: Colors.white,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Our Staff',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4.h),
              Text(
                'Manage all admin users',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Search
          SizedBox(
            width: 240.w,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, email, role...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
              ),
              onChanged: controller.searchStaff,
            ),
          ),
          SizedBox(width: 12.w),
          // Role filter
          Obx(() => Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedRole.value.isEmpty
                    ? null
                    : controller.selectedRole.value,
                hint: Text(
                  'All Roles',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text('All Roles', style: AppTextStyles.body2),
                  ),
                  ..._kRoles.map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(_formatRole(r), style: AppTextStyles.body2),
                    ),
                  ),
                ],
                onChanged: (val) => controller.filterByRole(val ?? ''),
              ),
            ),
          )),
          SizedBox(width: 12.w),
          IconButton(
            onPressed: controller.loadStaff,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            iconSize: 24.sp,
          ),
          SizedBox(width: 8.w),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(context, controller),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Staff'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Table ──────────────────────────────────────────────────────────────────
  Widget _buildTable(BuildContext context, StaffController controller) {
    return Container(
      margin: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.background),
          columns: [
            DataColumn(label: Text('#', style: AppTextStyles.subtitle1)),
            DataColumn(label: Text('Name', style: AppTextStyles.subtitle1)),
            DataColumn(label: Text('Email', style: AppTextStyles.subtitle1)),
            DataColumn(label: Text('Phone', style: AppTextStyles.subtitle1)),
            DataColumn(label: Text('Role', style: AppTextStyles.subtitle1)),
            DataColumn(label: Text('Created', style: AppTextStyles.subtitle1)),
            DataColumn(label: Text('Actions', style: AppTextStyles.subtitle1)),
          ],
          rows: controller.paginatedStaff.map((member) {
            String formattedDate = 'N/A';
            try {
              if (member.createdAt.isNotEmpty) {
                formattedDate = DateFormat(
                  'dd MMM yyyy',
                ).format(DateTime.parse(member.createdAt));
              }
            } catch (_) {
              formattedDate = member.createdAt;
            }

            return DataRow(cells: [
              DataCell(Text(
                member.id.toString(),
                style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
              )),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14.r,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(member.name, style: AppTextStyles.body2),
                ],
              )),
              DataCell(Text(member.email, style: AppTextStyles.body2)),
              DataCell(Text(member.phone, style: AppTextStyles.body2)),
              DataCell(_RoleBadge(role: member.role)),
              DataCell(Text(formattedDate, style: AppTextStyles.body2)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, color: AppColors.info),
                    onPressed: () => _showViewDialog(member),
                    tooltip: 'View',
                    iconSize: 18.sp,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(6.w),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.warning),
                    onPressed: () => _showEditDialog(context, controller, member),
                    tooltip: 'Edit',
                    iconSize: 18.sp,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(6.w),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => controller.deleteStaff(member.id, member.name),
                    tooltip: 'Delete',
                    iconSize: 18.sp,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(6.w),
                  ),
                ],
              )),
            ]);
          }).toList(),
        )),
      ),
    );
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  Widget _buildPagination(StaffController controller) {
    return Obx(() {
      final total = controller.totalPages;
      final current = controller.currentPage.value;
      final count = controller.filteredStaff.length;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        color: Colors.white,
        child: Row(
          children: [
            Text(
              'Showing ${controller.paginatedStaff.length} of $count staff',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(),
            IconButton(
              onPressed: current > 0 ? controller.prevPage : null,
              icon: const Icon(Icons.chevron_left),
              iconSize: 20.sp,
            ),
            ...List.generate(total, (i) {
              final isActive = i == current;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: InkWell(
                  onTap: () => controller.currentPage.value = i,
                  borderRadius: BorderRadius.circular(6.r),
                  child: Container(
                    width: 30.w,
                    height: 30.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppTextStyles.body2.copyWith(
                        color: isActive ? Colors.white : AppColors.textSecondary,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
            IconButton(
              onPressed: current < total - 1 ? controller.nextPage : null,
              icon: const Icon(Icons.chevron_right),
              iconSize: 20.sp,
            ),
          ],
        ),
      );
    });
  }

  // ── View Dialog ────────────────────────────────────────────────────────────
  void _showViewDialog(StaffModel member) {
    String formattedCreated = member.createdAt;
    String formattedUpdated = member.updatedAt;
    try {
      formattedCreated = DateFormat('dd MMM yyyy, hh:mm a')
          .format(DateTime.parse(member.createdAt));
      formattedUpdated = DateFormat('dd MMM yyyy, hh:mm a')
          .format(DateTime.parse(member.updatedAt));
    } catch (_) {}

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: 480.w,
          padding: EdgeInsets.all(28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Staff Details',
                    style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Center(
                child: CircleAvatar(
                  radius: 32.r,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              _detailRow('ID', '#${member.id}'),
              _detailRow('Name', member.name),
              _detailRow('Email', member.email),
              _detailRow('Phone', member.phone),
              _detailRowWidget('Role', _RoleBadge(role: member.role)),
              _detailRow('Created', formattedCreated),
              _detailRow('Updated', formattedUpdated),
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: Get.back,
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Add Dialog ─────────────────────────────────────────────────────────────
  void _showAddDialog(BuildContext context, StaffController controller) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedRole = 'admin';

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            width: 520.w,
            padding: EdgeInsets.all(28.w),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Staff Member',
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: Get.back,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    CustomTextField(
                      controller: nameCtrl,
                      label: 'Full Name',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    SizedBox(height: 14.h),
                    CustomTextField(
                      controller: emailCtrl,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    CustomTextField(
                      controller: phoneCtrl,
                      label: 'Phone',
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                    ),
                    SizedBox(height: 14.h),
                    CustomTextField(
                      controller: passCtrl,
                      label: 'Password',
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    CustomTextField(
                      controller: confirmPassCtrl,
                      label: 'Confirm Password',
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm password';
                        if (v != passCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    // Role dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role',
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedRole,
                              items: _selectableRoles()
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(_formatRole(r)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedRole = val ?? 'admin'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: Get.back,
                          child: const Text('Cancel'),
                        ),
                        SizedBox(width: 12.w),
                        Obx(() => ElevatedButton(
                          onPressed: controller.isSubmitting.value
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  if (selectedRole == 'super_admin') {
                                    final confirmedSuper =
                                        await Helpers.showConfirmDialog(
                                      title: 'Grant Super Admin',
                                      message:
                                          'You are about to create a new SUPER ADMIN account. '
                                          'This grants full control over all admin accounts, '
                                          'including the ability to create, edit and delete other admins. '
                                          'Are you sure you want to proceed?',
                                      confirmText: 'Grant Super Admin',
                                    );
                                    if (!confirmedSuper) return;
                                  }
                                  controller.createStaff({
                                    'name': nameCtrl.text.trim(),
                                    'email': emailCtrl.text.trim(),
                                    'phone': phoneCtrl.text.trim(),
                                    'password': passCtrl.text,
                                    'role': selectedRole,
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                          ),
                          child: controller.isSubmitting.value
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Add Staff'),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Edit Dialog ────────────────────────────────────────────────────────────
  void _showEditDialog(
    BuildContext context,
    StaffController controller,
    StaffModel member,
  ) {
    final nameCtrl = TextEditingController(text: member.name);
    final phoneCtrl = TextEditingController(text: member.phone);
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedRole = member.role;

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            width: 520.w,
            padding: EdgeInsets.all(28.w),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Staff Member',
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: Get.back,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    CustomTextField(
                      controller: nameCtrl,
                      label: 'Full Name',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    SizedBox(height: 14.h),
                    CustomTextField(
                      controller: phoneCtrl,
                      label: 'Phone',
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                    ),
                    SizedBox(height: 14.h),
                    CustomTextField(
                      controller: passCtrl,
                      label: 'New Password (leave blank to keep current)',
                      obscureText: true,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && v.length < 8) {
                          return 'Minimum 8 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    // Role dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role',
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: Builder(builder: (_) {
                              // Always keep the member's current role selectable
                              // even if it's super_admin and this editor isn't
                              // one themselves — otherwise DropdownButton
                              // crashes because `value` wouldn't match any item.
                              // It just can't be *changed to* super_admin by a
                              // non-super-admin.
                              final roles = _selectableRoles();
                              final dropdownRoles = roles.contains(selectedRole)
                                  ? roles
                                  : [...roles, selectedRole];
                              return DropdownButton<String>(
                                value: selectedRole,
                                items: dropdownRoles
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(_formatRole(r)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => selectedRole = val ?? member.role),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: Get.back,
                          child: const Text('Cancel'),
                        ),
                        SizedBox(width: 12.w),
                        Obx(() => ElevatedButton(
                          onPressed: controller.isSubmitting.value
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  final grantingSuperAdmin =
                                      selectedRole == 'super_admin' &&
                                          member.role != 'super_admin';
                                  if (grantingSuperAdmin) {
                                    final confirmedSuper =
                                        await Helpers.showConfirmDialog(
                                      title: 'Grant Super Admin',
                                      message:
                                          'You are about to promote "${member.name}" to SUPER ADMIN. '
                                          'This grants full control over all admin accounts, '
                                          'including the ability to create, edit and delete other admins. '
                                          'Are you sure you want to proceed?',
                                      confirmText: 'Grant Super Admin',
                                    );
                                    if (!confirmedSuper) return;
                                  }
                                  final data = <String, dynamic>{
                                    'name': nameCtrl.text.trim(),
                                    'phone': phoneCtrl.text.trim(),
                                    'role': selectedRole,
                                  };
                                  if (passCtrl.text.isNotEmpty) {
                                    data['password'] = passCtrl.text;
                                  }
                                  controller.updateStaff(member.id, data);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                          ),
                          child: controller.isSubmitting.value
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Update'),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          SizedBox(
            width: 90.w,
            child: Text(
              '$label:',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRowWidget(String label, Widget child) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          SizedBox(
            width: 90.w,
            child: Text(
              '$label:',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            ),
          ),
          child,
        ],
      ),
    );
  }

  String _formatRole(String role) {
    return role
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// ── Role Badge ─────────────────────────────────────────────────────────────────
class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label(role),
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'super_admin':
        return const Color(0xFF8B5CF6); // purple
      case 'admin':
        return const Color(0xFF3B82F6); // blue
      case 'manager':
        return const Color(0xFF22C55E); // green
      case 'viewer':
        return const Color(0xFF6B7280); // gray
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _label(String role) {
    return role
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
