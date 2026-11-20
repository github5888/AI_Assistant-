import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class LabScreen extends StatelessWidget {
  const LabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: AppGradients.navy,
            boxShadow: const [
              BoxShadow(
                color: Color(0x33101A3A),
                blurRadius: 26,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: const Color(0x33F7E3BB),
                ),
                child: const Icon(Icons.science, size: 22, color: AppColors.goldLight),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proof, not promises.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Every harvest batch is tested at an NABL-accredited lab. The certificate travels with your pack.',
                      style: TextStyle(
                        fontSize: 8.5,
                        height: 1.45,
                        color: Color(0xA6FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _CertificateCard(),
        SectionHeader(
          eyebrow: 'Our standards',
          title: 'Quality benchmarks',
        ),
        ..._benchmarks.map((row) => _BenchmarkRow(row: row)),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: premiumCard(),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(Icons.apps, size: 34, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan to verify',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Batch #IC-0426 · NABL report IC-0426/28',
                      style: TextStyle(fontSize: 8.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified, size: 18, color: AppColors.green),
            ],
          ),
        ),
      ],
    );
  }
}

class _CertificateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: premiumCard(radius: 18),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Batch Purity Certificate',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'NABL · REPORT IC-0426/28',
                            style: TextStyle(fontSize: 8.5, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF6EE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, size: 11, color: AppColors.green),
                          SizedBox(width: 4),
                          Text(
                            'PASSED',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Expanded(child: _Meta(label: 'BATCH', value: '#IC-0426')),
                    Expanded(child: _Meta(label: 'MILLED', value: '17 Nov 2026')),
                    Expanded(child: _Meta(label: 'PEAK TEMP', value: '27.4°C')),
                  ],
                ),
                const SizedBox(height: 8),
                ...labTests.map((test) => _TestRow(test: test)),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.check_circle, size: 13, color: AppColors.green),
                    SizedBox(width: 6),
                    Text(
                      '6 of 6 parameters passed · nothing added',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 72,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xEBEAF6EE),
                  border: Border.all(
                    color: const Color(0x59357A45),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, size: 17, color: AppColors.green),
                    Text(
                      'NABL\nVERIFIED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 6.2,
                        fontWeight: FontWeight.w900,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final String label;
  final String value;
  const _Meta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: eyebrowStyle(color: AppColors.muted).copyWith(fontSize: 7, letterSpacing: 1),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _TestRow extends StatelessWidget {
  final LabTest test;
  const _TestRow({required this.test});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEAF6EE),
            ),
            child: const Icon(Icons.check, size: 12, color: AppColors.green),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.name,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  test.method,
                  style: const TextStyle(fontSize: 7.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            test.result,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenchmarkRow extends StatelessWidget {
  final Map<String, String> row;
  const _BenchmarkRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(13),
      decoration: premiumCard(radius: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: AppColors.sand,
            ),
            child: const Icon(Icons.verified, size: 15, color: AppColors.orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row['title']!,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row['note']!,
                  style: const TextStyle(fontSize: 8, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            row['code']!,
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

const _benchmarks = <Map<String, String>>[
  {'title': 'FSSAI 100% Whole Grain', 'code': 'LIC. 11522998000123', 'note': 'Whole grain compliance'},
  {'title': 'Cold Chakki < 28°C', 'code': 'LOG 27.4°C PEAK', 'note': 'Live enzymes intact'},
  {'title': 'NABL Lab Tested Batch', 'code': 'BATCH #IC-0426', 'note': 'Certificate with every pack'},
  {'title': 'Non-GMO Ancient Heritage', 'code': 'EMMER · KHAPLI', 'note': 'Heritage seed traceability'},
  {'title': 'Zero Maida & Bleach', 'code': '0.00 ppm NIL', 'note': 'Nothing added, nothing removed'},
];
