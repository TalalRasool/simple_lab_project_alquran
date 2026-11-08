import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';

/// Soft card used for dashboard tiles and list rows.
class CommonContainer extends StatelessWidget {
  const CommonContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderRadius,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double? borderRadius;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius ?? 16.r);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: color ?? AppColors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding ?? EdgeInsets.all(16.w),
            child: child,
          ),
        ),
      ),
    );
  }
}
