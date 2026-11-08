import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Field title with a red asterisk when the value is mandatory.
class RequiredLabel extends StatelessWidget {
  const RequiredLabel({super.key, required this.text, this.required = true});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: required ? '$text, required' : text,
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            text: text,
            style: AppTextStyles.label,
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
