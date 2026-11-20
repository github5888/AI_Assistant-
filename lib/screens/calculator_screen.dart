import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return AppPage(
      child: Column(
        children: [
          AppTopBar(
            title: 'Grain calculator',
            subtitle: 'Find your monthly pack',
            back: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                const Eyebrow(text: 'Grain science', rule: true),
                const SizedBox(height: 8),
                Text(
                  'How many rotis does your family need?',
                  style: displayStyle(size: 24),
                ),
                const SizedBox(height: 8),
                const Text(
                  'itsclear absorbs 72% water — 36 soft rotis per kg instead of 28 from factory flour.',
                  style: TextStyle(fontSize: 10, height: 1.55, color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                const Eyebrow(text: 'Family members'),
                const SizedBox(height: 8),
                Row(
                  children: [2, 4, 6, 8].map((value) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: PillButton(
                          label: '$value Members',
                          selected: state.members == value,
                          onTap: () => state.setMembers(value),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Eyebrow(text: 'Rotis per day'),
                const SizedBox(height: 6),
                Slider(
                  value: state.rotis.toDouble(),
                  min: 4,
                  max: 60,
                  divisions: 56,
                  activeColor: AppColors.orange,
                  inactiveColor: const Color(0x33EF5B25),
                  label: '${state.rotis}',
                  onChanged: (value) => state.setRotis(value.round()),
                ),
                Row(
                  children: [
                    _QuickRotis(label: 'Light', value: 4, current: state.rotis),
                    _QuickRotis(label: 'Average', value: 16, current: state.rotis),
                    _QuickRotis(label: 'Large', value: 40, current: state.rotis),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: AppGradients.navy,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33101A3A),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow(
                        text: 'Monthly projection',
                        color: AppColors.amber,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${state.calcMonthly}',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'rotis / month',
                            style: TextStyle(fontSize: 10, color: Color(0x9FFFFFFF)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _YieldBar(
                        label: 'itsclear',
                        value: state.calcClearKg,
                        max: state.calcFactoryKg,
                        color: AppColors.orange,
                      ),
                      const SizedBox(height: 9),
                      _YieldBar(
                        label: 'Factory atta',
                        value: state.calcFactoryKg,
                        max: state.calcFactoryKg,
                        color: AppColors.goldLight,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: AppColors.amber),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'You save ${state.calcSavedKg.toStringAsFixed(1)} kg of flour every month.',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xBFFFFFFF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Shop the recommended pack',
                  icon: Icons.arrow_forward,
                  onTap: () {
                    state.setCategory(0);
                    state.goTab(1);
                    popScreen(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickRotis extends StatelessWidget {
  final String label;
  final int value;
  final int current;
  const _QuickRotis({
    required this.label,
    required this.value,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: PillButton(
          label: '$label ($value)',
          selected: current == value,
          onTap: () => state.setRotis(value),
        ),
      ),
    );
  }
}

class _YieldBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  const _YieldBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double pct = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0).toDouble();
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontSize: 8.5, color: Color(0x9FFFFFFF)),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: const Color(0x33FFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${value.toStringAsFixed(1)} kg',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
