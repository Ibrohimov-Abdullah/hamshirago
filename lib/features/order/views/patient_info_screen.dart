import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../controllers/order_controller.dart';

class PatientInfoScreen extends StatefulWidget {
  const PatientInfoScreen({super.key});
  @override State<PatientInfoScreen> createState() => _PatientInfoScreenState();
}

class _PatientInfoScreenState extends State<PatientInfoScreen> {
  final ctrl = Get.find<OrderController>();
  final _ageScroll = ScrollController();
  static const _min = 18, _max = 100, _iw = 56.0;

  // 0=now, 1=single, 2=multiDay
  int _scheduleMode = 0;

  bool _genderError = false;
  bool _timeError = false;
  bool _buildingError = false;
  bool _apartmentError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idx = ctrl.patientAge.value - _min;
      final targetOffset = (idx * _iw).clamp(
        0.0,
        _ageScroll.position.maxScrollExtent,
      );
      _ageScroll.jumpTo(targetOffset);
    });
  }

  @override
  void dispose() {
    _ageScroll.dispose();
    super.dispose();
  }

  void _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
          timePickerTheme: const TimePickerThemeData(
            hourMinuteTextColor: AppColors.primary,
          ),
        ),
        child: MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      ),
    );
    if (time == null) return;
    ctrl.scheduledAt = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );
    ctrl.isNow.value = false;
    ctrl.multiDayDates.clear();
    ctrl.multiDayTimes.clear();
    setState(() { _scheduleMode = 1; _timeError = false; });
  }

  void _pickMultiDayTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: ctrl.multiDayTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      ),
    );
    if (time == null) return;
    ctrl.multiDayTime = time;
    setState(() => _timeError = false);
  }

  void _toggleMultiDay(DateTime date) {
    final list = ctrl.multiDayDates;
    final idx = list.indexWhere((d) => d.year == date.year && d.month == date.month && d.day == date.day);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.add(date);
    }
    setState(() => _timeError = false);
  }

  void _openMultiDayPicker() async {
    // Simple dialog with calendar-like date selection for next 30 days
    await showDialog(
      context: context,
      builder: (ctx) => _MultiDayPickerDialog(
        selected: ctrl.multiDayDates.toList(),
        onConfirm: (dates) {
          ctrl.multiDayDates.value = dates;
          ctrl.isNow.value = false;
          ctrl.scheduledAt = null;
          setState(() { _scheduleMode = 2; _timeError = false; });
        },
      ),
    );
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      // Gender is required
      if (ctrl.patientGender.value.isEmpty) {
        _genderError = true;
        valid = false;
      } else {
        _genderError = false;
      }

      // Time: must pick either "now", single schedule, or multi-day with dates+all time slots filled
      final hasTime = ctrl.isNow.value
          || ctrl.scheduledAt != null
          || (ctrl.multiDayDates.isNotEmpty && ctrl.multiDayTimes.length == ctrl.timesPerDay && ctrl.multiDayTimes.every((t) => t.isNotEmpty));
      if (!hasTime) {
        _timeError = true;
        valid = false;
      } else {
        _timeError = false;
      }

      // Building number is required
      if (ctrl.buildingCtrl.text.trim().isEmpty) {
        _buildingError = true;
        valid = false;
      } else {
        _buildingError = false;
      }

      // Apartment is required
      if (ctrl.apartmentCtrl.text.trim().isEmpty) {
        _apartmentError = true;
        valid = false;
      } else {
        _apartmentError = false;
      }
    });
    return valid;
  }

  bool _isSnapping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'patient_info_title'.tr,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 16.sp,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 17.sp),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 120.h),
            child: Column(
              children: [
                // Age (not required — always has a value)
                _card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _lbl('patient_age'.tr),
                    SizedBox(height: 11.h),
                    _buildAge(),
                  ],
                )),
                SizedBox(height: 11.h),

                // Gender — required
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _lbl('patient_gender'.tr),
                        SizedBox(width: 4.w),
                        Text('*', style: TextStyle(color: Colors.red, fontSize: 13.sp)),
                        const Spacer(),
                        if (_genderError)
                          Text(
                            'select_gender_err'.tr,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10.sp,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ]),
                      SizedBox(height: 11.h),
                      Obx(() => Row(children: [
                        _Sel(
                          'male'.tr,
                          Icons.male_rounded,
                          ctrl.patientGender.value == 'male',
                              () {
                            ctrl.patientGender.value = 'male';
                            setState(() => _genderError = false);
                          },
                          error: _genderError,
                        ),
                        SizedBox(width: 10.w),
                        _Sel(
                          'female'.tr,
                          Icons.female_rounded,
                          ctrl.patientGender.value == 'female',
                              () {
                            ctrl.patientGender.value = 'female';
                            setState(() => _genderError = false);
                          },
                          error: _genderError,
                        ),
                      ])),
                    ],
                  ),
                ),
                SizedBox(height: 11.h),

                // Time — required
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _lbl('arrival_time'.tr),
                        SizedBox(width: 4.w),
                        Text('*', style: TextStyle(color: Colors.red, fontSize: 13.sp)),
                        const Spacer(),
                        if (_timeError)
                          Text(
                            'select_time_err'.tr,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10.sp,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ]),
                      SizedBox(height: 11.h),
                      // Row 1: Hozir + Vaqt belgilash
                      Row(children: [
                        _Sel(
                          'now'.tr,
                          Icons.flash_on_rounded,
                          _scheduleMode == 0 && ctrl.isNow.value,
                          () {
                            ctrl.isNow.value = true;
                            ctrl.scheduledAt = null;
                            ctrl.multiDayDates.clear();
                            ctrl.multiDayTimes.clear();
                            setState(() { _scheduleMode = 0; _timeError = false; });
                          },
                          error: _timeError,
                        ),
                        SizedBox(width: 10.w),
                        _Sel(
                          'schedule_time'.tr,
                          Icons.schedule_rounded,
                          _scheduleMode == 1,
                          () => _pickTime(),
                          error: _timeError && _scheduleMode != 0,
                        ),
                      ]),
                      SizedBox(height: 8.h),
                      // Row 2: Ko'p kunlar — must be inside Row so Expanded has a bounded parent
                      Row(children: [
                        _Sel(
                          'multi_days'.tr,
                          Icons.date_range_rounded,
                          _scheduleMode == 2,
                          () => _openMultiDayPicker(),
                          error: _timeError && _scheduleMode == 2,
                        ),
                      ]),
                      // Single date preview
                      if (_scheduleMode == 1 && ctrl.scheduledAt != null)
                        Padding(
                          padding: EdgeInsets.only(top: 9.h),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(9.r),
                            ),
                            child: Row(children: [
                              Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 13.sp),
                              SizedBox(width: 7.w),
                              Builder(builder: (_) {
                                final dt = ctrl.scheduledAt!;
                                return Text(
                                  '${dt.day.toString().padLeft(2,'0')}.${dt.month.toString().padLeft(2,'0')}.${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}',
                                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Nunito'),
                                );
                              }),
                            ]),
                          ),
                        ),
                      // Multi-day preview
                      Obx(() {
                        final dates = ctrl.multiDayDates.toList();
                        if (_scheduleMode != 2 || dates.isEmpty) return const SizedBox.shrink();
                        final months = ['Yan','Feb','Mar','Apr','May','Iyn','Iyl','Avg','Sen','Okt','Noy','Dek'];
                        final sorted = [...dates]..sort((a, b) => a.compareTo(b));
                        return Padding(
                          padding: EdgeInsets.only(top: 9.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date chips
                              Wrap(
                                spacing: 6.w, runSpacing: 6.h,
                                children: sorted.map((d) => Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(color: AppColors.primary, width: 1),
                                  ),
                                  child: Text('${d.day} ${months[d.month - 1]}',
                                    style: TextStyle(fontSize: 11.sp, color: AppColors.primary, fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
                                )).toList(),
                              ),
                              SizedBox(height: 12.h),
                              // Times per day stepper
                              Row(
                                children: [
                                  Text('Kuniga necha marta:', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.textMedium, fontFamily: 'Nunito')),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      if (ctrl.timesPerDay > 1) {
                                        setState(() {
                                          ctrl.timesPerDay--;
                                          while (ctrl.multiDayTimes.length > ctrl.timesPerDay) {
                                            ctrl.multiDayTimes.removeLast();
                                          }
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 30.w, height: 30.h,
                                      decoration: BoxDecoration(
                                        color: ctrl.timesPerDay > 1 ? AppColors.primary : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Icon(Icons.remove, color: Colors.white, size: 16.sp),
                                    ),
                                  ),
                                  Container(
                                    width: 40.w, height: 30.h,
                                    margin: EdgeInsets.symmetric(horizontal: 6.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(color: AppColors.primary),
                                    ),
                                    child: Center(
                                      child: Text('${ctrl.timesPerDay}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'Nunito')),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (ctrl.timesPerDay < 5) {
                                        setState(() => ctrl.timesPerDay++);
                                      }
                                    },
                                    child: Container(
                                      width: 30.w, height: 30.h,
                                      decoration: BoxDecoration(
                                        color: ctrl.timesPerDay < 5 ? AppColors.primary : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Icon(Icons.add, color: Colors.white, size: 16.sp),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              // Time pickers for each slot
                              ...List.generate(ctrl.timesPerDay, (index) {
                                final hasTime = index < ctrl.multiDayTimes.length;
                                final timeStr = hasTime ? ctrl.multiDayTimes[index] : null;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 7.h),
                                  child: GestureDetector(
                                    onTap: () async {
                                      TimeOfDay initial = TimeOfDay.now();
                                      if (hasTime) {
                                        final parts = timeStr!.split(':');
                                        initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                                      }
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: initial,
                                        builder: (ctx, child) => Theme(
                                          data: Theme.of(ctx).copyWith(
                                            colorScheme: const ColorScheme.light(primary: AppColors.primary),
                                          ),
                                          child: MediaQuery(
                                            data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                                            child: child!,
                                          ),
                                        ),
                                      );
                                      if (picked == null) return;
                                      final str = '${picked.hour.toString().padLeft(2, "0")}:${picked.minute.toString().padLeft(2, "0")}';
                                      setState(() {
                                        if (index < ctrl.multiDayTimes.length) {
                                          ctrl.multiDayTimes[index] = str;
                                        } else {
                                          while (ctrl.multiDayTimes.length < index) ctrl.multiDayTimes.add('');
                                          ctrl.multiDayTimes.add(str);
                                        }
                                        _timeError = false;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                      decoration: BoxDecoration(
                                        color: hasTime ? AppColors.primaryLight : AppColors.background,
                                        borderRadius: BorderRadius.circular(9.r),
                                        border: Border.all(
                                          color: hasTime ? AppColors.primary : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 22.w, height: 22.h,
                                            decoration: BoxDecoration(
                                              color: hasTime ? AppColors.primary : Colors.grey.shade300,
                                              borderRadius: BorderRadius.circular(6.r),
                                            ),
                                            child: Center(
                                              child: Text('${index + 1}', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Nunito')),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Icon(Icons.access_time_rounded, color: hasTime ? AppColors.primary : AppColors.textLight, size: 14.sp),
                                          SizedBox(width: 6.w),
                                          Text(
                                            hasTime ? timeStr! : '${index + 1}-vaqtni tanlang',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w700,
                                              color: hasTime ? AppColors.primary : AppColors.textLight,
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(Icons.chevron_right_rounded, color: hasTime ? AppColors.primary : Colors.grey.shade400, size: 18.sp),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(height: 11.h),

                // Address — building required, others optional
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _lbl('address'.tr),
                      SizedBox(height: 11.h),
                      _fld(
                        ctrl.buildingCtrl,
                        'building_num'.tr,
                        '14B',
                        Icons.home_outlined,
                        required: true,
                        hasError: _buildingError,
                        onChanged: (_) {
                          if (_buildingError) setState(() => _buildingError = false);
                        },
                      ),
                      SizedBox(height: 9.h),
                      Row(children: [
                        Expanded(
                          child: _fld(
                            ctrl.entranceCtrl,
                            'entrance'.tr,
                            '2',
                            Icons.door_front_door_outlined,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _fld(
                            ctrl.apartmentCtrl,
                            'apartment'.tr,
                            '38',
                            Icons.meeting_room_outlined,
                            required: true,
                            hasError: _apartmentError,
                            onChanged: (_) {
                              if (_apartmentError) setState(() => _apartmentError = false);
                            },
                          ),
                        ),
                      ]),
                      SizedBox(height: 9.h),
                      _fld(
                        ctrl.commentCtrl,
                        'comment_lbl'.tr,
                        'comment_hint'.tr,
                        Icons.notes_rounded,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 11.h, 20.w, 32.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(18.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  if (_validate()) {
                    Get.toNamed(AppRoutes.payment);
                  }
                },
                child: Container(
                  height: 52.h,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(13.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'next_btn'.tr,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAge() {
    final double itemWidth = _iw;
    // Account for page padding (20.w each side) + card padding (15.w each side)
    final double viewportCenter =
        MediaQuery.of(context).size.width / 2 - 20.w - 15.w;
    final double paddingH = viewportCenter - itemWidth / 2;

    return SizedBox(
      height: 60.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Container(
              width: 54.w,
              height: 52.h,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification && !_isSnapping) {
                final idx =
                (_ageScroll.offset / itemWidth).round();
                final clampedIdx = idx.clamp(0, _max - _min);
                final targetOffset = clampedIdx * itemWidth;

                if ((_ageScroll.offset - targetOffset).abs() > 0.5) {
                  _isSnapping = true;
                  _ageScroll
                      .animateTo(
                    targetOffset,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  )
                      .then((_) => _isSnapping = false);
                } else {
                  _isSnapping = false;
                }
                ctrl.patientAge.value = _min + clampedIdx;
              }
              return false;
            },
            child: ListView.builder(
              controller: _ageScroll,
              scrollDirection: Axis.horizontal,
              itemCount: _max - _min + 1,
              itemExtent: itemWidth,
              padding: EdgeInsets.symmetric(horizontal: paddingH),
              itemBuilder: (_, i) {
                final age = _min + i;
                return Obx(() {
                  final sel = ctrl.patientAge.value == age;
                  return GestureDetector(
                    onTap: () {
                      ctrl.patientAge.value = age;
                      _isSnapping = true;
                      _ageScroll
                          .animateTo(
                        i * itemWidth,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      )
                          .then((_) => _isSnapping = false);
                    },
                    child: Center(
                      child: Text(
                        '$age',
                        style: TextStyle(
                          fontSize: sel ? 21.sp : 15.sp,
                          fontWeight: sel
                              ? FontWeight.w900
                              : FontWeight.w500,
                          color: sel
                              ? AppColors.primary
                              : AppColors.textLight,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          ),
          Positioned(left: 0, child: _fade(true)),
          Positioned(right: 0, child: _fade(false)),
        ],
      ),
    );
  }

  Widget _fade(bool left) => Container(
    width: 56.w,
    height: 60.h,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: left ? Alignment.centerLeft : Alignment.centerRight,
        end: left ? Alignment.centerRight : Alignment.centerLeft,
        colors: [AppColors.white, AppColors.white.withOpacity(0)],
      ),
    ),
  );

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(15.w),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Widget _lbl(String t) => Text(
    t,
    style: TextStyle(
      fontSize: 11.sp,
      fontWeight: FontWeight.w700,
      color: AppColors.textMedium,
      fontFamily: 'Nunito',
    ),
  );

  Widget _fld(
      TextEditingController c,
      String label,
      String hint,
      IconData icon, {
        int maxLines = 1,
        bool required = false,
        bool hasError = false,
        ValueChanged<String>? onChanged,
      }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: hasError ? Colors.red : AppColors.textMedium,
                fontFamily: 'Nunito',
              ),
            ),
            if (required) ...[
              SizedBox(width: 2.w),
              Text('*',
                  style: TextStyle(color: Colors.red, fontSize: 12.sp)),
            ],
            if (hasError) ...[
              const Spacer(),
              Text(
                'required_field'.tr,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10.sp,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ]),
          SizedBox(height: 4.h),
          TextField(
            controller: c,
            maxLines: maxLines,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 13.sp,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon:
              Icon(icon, color: hasError ? Colors.red : AppColors.primary, size: 16.sp),
              contentPadding:
              EdgeInsets.symmetric(horizontal: 11.w, vertical: 11.h),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : Colors.grey.shade200,
                  width: hasError ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      );
}

// ─── Multi-Day Picker Dialog ─────────────────────────────────────────────────
class _MultiDayPickerDialog extends StatefulWidget {
  final List<DateTime> selected;
  final ValueChanged<List<DateTime>> onConfirm;
  const _MultiDayPickerDialog({required this.selected, required this.onConfirm});
  @override State<_MultiDayPickerDialog> createState() => _MultiDayPickerDialogState();
}

class _MultiDayPickerDialogState extends State<_MultiDayPickerDialog> {
  late List<DateTime> _sel;
  late DateTime _viewMonth;
  static const _monthNames = ['Yanvar','Fevral','Mart','Aprel','May','Iyun','Iyul','Avgust','Sentyabr','Oktyabr','Noyabr','Dekabr'];
  static const _weekDays = ['Du','Se','Ch','Pa','Ju','Sh','Ya'];

  @override
  void initState() {
    super.initState();
    _sel = [...widget.selected];
    final n = DateTime.now();
    _viewMonth = DateTime(n.year, n.month, 1);
  }

  bool _isSelected(DateTime d) => _sel.any((s) => s.year==d.year && s.month==d.month && s.day==d.day);
  bool _isPast(DateTime d) => d.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  void _toggle(DateTime d) {
    setState(() {
      final idx = _sel.indexWhere((s) => s.year==d.year && s.month==d.month && s.day==d.day);
      if (idx >= 0) _sel.removeAt(idx); else _sel.add(d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final firstWeekday = _viewMonth.weekday; // 1=Mon
    final cells = (firstWeekday - 1) + daysInMonth;
    final rows = (cells / 7).ceil();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('pick_days_title'.tr, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, fontFamily: 'Nunito', color: AppColors.textDark)),
            SizedBox(height: 12.h),
            // Month nav
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1)),
                  child: Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                ),
                Text('${_monthNames[_viewMonth.month-1]} ${_viewMonth.year}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
                GestureDetector(
                  onTap: () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1)),
                  child: Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // Weekday headers
            Row(children: _weekDays.map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppColors.textLight, fontFamily: 'Nunito'))))).toList()),
            SizedBox(height: 4.h),
            // Calendar grid
            ...List.generate(rows, (row) => Row(
              children: List.generate(7, (col) {
                final cellIdx = row * 7 + col;
                final dayNum = cellIdx - (firstWeekday - 1) + 1;
                if (dayNum < 1 || dayNum > daysInMonth) return const Expanded(child: SizedBox(height: 34));
                final date = DateTime(_viewMonth.year, _viewMonth.month, dayNum);
                final past = _isPast(date);
                final sel = _isSelected(date);
                return Expanded(
                  child: GestureDetector(
                    onTap: past ? null : () => _toggle(date),
                    child: Container(
                      height: 34.h,
                      margin: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                        border: sel ? null : Border.all(color: past ? Colors.transparent : Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                            color: sel ? Colors.white : past ? AppColors.textHint : AppColors.textDark,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            )),
            SizedBox(height: 12.h),
            if (_sel.isNotEmpty)
              Text('${_sel.length} ${'days_selected'.tr}', style: TextStyle(fontSize: 11.sp, color: AppColors.primary, fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
            SizedBox(height: 10.h),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 42.h,
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10.r)),
                  child: Center(child: Text('cancel'.tr, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textLight, fontFamily: 'Nunito'))),
                ),
              )),
              SizedBox(width: 10.w),
              Expanded(flex: 2, child: GestureDetector(
                onTap: _sel.isEmpty ? null : () { Navigator.pop(context); widget.onConfirm(_sel); },
                child: Container(
                  height: 42.h,
                  decoration: BoxDecoration(
                    gradient: _sel.isEmpty ? null : AppColors.primaryGradient,
                    color: _sel.isEmpty ? AppColors.divider : null,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(child: Text('confirm'.tr, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _sel.isEmpty ? AppColors.textLight : Colors.white, fontFamily: 'Nunito'))),
                ),
              )),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Sel extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool sel;
  final VoidCallback onTap;
  final bool error;

  const _Sel(this.label, this.icon, this.sel, this.onTap, {this.error = false});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: sel
              ? AppColors.primaryLight
              : error
              ? Colors.red.withOpacity(0.05)
              : AppColors.background,
          borderRadius: BorderRadius.circular(11.r),
          border: Border.all(
            color: sel
                ? AppColors.primary
                : error
                ? Colors.red
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: sel
                  ? AppColors.primary
                  : error
                  ? Colors.red
                  : AppColors.textLight,
              size: 16.sp,
            ),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: sel
                    ? AppColors.primary
                    : error
                    ? Colors.red
                    : AppColors.textLight,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}