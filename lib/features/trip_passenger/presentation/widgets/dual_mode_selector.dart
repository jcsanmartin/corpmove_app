import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';

class DualModeSelector extends StatefulWidget {
  final bool isCorporateMode;
  final ValueChanged<bool> onModeChanged;

  const DualModeSelector({
    super.key,
    required this.isCorporateMode,
    required this.onModeChanged,
  });

  @override
  State<DualModeSelector> createState() => _DualModeSelectorState();
}

class _DualModeSelectorState extends State<DualModeSelector> {
  double _dragPercent = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _dragPercent = widget.isCorporateMode ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(covariant DualModeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && oldWidget.isCorporateMode != widget.isCorporateMode) {
      _dragPercent = widget.isCorporateMode ? 1.0 : 0.0;
    }
  }

  void _updateModeBasedOnDrag() {
    bool newMode = _dragPercent > 0.5;
    if (newMode != widget.isCorporateMode) {
      widget.onModeChanged(newMode);
    }
    setState(() {
      _dragPercent = newMode ? 1.0 : 0.0;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF141414);
    const Color activeColor = AppColors.accentLime;
    const Color inactiveTextColor = Color(0xFF7A7A7A);
    const Color activeTextColor = Color(0xFF141414);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width =
            constraints.maxWidth > 260 ? 260 : constraints.maxWidth;
        const double padding = 4.0;
        final double pillWidth = (width - padding * 2) / 2;

        return Center(
          child: GestureDetector(
            onTapUp: (details) {
              bool isRightSide = details.localPosition.dx > width / 2;
              widget.onModeChanged(isRightSide);
              setState(() => _dragPercent = isRightSide ? 1.0 : 0.0);
            },
            onPanStart: (_) {
              setState(() => _isDragging = true);
            },
            onPanUpdate: (details) {
              setState(() {
                double dx =
                    details.localPosition.dx - padding - (pillWidth / 2);
                _dragPercent = (dx / pillWidth).clamp(0.0, 1.0);
              });
            },
            onPanEnd: (_) {
              _updateModeBasedOnDrag();
            },
            child: Container(
              width: width,
              height: 40,
              padding: const EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Stack(
                children: [
                  // Pastilla animada
                  AnimatedPositioned(
                    duration: _isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    left: _dragPercent * pillWidth,
                    top: 0,
                    bottom: 0,
                    width: pillWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  // Textos superpuestos
                  Row(
                    children: [
                      // Personal
                      Expanded(
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: GoogleFonts.inter(
                              fontWeight: _dragPercent < 0.5
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: _dragPercent < 0.5
                                  ? activeTextColor
                                  : inactiveTextColor,
                              fontSize: 14,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 14,
                                  color: _dragPercent < 0.5
                                      ? activeTextColor
                                      : inactiveTextColor,
                                ),
                                const SizedBox(width: 4),
                                const Text('Personal'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Corporativo
                      Expanded(
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: GoogleFonts.inter(
                              fontWeight: _dragPercent >= 0.5
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _dragPercent >= 0.5
                                  ? activeTextColor
                                  : inactiveTextColor,
                              fontSize: 14,
                            ),
                                    child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  size: 14,
                                  color: _dragPercent >= 0.5
                                      ? activeTextColor
                                      : inactiveTextColor,
                                ),
                                const SizedBox(width: 4),
                                const Flexible(
                                  child: Text(
                                    'Corporativo',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_dragPercent >= 0.5) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: activeTextColor.withValues(
                                          alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ON',
                                      style: GoogleFonts.inter(
                                        color: activeTextColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
