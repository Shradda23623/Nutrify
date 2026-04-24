import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../models/bmi_model.dart';
import '../widgets/bmi_gauge.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  BmiModel? _result;

  void _calculate() {
    final h = double.tryParse(_heightCtrl.text);
    final w = double.tryParse(_weightCtrl.text);
    if (h != null && w != null && h > 0 && w > 0) {
      setState(() {
        _result = BmiModel(heightCm: h, weightKg: w);
      });
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid height and weight.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color get _categoryColor {
    if (_result == null) return AppColors.primary;
    switch (_result!.category) {
      case 'Underweight':
        return const Color(0xFF4D96FF);
      case 'Normal weight':
        return const Color(0xFF6BCB77);
      case 'Overweight':
        return const Color(0xFFFFE66D);
      default:
        return const Color(0xFFFF6B6B);
    }
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('BMI Calculator',
            style: TextStyle(color: context.textPrimary)),
        backgroundColor: context.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: context.textSecondary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: context.cardDecoration(
                  radius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter Your Details',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  _inputField(
                    context: context,
                    controller: _heightCtrl,
                    label: 'Height (cm)',
                    hint: 'e.g. 170',
                    icon: Icons.height_rounded,
                  ),
                  const SizedBox(height: 12),

                  _inputField(
                    context: context,
                    controller: _weightCtrl,
                    label: 'Weight (kg)',
                    hint: 'e.g. 65',
                    icon: Icons.monitor_weight_outlined,
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: _calculate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Calculate BMI',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Result card
            if (_result != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: context.cardDecoration(
                    radius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    // Gauge
                    BmiGauge(bmi: _result!.bmi),

                    const SizedBox(height: 16),

                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: _categoryColor, width: 1.5),
                      ),
                      child: Text(
                        _result!.category,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _categoryColor == const Color(0xFFFFE66D)
                              ? context.textPrimary
                              : _categoryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Zone legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _zone(context, '< 18.5', 'Under', const Color(0xFF4D96FF)),
                        _zone(context, '18.5–25', 'Normal', const Color(0xFF6BCB77)),
                        _zone(context, '25–30', 'Over', const Color(0xFFFFE66D)),
                        _zone(context, '> 30', 'Obese', const Color(0xFFFF6B6B)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Advice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.inputFill,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _result!.advice,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Ideal weight info
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(context.isDark ? 0.2 : 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.track_changes_rounded,
                        size: 28, color: context.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ideal Weight Range',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: context.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _idealWeight(_result!.heightCm),
                            style: TextStyle(
                                fontSize: 13, color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _idealWeight(double heightCm) {
    final hM = heightCm / 100;
    final minW = (18.5 * hM * hM).toStringAsFixed(1);
    final maxW = (24.9 * hM * hM).toStringAsFixed(1);
    return 'For your height (${heightCm.toStringAsFixed(0)} cm), '
        'ideal weight is $minW – $maxW kg';
  }

  Widget _zone(BuildContext context, String range, String label, Color color) {
    return Column(
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: context.textPrimary)),
        Text(range,
            style: TextStyle(fontSize: 9, color: context.textHint)),
      ],
    );
  }

  Widget _inputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.textHint),
            prefixIcon: Icon(icon, color: AppColors.green, size: 20),
            filled: true,
            fillColor: context.inputFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: context.isDark
                      ? context.mutedBorder
                      : Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }
}
