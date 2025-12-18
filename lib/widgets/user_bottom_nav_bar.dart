import 'package:flutter/material.dart';

class UserBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const UserBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // Admin ile aynı yükseklik
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
          _buildNavItem(context, icon: Icons.description, index: 0, isSelected: currentIndex == 0),
          _buildNavItem(context, icon: Icons.person, index: 1, isSelected: currentIndex == 1),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required int index, required bool isSelected}) {
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? Colors.white : Colors.transparent,
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
            border: isSelected ? Border.all(color: const Color(0xFF00A8E8), width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()
                  ..scaleByDouble(isSelected ? 1.15 : 1.0, isSelected ? 1.15 : 1.0, isSelected ? 1.15 : 1.0, 1.0),
                child: Icon(
                  icon,
                  size: isSelected ? 28 : 24,
                  color: isSelected ? const Color(0xFF0058A3) : Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 8 : 0,
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
    );
  }
}
