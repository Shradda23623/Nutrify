import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TonePicker extends StatefulWidget {
  final String selectedTone;
  final Function(String) onSelected;

  const TonePicker({
    super.key,
    required this.selectedTone,
    required this.onSelected,
  });

  @override
  State<TonePicker> createState() => _TonePickerState();
}

class _TonePickerState extends State<TonePicker> {
  final List<Map<String, String>> _tones = [
    {'id': 'default', 'label': '🔔 Default', 'desc': 'Standard notification tone'},
    {'id': 'chime', 'label': '🎵 Chime', 'desc': 'Soft melodic chime'},
    {'id': 'water', 'label': '💧 Water Drop', 'desc': 'Gentle water drop sound'},
    {'id': 'bell', 'label': '🔔 Bell', 'desc': 'Classic bell ring'},
    {'id': 'beep', 'label': '📳 Beep', 'desc': 'Simple alert beep'},
    {'id': 'silent', 'label': '🔕 Silent', 'desc': 'Pop-up only, no sound'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Tone',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ..._tones.map((tone) {
          final isSelected = widget.selectedTone == tone['id'];
          return GestureDetector(
            onTap: () => widget.onSelected(tone['id']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.green
                      : Colors.black12,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(tone['label']!,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.black
                              : Colors.black54)),
                  const Spacer(),
                  Text(tone['desc']!,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black38)),
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.check_circle_rounded,
                          color: Color(0xFF6BCB77), size: 18),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
