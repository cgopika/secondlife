import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class SecondLifeLogo extends StatelessWidget {
  final double size;

  const SecondLifeLogo({this.size = 56, super.key});

  @override
  Widget build(BuildContext context) {
    // Use full illustration for sizes >= 72, else use simplified SVG mark for small branding
    final useIllustration = size >= 72;
    final imageWidget = useIllustration
        ? ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: Image.asset(
              'assets/images/secondlife_logo_illustration.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackCircle(size),
            ),
          )
        : SvgPicture.asset(
            'assets/icons/secondlife_mark.svg',
            fit: BoxFit.contain,
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: size, width: size, child: imageWidget),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'SecondLife',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.darkGreen,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Give materials a second life.',
              style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
            ),
          ],
        )
      ],
    );
  }

  Widget _fallbackCircle(double size) => Container(
        decoration: BoxDecoration(
          color: AppColors.softGreen,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            height: size * 0.46,
            width: size * 0.46,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.eco_rounded,
              color: Colors.white,
              size: size * 0.28,
            ),
          ),
        ),
      );
}
