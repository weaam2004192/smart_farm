import 'package:flutter/material.dart';
import '../widgets/control_button.dart';
import '../widgets/section_title.dart';

class ControlsScreen extends StatelessWidget {
  final bool lampOn;
  final bool fanOn;
  final Function(String, bool) onToggle;

  const ControlsScreen({
    super.key,
    required this.lampOn,
    required this.fanOn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const SectionTitle('Main Controls'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: ControlButton('Heating Lamp', Icons.lightbulb_outline_rounded, lampOn, () => onToggle('controls/lamp', lampOn))),
            const SizedBox(width: 16),
            Expanded(child: ControlButton('Ventilation Fan', Icons.air_rounded, fanOn, () => onToggle('controls/fan', fanOn))),
          ],
        ),
      ],
    );
  }
}
