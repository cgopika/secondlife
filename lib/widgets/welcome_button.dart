import 'package:flutter/material.dart';

class WelcomeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const WelcomeButton({super.key, required this.label, required this.onTap, this.primary = true});

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return SizedBox(
        height: 54,
        width: double.infinity,
        child: FilledButton(
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
    }

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
