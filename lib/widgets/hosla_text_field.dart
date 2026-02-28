import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';

/// Hosla Design System text field.
///
/// Label row on top (icon + label + optional trailing widget),
/// rounded container below with the actual input.
///
/// Supports single-line, multi-line, obscured, formatter, and
/// validator variants.
class HoslaTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final String? hintText;
  final int maxLines;
  final int? maxLength;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final Widget? suffix;
  final Widget? trailing; // trailing widget in the label row
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final TextStyle? textStyle;
  final bool showCounter;

  const HoslaTextField({
    super.key,
    required this.label,
    required this.icon,
    this.controller,
    this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.trailing,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.textStyle,
    this.showCounter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label row ──
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: ThemeColors.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextThemes.getBodyMediumStyle(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.getTextColor(context),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),

        // ── Input container ──
        Container(
          decoration: BoxDecoration(
            color: ThemeColors.getCardColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ThemeColors.getBorderColor(
                context,
              ).withValues(alpha: 0.25),
            ),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textAlign: textAlign,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            enabled: enabled,
            readOnly: readOnly,
            focusNode: focusNode,
            style:
                textStyle ??
                TextThemes.getBodyMediumStyle(
                  context,
                ).copyWith(fontSize: 15, height: maxLines > 1 ? 1.5 : null),
            cursorColor: ThemeColors.primaryColor,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextThemes.getBodyMediumStyle(context).copyWith(
                color: ThemeColors.getSecondaryTextColor(
                  context,
                ).withValues(alpha: 0.4),
                fontSize: 14,
              ),
              border: InputBorder.none,
              counterText: showCounter ? null : '',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 14,
              ),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}
