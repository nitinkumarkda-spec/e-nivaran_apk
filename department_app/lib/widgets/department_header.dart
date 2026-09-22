import 'package:flutter/material.dart';

/// Reusable emblem/logo box for department screens.
class DepartmentHeader extends StatelessWidget {
  final double size;

  const DepartmentHeader({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Image.asset(
        'assets/images/logo2.png',
        fit: BoxFit.contain,
        errorBuilder: (ctx, e, st) => Icon(
          Icons.shield,
          size: size * 0.55,
          color: const Color(0xFFE3861C),
        ),
      ),
    );
  }
}
