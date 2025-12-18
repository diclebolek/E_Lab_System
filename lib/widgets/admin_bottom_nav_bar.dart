import 'package:flutter/material.dart';

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // Daha ince navigation bar
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0058A3), Color(0xFF00A8E8)],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildNavItem(context, icon: Icons.add_circle, index: 0, isSelected: currentIndex == 0),
          _buildNavItem(context, icon: Icons.list, index: 1, isSelected: currentIndex == 1),
          _buildNavItem(context, icon: Icons.dashboard, index: 2, isSelected: currentIndex == 2),
          _buildNavItem(context, icon: Icons.add, index: 3, isSelected: currentIndex == 3),
          _buildNavItem(context, icon: Icons.assignment, index: 4, isSelected: currentIndex == 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required int index, required bool isSelected}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(12),
          splashColor: isSelected
              ? const Color(0xFF00A8E8).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.2),
          highlightColor: isSelected
              ? const Color(0xFF00A8E8).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? Colors.white : Colors.transparent,
              boxShadow: isSelected
                  ? [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
                      BoxShadow(
                        color: const Color(0xFF00A8E8).withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                    ]
                  : null,
              border: isSelected ? Border.all(color: const Color(0xFF00A8E8), width: 2.5) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  transform: Matrix4.identity()
                    ..scaleByDouble(isSelected ? 1.2 : 1.0, isSelected ? 1.2 : 1.0, isSelected ? 1.2 : 1.0, 1.0),
                  child: Icon(
                    icon,
                    size: isSelected ? 28 : 24,
                    color: isSelected ? const Color(0xFF0058A3) : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 10 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00A8E8) : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
