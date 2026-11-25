import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controller/patient_history_controller.dart';
import '../../controller/users_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/custom_textfield.dart';
import '../../routes/admin_routes.dart';
import 'patient_history_screen.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UsersController>();

    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(selectedRoute: AdminRoutes.USERS),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Column(
                children: [
                  _buildTopBar(controller),
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (controller.filteredUsers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outlined,
                                size: 80.sp,
                                color: AppColors.textHint,
                              ),
                              SizedBox(height: 16.h),
                              Text('No users found', style: AppTextStyles.h4),
                            ],
                          ),
                        );
                      }

                      return _buildUsersTable(controller);
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

  Widget _buildTopBar(UsersController controller) {
    return Container(
      padding: EdgeInsets.all(24.w),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient Management',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4.h),
              Text(
                'Manage all registered patients',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 300.w,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  onChanged: controller.searchUsers,
                ),
              ),
              SizedBox(width: 16.w),
              ElevatedButton.icon(
                onPressed: () => _showAddPatientDialog(controller),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add Patient'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              IconButton(
                onPressed: () => controller.loadUsers(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                iconSize: 28.sp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPatientDialog(UsersController controller) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String gender = 'male';

    await Get.dialog<void>(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Container(
            width: 560.w,
            constraints: BoxConstraints(maxHeight: 800.h),
            padding: EdgeInsets.all(24.w),
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
                          'Add Patient',
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
                      controller: nameController,
                      label: 'Name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    SizedBox(height: 14.h),
                    CustomTextField(
                      controller: ageController,
                      label: 'Age',
                      prefixIcon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final age = int.tryParse(value?.trim() ?? '');
                        if (age == null) return 'Enter a valid age';
                        if (age < 1 || age > 120) {
                          return 'Age must be between 1 and 120';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'Gender',
                      style: AppTextStyles.subtitle1.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    DropdownButtonFormField<String>(
                      initialValue: gender,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.wc_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => gender = value);
                        }
                      },
                    ),
                    SizedBox(height: 14.h),
                    CustomTextField(
                      controller: emailController,
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Email is required';
                        if (!GetUtils.isEmail(email)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    CustomTextField(
                      controller: phoneController,
                      label: 'Contact Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Contact number is required'
                          : null,
                    ),
                    SizedBox(height: 14.h),
                    CustomTextField(
                      controller: passwordController,
                      label: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
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
                        ElevatedButton.icon(
                          onPressed: () {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            controller.createPatient({
                              'name': nameController.text.trim(),
                              'age': int.parse(ageController.text.trim()),
                              'gender': gender,
                              'email': emailController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'password': passwordController.text,
                            });
                          },
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Add Patient'),
                        ),
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

    nameController.dispose();
    ageController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
  }

  Widget _buildUsersTable(UsersController controller) {
    return Container(
      margin: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('ID', style: AppTextStyles.subtitle1)),
            DataColumn(label: Text('Name', style: AppTextStyles.subtitle1)),
            DataColumn(label: Text('Phone', style: AppTextStyles.subtitle1)),
            DataColumn(label: Text('History', style: AppTextStyles.subtitle1)),
            DataColumn(label: Text('Actions', style: AppTextStyles.subtitle1)),
          ],
          rows: controller.filteredUsers.map((user) {
            return DataRow(
              cells: [
                DataCell(Text(user.id.toString())),
                DataCell(Text(user.name)),
                DataCell(Text(user.phone)),
                DataCell(
                  OutlinedButton.icon(
                    onPressed: () =>
                        _showHistoryDialog(user),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility,
                            color: AppColors.info),
                        onPressed: () => _showUserDetails(user),
                        tooltip: 'View',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: AppColors.warning),
                        onPressed: () =>
                            _showEditUserDialog(controller, user),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: AppColors.error),
                        onPressed: () => controller.deleteUser(user.id),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showHistoryDialog(user) {
    const tag = 'patient_history_dialog';

    if (Get.isRegistered<PatientHistoryController>(tag: tag)) {
      Get.delete<PatientHistoryController>(tag: tag, force: true);
    }

    final controller = Get.put(PatientHistoryController(), tag: tag);
    controller.setPatient(user.id, user.name, user.phone);

    Get.dialog(
      PatientHistoryDialog(controller: controller),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    ).then((_) {
      if (Get.isRegistered<PatientHistoryController>(tag: tag)) {
        Get.delete<PatientHistoryController>(tag: tag, force: true);
      }
    });
  }

  void _showUserDetails(user) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          width: 500.w,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User Details',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              _buildDetailRow('ID', user.id.toString()),
              _buildDetailRow('Name', user.name),
              _buildDetailRow('Phone', user.phone),
              _buildDetailRow('Age', user.age?.toString() ?? 'N/A'),
              _buildDetailRow('Gender', user.gender?.toUpperCase() ?? 'N/A'),
              _buildDetailRow('Registered', user.createdAt),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(UsersController controller, user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final ageController = TextEditingController(
      text: user.age?.toString() ?? '',
    );

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          width: 500.w,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit User',
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24.h),
              CustomTextField(controller: nameController, label: 'Name'),
              SizedBox(height: 16.h),
              CustomTextField(controller: phoneController, label: 'Phone'),
              SizedBox(height: 16.h),
              CustomTextField(
                controller: ageController,
                label: 'Age',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      nameController.dispose();
                      phoneController.dispose();
                      ageController.dispose();
                      Get.back();
                    },
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: 16.w),
                  ElevatedButton(
                    onPressed: () {
                      final data = {
                        'name': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                        if (ageController.text.isNotEmpty)
                          'age': int.parse(ageController.text.trim()),
                      };
                      controller.updateUser(user.id, data);
                      nameController.dispose();
                      phoneController.dispose();
                      ageController.dispose();
                    },
                    child: const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
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
}
