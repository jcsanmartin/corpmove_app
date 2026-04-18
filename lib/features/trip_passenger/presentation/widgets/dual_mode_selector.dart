import 'package:flutter/material.dart';

class DualModeSelector extends StatelessWidget {
  final bool isCorporateMode;
  final ValueChanged<bool> onModeChanged;

  const DualModeSelector({
    super.key,
    required this.isCorporateMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          _buildModeOption('🧑 Personal', false),
          _buildModeOption('🏢 Corporativo', true),
        ],
      ),
    );
  }

  Widget _buildModeOption(String text, bool isCorporate) {
    final isSelected = isCorporateMode == isCorporate;
    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(isCorporate),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(34),
            boxShadow: isSelected
                ? [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),
              if (isSelected && isCorporate) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Activo',
                    style: TextStyle(
                      color: Color(0xFFFF6D00),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}