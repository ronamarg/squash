import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0F1016);
  static const backgroundAlt = Color(0xFF11131B);
  static const surface = Color(0xFF161824);
  static const card = Color(0xFF181B25);
  static const accent = Color(0xFFFF8A3D);
  static const accentSecondary = Color(0xFFB347FF);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xCCFFFFFF);
  static const textMuted = Color(0x99FFFFFF);
  static const outline = Color(0xFF272A34);
}

class AppGradients {
  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0C0D13), Color(0xFF141725)],
  );

  static const cardAccent = LinearGradient(
    colors: [Color(0xFFFF8A3D), Color(0xFFB347FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const subtle = LinearGradient(
    colors: [Color(0xFF1A1C24), Color(0xFF11131B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  static const _font = 'Helvetica';

  static const headingXL = TextStyle(
    fontFamily: _font,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const headingL = TextStyle(
    fontFamily: _font,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const headingM = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
    letterSpacing: 0.2,
  );

  static const bodyMuted = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.5,
  );

  static const button = TextStyle(
    fontFamily: _font,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );
}

class AppDecorations {
  static BoxDecoration card({double radius = 20}) {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 18,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration outlineCard({double radius = 14}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.outline, width: 1.2),
    );
  }
}
