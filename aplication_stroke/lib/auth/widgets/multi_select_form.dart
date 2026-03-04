import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../styles/colors/app_color.dart';
import '../../utils/util.dart';

/// Widget Multi-Select Form
///
/// Memungkinkan pengguna menambah dan memilih banyak item sekaligus.
/// Digunakan untuk input riwayat penyakit dan alergi obat.
///
/// Fitur:
/// - Tampilan chip yang bisa dipilih/dihapus
/// - Dialog tambah item baru yang modern
/// - Animasi masuk chip baru
/// - Counter jumlah item terpilih
class MultiSelectForm extends StatefulWidget {
  final String title;
  final String hintText;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;

  const MultiSelectForm({
    super.key,
    required this.title,
    required this.hintText,
    required this.selectedItems,
    required this.onChanged,
  });

  @override
  State<MultiSelectForm> createState() => _MultiSelectFormState();
}

class _MultiSelectFormState extends State<MultiSelectForm>
    with SingleTickerProviderStateMixin {
  /// Daftar semua item yang sudah ditambahkan (belum tentu terpilih)
  final List<String> _items = [];

  /// Controller animasi untuk chip baru yang masuk
  late AnimationController _addAnimController;

  @override
  void initState() {
    super.initState();
    _addAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _addAnimController.dispose();
    super.dispose();
  }

  /// Toggle item: pilih jika belum ada, hapus jika sudah ada
  void _toggleItem(String item) {
    HapticFeedback.selectionClick();
    final itemLower = item.trim().toLowerCase();
    final updated = List<String>.from(widget.selectedItems);
    if (updated.contains(itemLower)) {
      updated.remove(itemLower);
    } else {
      updated.add(itemLower);
    }
    widget.onChanged(updated);
    setState(() {});
  }

  /// Tambah item baru ke daftar dan langsung pilih
  void _addCustomItem(String item) {
    final itemLower = item.trim().toLowerCase();
    if (_items.contains(itemLower)) return; // hindari duplikat

    setState(() => _items.add(itemLower));

    // Jalankan animasi masuk
    _addAnimController
      ..reset()
      ..forward();

    final updated = List<String>.from(widget.selectedItems)..add(itemLower);
    widget.onChanged(updated);
  }

  /// Hapus item dari daftar dan dari selected
  void _removeItem(String item) {
    HapticFeedback.lightImpact();
    setState(() => _items.remove(item));
    final updated = List<String>.from(widget.selectedItems)..remove(item);
    widget.onChanged(updated);
  }

  /// Mendapatkan warna chip berdasarkan index (variasi warna)
  Color _getChipColor(int index) {
    final colors = [
      const Color(0xFF0A7AC1),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFF0891B2),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedItems;
    final hasItems = _items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header: Label + Counter ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForTitle(widget.title),
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),

            // Counter item terpilih
            if (selected.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${selected.length} dipilih',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 4),

        // Subjudul
        Text(
          'Opsional — tambahkan jika ada',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 10),

        // --- Area Chip ---
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: EdgeInsets.all(hasItems ? 12 : 0),
          decoration: hasItems
              ? BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                )
              : null,
          child: hasItems
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = selected.contains(item);
                    final chipColor = _getChipColor(index);

                    // Animasi hanya untuk chip terakhir yang baru ditambahkan
                    final isNewest = index == _items.length - 1;

                    return isNewest
                        ? _AnimatedChip(
                            label: capitalizeWords(item),
                            isSelected: isSelected,
                            color: chipColor,
                            animation: _addAnimController,
                            onToggle: () => _toggleItem(item),
                            onDelete: () => _removeItem(item),
                          )
                        : _SelectableChip(
                            label: capitalizeWords(item),
                            isSelected: isSelected,
                            color: chipColor,
                            onToggle: () => _toggleItem(item),
                            onDelete: () => _removeItem(item),
                          );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 10),

        // --- Tombol Tambah ---
        _AddButton(title: widget.title, onTap: () => _showAddDialog()),
      ],
    );
  }

  /// Mendapatkan ikon yang sesuai berdasarkan judul
  IconData _getIconForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('penyakit') || lower.contains('riwayat')) {
      return Icons.medical_information_outlined;
    }
    if (lower.contains('alergi') || lower.contains('obat')) {
      return Icons.medication_outlined;
    }
    return Icons.list_alt_rounded;
  }

  /// Dialog untuk menambahkan item baru
  void _showAddDialog() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dialog
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconForTitle(widget.title),
                        color: AppColor.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tambah ${widget.title}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            'Data akan tersimpan di profil Anda',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Input field
                Form(
                  key: formKey,
                  child: TextFormField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Tidak boleh kosong'
                        : null,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.edit_outlined,
                        color: AppColor.primary,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColor.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onFieldSubmitted: (_) {
                      if (formKey.currentState!.validate()) {
                        _addCustomItem(controller.text);
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Tombol aksi
                Row(
                  children: [
                    // Tombol Batal
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Tombol Tambah
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            _addCustomItem(controller.text);
                            Navigator.pop(ctx);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Tambah',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────

/// Chip yang bisa dipilih dan dihapus
class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onToggle,
    required this.onDelete,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon centang saat terpilih
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 13),
              const SizedBox(width: 5),
            ],

            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),

            // Tombol hapus
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 10,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip dengan animasi masuk (untuk chip yang baru ditambahkan)
class _AnimatedChip extends StatelessWidget {
  const _AnimatedChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.animation,
    required this.onToggle,
    required this.onDelete,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final Animation<double> animation;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        // Animasi scale + fade untuk chip baru
        final scale = Tween<double>(begin: 0.5, end: 1.0)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            )
            .value;
        final opacity = Tween<double>(begin: 0.0, end: 1.0)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.5),
              ),
            )
            .value;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: _SelectableChip(
        label: label,
        isSelected: isSelected,
        color: color,
        onToggle: onToggle,
        onDelete: onDelete,
      ),
    );
  }
}

/// Tombol "Tambah ..." di bawah daftar chip
class _AddButton extends StatefulWidget {
  const _AddButton({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onTapUp: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - (_hoverController.value * 0.03),
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColor.primary.withOpacity(0.08)
                : AppColor.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? AppColor.primary.withOpacity(0.4)
                  : AppColor.primary.withOpacity(0.2),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tambah ${widget.title.toLowerCase()}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColor.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
