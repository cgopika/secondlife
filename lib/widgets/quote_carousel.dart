import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuoteCarousel extends StatefulWidget {
  final List<String> quotes;

  const QuoteCarousel({super.key, required this.quotes});

  @override
  State<QuoteCarousel> createState() => _QuoteCarouselState();
}

class _QuoteCarouselState extends State<QuoteCarousel> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _nextQuote);
  }

  void _nextQuote() {
    if (!mounted) return;
    setState(() => index = (index + 1) % widget.quotes.length);
    Future.delayed(const Duration(seconds: 4), _nextQuote);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, .08), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: Text(
            widget.quotes[index],
            key: ValueKey(index),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: AppColors.secondaryText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.quotes.length, (i) {
            final active = i == index;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 8 : 6,
              height: active ? 8 : 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.lightMint,
                shape: BoxShape.circle,
              ),
            );
          }),
        )
      ],
    );
  }
}
