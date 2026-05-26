import 'package:flutter/material.dart';
import 'models/character.dart';

/// 급식실 대소동 — 글로벌 색상 시스템
class AppColors {
  AppColors._();

  // ─── 배경 ───
  static const Color scaffoldBg = Color(0xFFFFF5D8);
  static const Color skyTop = Color(0xFF8ED7F7);
  static const Color skyBottom = Color(0xFFFFF2C7);
  static const Color grass = Color(0xFF8FD06A);
  static const Color grassDark = Color(0xFF5EA94E);
  static const Color ink = Color(0xFF2E2A25);
  static const Color outline = Color(0xFF4B3A2E);
  static const Color surfaceDark = Color(0xFFFFE4A8);
  static const Color surfaceCard = Color(0xFFFFFAE8);
  static const Color panelBg = Color(0xFFFDF0C2);

  // ─── 주요 액센트 ───
  static const Color neonCyan = Color(0xFF35AFC0);
  static const Color neonCyanLight = Color(0xFFE7FBFF);
  static const Color neonGold = Color(0xFFF6B63F);
  static const Color neonPink = Color(0xFFF06B57);
  static const Color neonPinkLight = Color(0xFFFFB3A3);

  // ─── 등급(Grade) 색상 ───
  static const Color gradeNormal = Color(0xFF57B96A);
  static const Color gradeRare = Color(0xFF4BA3D9);
  static const Color gradeEpic = Color(0xFFE18BCA);
  static const Color gradeLegendary = Color(0xFFF6B63F);

  // ─── 기능 색상 ───
  static const Color hpGreen = Color(0xFF4CAF50);
  static const Color manaBlue = Color(0xFF35AFC0);
  static const Color damageRed = Color(0xFFD94B3D);
  static const Color healGreen = Color(0xFF35A852);
  static const Color skillPurple = Color(0xFF9B59B6);
  static const Color critYellow = Color(0xFFFFD447);
  static const Color shieldBlue = Color(0xFF3A8BD8);
  static const Color poisonPurple = Color(0xFF8E5CC2);

  // ─── 텍스트 ───
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF5B4C3A);
  static const Color textMuted = Color(0xFF7B6B57);
  static const Color textDim = Color(0xFF8A7761);

  // ─── 승리/패배 ───
  static const Color victoryGold = Color(0xFFFFCF45);
  static const Color defeatRed = Color(0xFFD94B3D);
  static const Color drawGrey = Color(0xFF8E8E8E);
  static const Color winGreen = Color(0xFF4FAE57);

  /// 등급에 따른 색상 반환
  static Color getGradeColor(CharacterGrade? grade) {
    if (grade == null) return Colors.white24;
    switch (grade) {
      case CharacterGrade.normal:
        return gradeNormal;
      case CharacterGrade.rare:
        return gradeRare;
      case CharacterGrade.epic:
        return gradeEpic;
      case CharacterGrade.legendary:
        return gradeLegendary;
    }
  }

  /// 등급 한국어 텍스트
  static String getGradeText(CharacterGrade grade) {
    switch (grade) {
      case CharacterGrade.normal:
        return '일반';
      case CharacterGrade.rare:
        return '희귀';
      case CharacterGrade.epic:
        return '영웅';
      case CharacterGrade.legendary:
        return '전설';
    }
  }
}
