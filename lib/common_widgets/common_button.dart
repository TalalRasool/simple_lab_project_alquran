import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Solid primary button, or the outlined variant used for Create Account.
class CommonButton extends StatelessWidget {
  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isOutlined = false,
    this.width,
    this.height,
    this.icon,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final double? width;
  final double? height;
  final Widget? icon;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14.r);
    final requested =
        foregroundColor ?? (isOutlined ? AppColors.primary : AppColors.white);
    final foreground = isOutlined && requested == AppColors.primary
        ? AppColors.icon
        : requested;
    final label = Text(
      text,
      style: AppTextStyles.button.copyWith(color: foreground),
    );
    final child = icon == null
        ? label
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon!,
              SizedBox(width: 8.w),
              Flexible(child: label),
            ],
          );

    final button = isOutlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: foreground,
              backgroundColor: backgroundColor ?? AppColors.card,
              side: BorderSide(
                color: borderColor ?? AppColors.icon,
                width: 1.4.w,
              ),
              shape: RoundedRectangleBorder(borderRadius: radius),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
            child: child,
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? AppColors.primaryButton,
              foregroundColor: foreground,
              disabledBackgroundColor: AppColors.lightGreen.withValues(
                alpha: 0.4,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: radius),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
            child: child,
          );

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 52.h,
      child: button,
    );
  }
}
