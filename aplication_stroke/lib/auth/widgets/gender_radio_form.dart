import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../styles/colors/app_color.dart';

/// Widget Pilihan Jenis Kelamin
///
/// Menampilkan dua kartu interaktif untuk memilih jenis kelamin (Pria / Wanita).
/// Dilengkapi animasi transisi warna, ikon, dan efek tekan yang halus.
///
/// Catatan perbaikan bug:
/// - Nilai "famale" (typo) sudah diperbaiki menjadi "female"
class GenderRadioForm extends StatefulWidget {
  final String selectedGender;
  final ValueChanged<String> onChanged;

  const GenderRadioForm({
    super.key,
    required this.selectedGender,
    required this.onChanged,
  });

  @override
  State<GenderRadioForm> createState() => _GenderRadioFormState();
}

class _GenderRadioFormState extends State<GenderRadioForm>
    with SingleTickerProviderStateMixin {
  late String _currentGender;

  @override
  void initState() {
    super.initState();
    _currentGender = widget.selectedGender;
  }

  /// Menangani perubahan pilihan jenis kelamin
  void _onGenderChanged(String value) {
    if (_currentGender == value) return;
    HapticFeedback.selectionClick();
    setState(() => _currentGender = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Label ---
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.wc_rounded, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                "Jenis Kelamin",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),

        // --- Dua Kartu Pilihan ---
        Row(
          children: [
            // Kartu Pria
            Expanded(
              child: _GenderCard(
                value: "male",
                label: "Pria",
                icon: Icons.male_rounded,
                selectedValue: _currentGender,
                selectedColor: const Color(0xFF0A7AC1),
                selectedBgColor: const Color(0xFFE3F2FD),
                unselectedColor: Colors.grey.shade400,
                onTap: () => _onGenderChanged("male"),
              ),
            ),

            const SizedBox(width: 12),

            // Kartu Wanita (diperbaiki: "famale" → "female")
            Expanded(
              child: _GenderCard(
                value: "female",
                label: "Wanita",
                icon: Icons.female_rounded,
                selectedValue: _currentGender,
                selectedColor: const Color(0xFFD63384),
                selectedBgColor: const Color(0xFFFCE4EC),
                unselectedColor: Colors.grey.shade400,
                onTap: () => _onGenderChanged("female"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Kartu Pilihan Gender
///
/// Kartu individual yang menampilkan ikon dan label gender.
/// Berubah tampilan saat dipilih: warna border, background, ikon, dan centang.
class _GenderCard extends StatefulWidget {
  const _GenderCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.selectedValue,
    required this.selectedColor,
    required this.selectedBgColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final String selectedValue;
  final Color selectedColor;
  final Color selectedBgColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  bool get isSelected => selectedValue == value;

  @override
  State<_GenderCard> createState() => _GenderCardState();
}

class _GenderCardState extends State<_GenderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            // Background berubah saat terpilih
            color: isSelected ? widget.selectedBgColor : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? widget.selectedColor : Colors.grey.shade200,
              width: isSelected ? 1.8 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: widget.selectedColor.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Baris atas: ikon + centang
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ikon gender dalam lingkaran
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.selectedColor.withOpacity(0.15)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 22,
                      color: isSelected
                          ? widget.selectedColor
                          : widget.unselectedColor,
                    ),
                  ),

                  // Ikon centang saat terpilih
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: isSelected
                        ? Container(
                            key: const ValueKey('check'),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: widget.selectedColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          )
                        : Container(
                            key: const ValueKey('empty'),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Label gender
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? widget.selectedColor
                        : Colors.grey.shade600,
                    letterSpacing: isSelected ? -0.2 : 0,
                  ),
                  child: Text(widget.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
