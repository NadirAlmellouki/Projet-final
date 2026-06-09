import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.size = 36,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String initials;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryTint,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: size * 0.33,
          fontWeight: FontWeight.w600,
          color: foregroundColor ?? AppColors.primary,
        ),
      ),
    );
  }
}

class MatchScoreBadge extends StatelessWidget {
  const MatchScoreBadge({super.key, required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '⚡ ${score.round()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SessionChip extends StatelessWidget {
  const SessionChip({
    super.key,
    required this.label,
    this.variant = ChipVariant.gray,
  });

  final String label;
  final ChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      ChipVariant.primary => (AppColors.primaryTint, const Color(0xFF3730A3)),
      ChipVariant.green => (const Color(0xFFF0FDF4), const Color(0xFF166534)),
      ChipVariant.gray => (AppColors.surface, AppColors.text2),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: variant == ChipVariant.gray
            ? Border.all(color: AppColors.border, width: 0.5)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

enum ChipVariant { primary, green, gray }

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.creatorInitials,
    required this.creatorName,
    required this.subject,
    required this.subtitle,
    this.matchScore,
    this.distanceKm,
    this.isActiveNow = false,
    this.onJoin,
  });

  final String creatorInitials;
  final String creatorName;
  final String subject;
  final String subtitle;
  final double? matchScore;
  final double? distanceKm;
  final bool isActiveNow;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    UserAvatar(initials: creatorInitials),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            creatorName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text1,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.text3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (matchScore != null) MatchScoreBadge(score: matchScore!),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              SessionChip(label: subject, variant: ChipVariant.primary),
              if (distanceKm != null)
                SessionChip(
                  label: '📍 ${distanceKm!.toStringAsFixed(1)} km',
                  variant: ChipVariant.gray,
                ),
              if (isActiveNow)
                const SessionChip(label: 'Maintenant', variant: ChipVariant.green),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onJoin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Rejoindre'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.explore_outlined, Icons.explore, 'Découvrir'),
      (Icons.map_outlined, Icons.map, 'Carte'),
      (Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
      (Icons.bar_chart_outlined, Icons.bar_chart, 'Stats'),
      (Icons.person_outline, Icons.person, 'Profil'),
    ];

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == currentIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    active ? items[i].$2 : items[i].$1,
                    size: 22,
                    color: active ? AppColors.primary : AppColors.text3,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i].$3,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.primary : AppColors.text3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.nunitoSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}
