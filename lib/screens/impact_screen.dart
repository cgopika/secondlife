import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class ImpactPage extends StatelessWidget {
  const ImpactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Impact',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.darkText),
            ),
            const SizedBox(height: 8),
            const Text(
              'See how your exchanges create value for your community.',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView(
                children: [
                  _StatCard(title: 'Materials reused', value: '42'),
                  const SizedBox(height: 12),
                  _StatCard(title: 'CO₂ saved (est.)', value: '128 kg'),
                  const SizedBox(height: 12),
                  _StatCard(title: 'Local exchanges', value: '19'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.secondaryText)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.softGreen,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: SvgPicture.asset('assets/icons/secondlife_mark.svg'),
            ),
          )
        ],
      ),
    );
  }
}
