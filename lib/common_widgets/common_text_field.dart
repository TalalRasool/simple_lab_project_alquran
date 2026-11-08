import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'required_label.dart';

/// Rounded text field with an optional required label.
class CommonTextField extends StatelessWidget {
  const CommonTextField({
    super.key,
    this.controller,
    this.label,
    this.isRequired = false,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.maxLength,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController? controller;
  final String? label;
  final bool isRequired;
  final String? hintText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14.r);

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final field = TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: AppTextStyles.body,
      cursorColor: AppColors.primaryButton,
      decoration: InputDecoration(
        hintText: hintText,
        helperText: helperText,
        helperMaxLines: 2,
        helperStyle: AppTextStyles.caption,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.white,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixIconColor: AppColors.primaryButton,
        suffixIconColor: AppColors.textSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.primaryButton, width: 1.5),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error, width: 1.5),
        errorMaxLines: 2,
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        counterStyle: AppTextStyles.caption,
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequiredLabel(text: label!, required: isRequired),
        SizedBox(height: 8.h),
        field,
      ],
    );
  }
}
