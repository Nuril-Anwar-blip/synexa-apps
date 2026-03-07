import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../styles/colors/app_color.dart';

/// Tipe input yang menentukan keyboard dan formatter default
enum InputFieldType {
  /// Teks biasa (huruf, angka, spasi)
  text,

  /// Angka saja
  number,

  /// Alamat email
  email,

  /// Nomor telepon
  phone,
}

/// Widget Input Teks Universal
///
/// Fitur:
/// - Animasi fokus (border biru + shadow + background biru muda)
/// - Label berubah warna saat fokus — konsisten dengan PasswordFormFieldWithLabel
/// - Keyboard otomatis sesuai tipe
/// - Formatter otomatis sesuai tipe
/// - Compact mode
/// - Multiline support
/// - Validator support
class TextFormFieldWithLabel extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String? value)? validator;
  final InputFieldType fieldType;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final bool compact;
  final int maxLines;

  const TextFormFieldWithLabel({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
    this.fieldType = InputFieldType.text,
    this.hintText,
    this.inputFormatters,
    this.compact = false,
    this.maxLines = 1,
  });

  @override
  State<TextFormFieldWithLabel> createState() => _TextFormFieldWithLabelState();
}

class _TextFormFieldWithLabelState extends State<TextFormFieldWithLabel> {
  bool _isFocused = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Keyboard Type ───────────────────────────────────────
  TextInputType get _keyboardType {
    switch (widget.fieldType) {
      case InputFieldType.number:
        return TextInputType.number;
      case InputFieldType.email:
        return TextInputType.emailAddress;
      case InputFieldType.phone:
        return TextInputType.phone;
      default:
        return widget.maxLines > 1
            ? TextInputType.multiline
            : TextInputType.text;
    }
  }

  // ─── Formatter Default ───────────────────────────────────
  List<TextInputFormatter> get _defaultFormatters {
    switch (widget.fieldType) {
      case InputFieldType.number:
        return [FilteringTextInputFormatter.digitsOnly];
      case InputFieldType.email:
        return [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._\-]'))];
      case InputFieldType.phone:
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
          LengthLimitingTextInputFormatter(15),
        ];
      default:
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@\-_.\s]')),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = widget.compact;
    final List<TextInputFormatter> formatters = <TextInputFormatter>[
      ..._defaultFormatters,
      ...?widget.inputFormatters,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: isCompact ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: _isFocused ? AppColor.primary : const Color(0xFF374151),
            ),
            child: Text(widget.label),
          ),
        ),

        // ── Input Field ────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColor.primary.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            focusNode: _focusNode,
            keyboardType: _keyboardType,
            inputFormatters: formatters,
            maxLines: widget.maxLines,
            style: TextStyle(
              fontSize: isCompact ? 13 : 15,
              color: const Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            decoration: InputDecoration(
              isDense: isCompact,
              hintText:
                  widget.hintText ?? 'Masukkan ${widget.label.toLowerCase()}',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
                fontSize: isCompact ? 13 : 14,
                letterSpacing: 0,
              ),
              filled: true,
              fillColor: _isFocused
                  ? AppColor.primary.withOpacity(0.04)
                  : Colors.grey.shade50,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16,
                vertical: isCompact ? 11 : 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColor.primary,
                  width: 1.8,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColor.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColor.error, width: 1.8),
              ),
              errorStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColor.error,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
