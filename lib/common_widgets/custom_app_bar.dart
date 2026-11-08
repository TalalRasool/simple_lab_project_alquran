import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Light app bar with an optional back button and a centered title.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String title;
  final bool? showBackButton;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  bool _shouldShowBack(BuildContext context) {
    if (showBackButton != null) return showBackButton!;
    return Navigator.of(context).canPop();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = foregroundColor ?? AppColors.textPrimary;
    final showBack = _shouldShowBack(context);

    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              onPressed: Get.back,
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: foreground,
                size: 18.sp,
              ),
            )
          : null,
      title: Text(
        title,
        style: AppTextStyles.title.copyWith(color: foreground),
      ),
      actions: actions,
    );
  }
}
