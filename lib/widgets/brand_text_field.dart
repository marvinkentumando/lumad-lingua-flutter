import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class BrandTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final int maxLines;

  final bool showValidation;
  final bool isValid;
  final String? errorText;

  final ValueChanged<String>? onChanged;

  const BrandTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.showValidation = false,
    this.isValid = false,
    this.errorText,
    this.onChanged,
  });

  @override
  State<BrandTextField> createState() => _BrandTextFieldState();
}

class _BrandTextFieldState extends State<BrandTextField> {
  bool _obscureText = true;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_isFocused) HapticFeedback.selectionClick();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    HapticFeedback.lightImpact();
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isFocused
                ? AppColors.creamBg
                : AppColors.creamBg.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError
                  ? AppColors.semanticRed
                  : (widget.isValid
                      ? AppColors.semanticGreen.withValues(alpha: 0.5)
                      : (_isFocused
                            ? AppColors.gold500
                            : Colors.black.withValues(alpha: 0.1))),
              width: _isFocused || widget.isValid || hasError ? 2 : 1.5,
            ),
            boxShadow: hasError
                ? [
                    BoxShadow(
                      color: AppColors.semanticRed.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : (widget.isValid
                      ? [
                          BoxShadow(
                            color: AppColors.semanticGreen.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : (_isFocused
                            ? [
                                BoxShadow(
                                  color: AppColors.gold500.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [])),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            style: AppTypography.body.copyWith(
              color: AppColors.forest900,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: widget.labelText,
              labelStyle: AppTypography.body.copyWith(
                color: hasError
                    ? AppColors.semanticRed
                    : (_isFocused
                        ? AppColors.forest700
                        : AppColors.forest900.withValues(alpha: 0.6)),
                fontWeight: FontWeight.bold,
              ),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: hasError
                    ? AppColors.semanticRed
                    : (_isFocused
                        ? AppColors.gold600
                        : AppColors.forest500.withValues(alpha: 0.6)),
              ),
              suffixIcon: (widget.showValidation && widget.isValid) || widget.isPassword || hasError
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasError)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.error_outline_rounded, color: AppColors.semanticRed, size: 20),
                          ),
                        if (widget.showValidation && widget.isValid && !hasError)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.check_circle, color: AppColors.semanticGreen, size: 20),
                          ),
                        if (widget.isPassword)
                          IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: hasError
                                  ? AppColors.semanticRed
                                  : (_isFocused
                                      ? AppColors.gold600
                                      : AppColors.forest500.withValues(alpha: 0.6)),
                              size: 20,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                        const SizedBox(width: 8),
                      ],
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onChanged: widget.onChanged,
            validator: widget.validator,
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 16),
            child: Text(
              widget.errorText!,
              style: AppTypography.label.copyWith(
                color: AppColors.semanticRed,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn().slideY(begin: -0.2),
      ],
    );
  }
}



