import 'package:flutter/material.dart';

class ControlButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isOn;
  final VoidCallback onPressed;
  final Color? activeColor;

  const ControlButton(this.title, this.icon, this.isOn, this.onPressed, {this.activeColor, super.key});

  @override
  Widget build(BuildContext context) {
    final Color active = activeColor ?? const Color(0xFF238636);
    final List<Color> activeGradient = activeColor != null
      ? [active.withAlpha((0.8 * 255).round()), active]
      : [const Color(0xFF3FB950), const Color(0xFF238636)];

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOn ? activeGradient : [const Color(0xFF21262D), const Color(0xFF161B22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isOn ? active : const Color(0xFF30363D)),
          boxShadow: isOn
              ? [
                  BoxShadow(
                    color: active.withAlpha((0.5 * 255).round()),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isOn ? Colors.white : const Color(0xFF8B949E)),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: isOn ? Colors.white : const Color(0xFF8B949E), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
