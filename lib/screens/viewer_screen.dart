import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class ViewerScreen extends StatelessWidget {
  const ViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final angle = state.viewerAngle.abs().round() % 360;
    final rotation = math.sin(state.viewerAngle * math.pi / 180) * 0.28;

    return AppPage(
      child: Column(
        children: [
          AppTopBar(
            title: '360° pack inspector',
            subtitle: 'Authentic itsclear™ packaging',
            back: true,
            actions: [
              RoundIconButton(
                icon: Icons.refresh,
                onTap: state.resetViewer,
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    state.setViewerAngle(state.viewerAngle + details.delta.dx * 0.6);
                  },
                  child: Container(
                    height: 320,
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.line),
                      gradient: const RadialGradient(
                        center: Alignment(0, -0.2),
                        radius: 0.9,
                        colors: [Color(0xFFFFFAF3), AppColors.paper],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 230,
                            height: 230,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0x40EF5B25),
                                style: BorderStyle.solid,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(rotation),
                            child: PackImage(
                              asset: viewerPacks[state.viewerIndex],
                              width: 230,
                              height: 276,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Text(
                              '${angle.toString().padLeft(3, '0')}°',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _HintPill(text: 'Drag left or right to inspect the pouch'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: viewerTabs.map((tab) {
                      final selected = state.viewerIndex == tab.index;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: PillButton(
                            label: tab.label,
                            selected: selected,
                            onTap: () => state.setViewerIndex(tab.index),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 62,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: viewerPacks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 7),
                    itemBuilder: (context, index) {
                      final selected = state.viewerIndex == index;
                      return InkWell(
                        onTap: () => state.setViewerIndex(index),
                        child: Container(
                          width: 58,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.paper,
                            border: Border.all(
                              color: selected ? AppColors.orange : AppColors.line,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: PackImage(asset: viewerPacks[index]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  child: Row(
                    children: const [
                      Icon(Icons.thermostat, size: 16, color: AppColors.orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cold milled below 28°C',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '100% Khapli Wheat · Batch #IC-0426',
                              style: TextStyle(fontSize: 8.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.verified, size: 18, color: AppColors.green),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: const [
                      Expanded(child: SpecTile(value: '27.4°C', label: 'Peak temp')),
                      SizedBox(width: 7),
                      Expanded(child: SpecTile(value: '0.00', label: 'Bleach ppm')),
                      SizedBox(width: 7),
                      Expanded(child: SpecTile(value: '100%', label: 'Bran kept')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  final String text;
  const _HintPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
