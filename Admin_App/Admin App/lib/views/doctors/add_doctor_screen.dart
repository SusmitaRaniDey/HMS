import 'package:admin_panel_web_app/utils/helpers.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/doctor_controller.dart';
import '../../models/doctor_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/schedule_time_field.dart';

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;

  void _handleSubmit(
    DoctorsController controller,
    GlobalKey<FormState> formKey,
  ) {
    // Trigger validation
    final isValid = formKey.currentState!.validate();

    if (!isValid) {
      // Scroll to the first error field
      final formContext = formKey.currentContext;
      if (formContext != null) {
        Scrollable.ensureVisible(
          formContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
      return;
    }

    if (controller.workingDays.isEmpty) {
      Helpers.showErrorSnackbar(
        'Error',
        'Please add at least one offline schedule',
      );
      return;
    }

    if (controller.onlineSchedule.isEmpty) {
      Helpers.showErrorSnackbar(
        'Error',
        'Please add at least one online schedule',
      );
      return;
    }

    // Show loading state
    setState(() {
      _isSubmitting = true;
    });

    final languages = controller.languagesController.text
        .trim()
        .split(',')
        .map((e) => e.trim())
        .toList();

    final doctor = DoctorModel(
      name: controller.nameController.text.trim(),
      email: controller.emailController.text.trim(),
      password: controller.passwordController.text.trim(),
      phone: controller.phoneController.text.trim(),
      degrees: controller.degreesController.text.trim(),
      specialty: controller.specialtyController.text.trim(),
      experience: int.parse(controller.experienceController.text.trim()),
      workingAt: controller.workingAtController.text.trim(),
      onlineFee: double.parse(controller.onlineFeeController.text.trim()),
      offlineFee: double.parse(controller.offlineFeeController.text.trim()),
      biography: controller.biographyController.text.trim(),
      languages: languages,
      workingDays: controller.workingDays.toList(),
      onlineSchedule: controller.onlineSchedule.toList(),
      consultLimitPerDay: int.parse(controller.consultLimitController.text),
    );

    // Call createDoctor and handle completion
    controller.createDoctor(doctor).then((_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addWorkingDay(BuildContext context, DoctorsController controller) {
    final List<String> days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    showDialog(
      context: context,
      builder: (context) {
        String selectedDay = days[0];
        var startTime = const TimeOfDay(hour: 9, minute: 0);
        var endTime = const TimeOfDay(hour: 17, minute: 0);

        return AlertDialog(
          title: const Text('Add Working Day'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatefulBuilder(
                builder: (context, setDropdownState) => DropdownButton<String>(
                  value: selectedDay,
                  isExpanded: true,
                  items: days
                      .map(
                        (day) => DropdownMenuItem(value: day, child: Text(day)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDropdownState(() {
                      selectedDay = value ?? selectedDay;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              ScheduleTimeField(
                label: 'Start Time',
                initialTime: startTime,
                onChanged: (value) => startTime = value,
              ),
              const SizedBox(height: 12),
              ScheduleTimeField(
                label: 'End Time',
                initialTime: endTime,
                onChanged: (value) => endTime = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                controller.addWorkingDay(
                  DaySchedule(
                    day: selectedDay,
                    startTime: formatScheduleTime(startTime),
                    endTime: formatScheduleTime(endTime),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addOnlineSchedule(BuildContext context, DoctorsController controller) {
    final List<String> days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    String selectedDay = days[0];
    var startTime = const TimeOfDay(hour: 9, minute: 0);
    var endTime = const TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Online Schedule'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedDay,
                    isExpanded: true,
                    items: days
                        .map(
                          (day) =>
                              DropdownMenuItem(value: day, child: Text(day)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDay = value ?? selectedDay;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ScheduleTimeField(
                    label: 'Start Time',
                    initialTime: startTime,
                    onChanged: (value) => startTime = value,
                  ),
                  const SizedBox(height: 12),
                  ScheduleTimeField(
                    label: 'End Time',
                    initialTime: endTime,
                    onChanged: (value) => endTime = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    controller.addOnlineSchedule(
                      OnlineSchedule(
                        day: selectedDay,
                        startTime: formatScheduleTime(startTime),
                        endTime: formatScheduleTime(endTime),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DoctorsController>();
    final formKey = GlobalKey<FormState>();
    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(selectedRoute: '/doctors'),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.all(24.w),
                      child: Container(
                        padding: EdgeInsets.all(32.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Doctor Information',
                                style: AppTextStyles.h4.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 24.h),

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: controller.nameController,
                                      label: 'Full Name',
                                      hint: 'Dr. John Doe',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: controller.emailController,
                                      label: 'Email',
                                      hint: 'doctor@example.com',
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Email is required';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Enter valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20.h),

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: controller.passwordController,
                                      label: 'Password',
                                      hint: 'SecurePass123!',
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
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: controller.phoneController,
                                      label: 'Phone Number',
                                      hint: '+880-1711223344',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Phone is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20.h),

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: controller.degreesController,
                                      label: 'Degrees',
                                      hint: 'MD, MBBS, DM Cardiology',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Degrees required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: CustomTextField(
                                      controller:
                                          controller.specialtyController,
                                      label: 'Specialty',
                                      hint: 'Cardiology',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Specialty is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20.h),

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller:
                                          controller.experienceController,
                                      label: 'Experience (Years)',
                                      hint: '12',
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Experience is required';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Enter valid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: CustomTextField(
                                      controller:
                                          controller.workingAtController,
                                      label: 'Working At',
                                      hint: 'City Heart Hospital',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Working place is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20.h),

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller:
                                          controller.onlineFeeController,
                                      label: 'Consultation Fee (Online)',
                                      hint: '500',
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Online fee is required';
                                        }
                                        final fee = double.tryParse(value);
                                        if (fee == null) {
                                          return 'Enter valid amount';
                                        }
                                        if (fee < 0) {
                                          return 'Fee cannot be negative';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: CustomTextField(
                                      controller:
                                          controller.offlineFeeController,
                                      label: 'Consultation Fee (Offline)',
                                      hint: '500',
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Offline fee is required';
                                        }
                                        final fee = double.tryParse(value);
                                        if (fee == null) {
                                          return 'Enter valid amount';
                                        }
                                        if (fee < 0) {
                                          return 'Fee cannot be negative';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: CustomTextField(
                                      controller:
                                          controller.consultLimitController,
                                      label: 'Consult Limit Per Day',
                                      hint: '30',
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Enter valid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20.h),

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller:
                                          controller.languagesController,
                                      label: 'Languages (comma-separated)',
                                      hint: 'Bangla, English, Hindi',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Languages required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20.h),

                              CustomTextField(
                                controller: controller.biographyController,
                                label: 'Biography',
                                hint:
                                    'Experienced cardiologist with 12 years of clinical practice...',
                                maxLines: 5,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Biography is required';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 24.h),

                              // Image picker section
                              Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Profile Picture',
                                      style: AppTextStyles.body2.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                    Obx(() {
                                      final imageFile = controller
                                          .imagePickerService
                                          .selectedImage
                                          .value;
                                      final hasImage = imageFile != null;

                                      return Column(
                                        children: [
                                          if (hasImage)
                                            Container(
                                              height: 200.h,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey[300]!,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                child: FutureBuilder<Uint8List>(
                                                  future: imageFile
                                                      .readAsBytes(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      return Image.memory(
                                                        snapshot.data!,
                                                        fit: BoxFit.cover,
                                                      );
                                                    }
                                                    return const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          SizedBox(height: 12.h),
                                          Row(
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () => controller
                                                    .imagePickerService
                                                    .pickImage(),
                                                icon: Icon(
                                                  hasImage
                                                      ? Icons.edit
                                                      : Icons
                                                            .add_photo_alternate,
                                                ),
                                                label: Text(
                                                  hasImage
                                                      ? 'Change Image'
                                                      : 'Select Image',
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                ),
                                              ),
                                              if (hasImage) ...[
                                                SizedBox(width: 12.w),
                                                OutlinedButton.icon(
                                                  onPressed: () => controller
                                                      .imagePickerService
                                                      .clearImage(),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                  label: const Text('Remove'),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                        foregroundColor:
                                                            Colors.red,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24.h),

                              Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Offline Schedule',
                                          style: AppTextStyles.body2,
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () => _addWorkingDay(
                                            context,
                                            controller,
                                          ),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add Slot'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    Obx(() {
                                      if (controller.workingDays.isEmpty) {
                                        return Text(
                                          'No offline schedule added yet',
                                          style: AppTextStyles.body2.copyWith(
                                            color: Colors.grey,
                                          ),
                                        );
                                      }

                                      return ListView.builder(
                                        shrinkWrap: true,
                                        itemCount:
                                            controller.workingDays.length,
                                        itemBuilder: (context, index) {
                                          final day =
                                              controller.workingDays[index];
                                          return Padding(
                                            padding: EdgeInsets.only(top: 8.h),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '${day.day}: ${formatScheduleTimeForDisplay(context, day.startTime)} - ${formatScheduleTimeForDisplay(context, day.endTime)}',
                                                  style: AppTextStyles.body2,
                                                ),
                                                IconButton(
                                                  onPressed: () => controller
                                                      .removeWorkingDay(index),
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  constraints: BoxConstraints(
                                                    minWidth: 24.w,
                                                    minHeight: 24.h,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  iconSize: 18.sp,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              ),

                              SizedBox(height: 24.h),

                              Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Online Schedule',
                                          style: AppTextStyles.body2,
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () => _addOnlineSchedule(
                                            context,
                                            controller,
                                          ),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add Slot'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    Obx(() {
                                      if (controller.onlineSchedule.isEmpty) {
                                        return Text(
                                          'No online schedule added yet',
                                          style: AppTextStyles.body2.copyWith(
                                            color: Colors.grey,
                                          ),
                                        );
                                      }

                                      return ListView.builder(
                                        shrinkWrap: true,
                                        itemCount:
                                            controller.onlineSchedule.length,
                                        itemBuilder: (context, index) {
                                          final slot =
                                              controller.onlineSchedule[index];
                                          return Padding(
                                            padding: EdgeInsets.only(top: 8.h),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '${slot.day}: ${formatScheduleTimeForDisplay(context, slot.startTime)} - ${formatScheduleTimeForDisplay(context, slot.endTime)}',
                                                  style: AppTextStyles.body2,
                                                ),
                                                IconButton(
                                                  onPressed: () => controller
                                                      .removeOnlineSchedule(
                                                        index,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  constraints: BoxConstraints(
                                                    minWidth: 24.w,
                                                    minHeight: 24.h,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  iconSize: 18.sp,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              ),

                              SizedBox(height: 32.h),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => Get.back(),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 32.w,
                                        vertical: 16.h,
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                  SizedBox(width: 16.w),
                                  ElevatedButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : () => _handleSubmit(
                                            controller,
                                            formKey,
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 32.w,
                                        vertical: 16.h,
                                      ),
                                    ),
                                    child: _isSubmitting
                                        ? SizedBox(
                                            width: 20.w,
                                            height: 20.h,
                                            child:
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                          )
                                        : const Text('Add Doctor'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.all(24.w),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
          ),
          SizedBox(width: 16.w),
          Text(
            'Add New Doctor',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
