import 'package:flutter/material.dart';

class AlarmBanner extends StatelessWidget {
  final bool isAlarmActive;
  final Color alarmColor;
  final String alarmMessage;

  const AlarmBanner({
    super.key,
    required this.isAlarmActive,
    required this.alarmColor,
    required this.alarmMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isAlarmActive ? 60 : 0,
      color: alarmColor,
      child: isAlarmActive
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alarmMessage,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
