import 'package:flutter/material.dart';
import '../../styles/colors/app_color.dart';

/// Widget Input Password
///
/// Input field password dengan:
/// - Toggle show/hide dengan animasi ikon berganti
/// - Efek fokus: border biru + shadow + background biru muda
/// - Label berubah warna saat fokus
/// - Opsional: indikator kekuatan password (showStrength: true)
class PasswordFormFieldWithLabel extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String? value)? validator;

  /// Label di atas field. Default: "Password"
  final String label;

  /// Hint text di dalam field
  final String? hintText;

  /// Aktifkan indikator kekuatan password (cocok untuk halaman register)
  final bool showStrength;

  const PasswordFormFieldWithLabel({
    super.key,
    required this.controller,
    required this.validator,
    this.label = 'Password',
    this.hintText,
    this.showStrength = false,
  });

  @override
  State<PasswordFormFieldWithLabel> createState() =>
      _PasswordFormFieldWithLabelState();
}

class _PasswordFormFieldWithLabelState extends State<PasswordFormFieldWithLabel>
    with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  bool _isFocused = false;
  int _strength = 0;

  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
    if (widget.showStrength) {
      widget.controller.addListener(_updateStrength);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (widget.showStrength) {
      widget.controller.removeListener(_updateStrength);
    }
    super.dispose();
  }

  /// Hitung skor kekuatan password (0–4)
  void _updateStrength() {
    final p = widget.controller.text;
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) s++;
    if (mounted) setState(() => _strength = s);
  }

  Color get _strengthColor {
    switch (_strength) {
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.green.shade500;
      default:
        return Colors.grey.shade200;
    }
  }

  String get _strengthLabel {
    switch (_strength) {
      case 1:
        return 'Lemah';
      case 2:
        return 'Cukup';
      case 3:
        return 'Kuat';
      case 4:
        return 'Sangat Kuat ✓';
      default:
        return '';
    }
  }

  String get _strengthTip {
    if (_strength == 0) return 'Min. 8 karakter';
    if (_strength == 1) return 'Tambah huruf besar';
    if (_strength == 2) return 'Tambah angka';
    if (_strength == 3) return 'Tambah simbol (!@#)';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: _isFocused ? AppColor.primary : Colors.grey.shade500,
              ),
              const SizedBox(width: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isFocused
                      ? AppColor.primary
                      : const Color(0xFF374151),
                ),
                child: Text(widget.label),
              ),
            ],
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
                      spreadRadius: -1,
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
            obscureText: _obscureText,
            focusNode: _focusNode,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
            decoration: InputDecoration(
              hintText:
                  widget.hintText ?? 'Masukkan ${widget.label.toLowerCase()}',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
                fontSize: 14,
                letterSpacing: 0,
              ),

              // Ikon gembok kiri
              prefixIcon: Icon(
                Icons.lock_rounded,
                size: 20,
                color: _isFocused ? AppColor.primary : Colors.grey.shade400,
              ),

              // Toggle show/hide kanan
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      key: ValueKey(_obscureText),
                      size: 20,
                      color: _isFocused
                          ? AppColor.primary
                          : Colors.grey.shade500,
                    ),
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                  splashRadius: 20,
                  tooltip: _obscureText
                      ? 'Tampilkan password'
                      : 'Sembunyikan password',
                ),
              ),

              filled: true,
              fillColor: _isFocused
                  ? AppColor.primary.withOpacity(0.04)
                  : Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
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
                borderSide: BorderSide(color: AppColor.primary, width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColor.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColor.error, width: 1.8),
              ),
              errorStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColor.error,
              ),
            ),
          ),
        ),

        // ── Indikator Kekuatan Password ────────────────
        if (widget.showStrength && widget.controller.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(right: i < 3 ? 5 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < _strength
                        ? _strengthColor
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _strengthLabel,
                  key: ValueKey(_strengthLabel),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _strengthColor,
                  ),
                ),
              ),
              if (_strength < 4)
                Text(
                  _strengthTip,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
