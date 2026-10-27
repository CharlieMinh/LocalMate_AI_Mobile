import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Text field with a single visible label above the input (no duplicated
/// floating label), optional helper/error and a password visibility toggle.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.prefixIcon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.fieldKey,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final IconData? prefixIcon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final int maxLines;
  final int? maxLength;

  /// Key placed on the inner TextFormField (tests target the input itself).
  final Key? fieldKey;
  final bool autocorrect;
  final bool enableSuggestions;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(widget.label, style: text.labelMedium),
        ),
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _hidden,
          autocorrect: widget.autocorrect,
          enableSuggestions: widget.enableSuggestions,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          style: text.bodyLarge,
          scrollPadding: const EdgeInsets.all(AppSpacing.xxxl * 2),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            helperMaxLines: 3,
            errorText: widget.errorText,
            errorMaxLines: 3,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: AppSizes.icon),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: AppSizes.icon,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
