import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/session_member_role.dart';

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
      ChipVariant.primary => (AppColors.primaryTint, AppColors.primaryDark),
      ChipVariant.green => (AppColors.successTint, const Color(0xFF047857)),
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
    this.memberRole = SessionMemberRole.none,
    this.onJoin,
    this.onOpenChat,
    this.onReport,
  });

  final String creatorInitials;
  final String creatorName;
  final String subject;
  final String subtitle;
  final double? matchScore;
  final double? distanceKm;
  final bool isActiveNow;
  final SessionMemberRole memberRole;
  final VoidCallback? onJoin;
  final VoidCallback? onOpenChat;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final isParticipant = memberRole.isParticipant;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActiveNow ? AppColors.accent.withValues(alpha: 0.35) : AppColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: isActiveNow
                    ? AppColors.accent
                    : isParticipant
                        ? AppColors.primary
                        : AppColors.border,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserAvatar(initials: creatorInitials),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  creatorName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text1,
                                  ),
                                ),
                                if (subtitle.isNotEmpty)
                                  Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.text3,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (matchScore != null) MatchScoreBadge(score: matchScore!),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          SessionChip(label: subject, variant: ChipVariant.primary),
                          if (distanceKm != null)
                            SessionChip(
                              label: '${distanceKm!.toStringAsFixed(1)} km',
                              variant: ChipVariant.gray,
                            ),
                          if (isActiveNow)
                            const SessionChip(
                              label: 'En cours',
                              variant: ChipVariant.green,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isParticipant && onReport != null)
                            IconButton(
                              onPressed: onReport,
                              icon: const Icon(Icons.flag_outlined, size: 20),
                              color: AppColors.text3,
                              tooltip: 'Signaler',
                              visualDensity: VisualDensity.compact,
                            ),
                          _SessionMembershipButton(
                            role: memberRole,
                            onJoin: onJoin,
                            onOpenChat: onOpenChat,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionMembershipButton extends StatelessWidget {
  const _SessionMembershipButton({
    required this.role,
    this.onJoin,
    this.onOpenChat,
  });

  final SessionMemberRole role;
  final VoidCallback? onJoin;
  final VoidCallback? onOpenChat;

  @override
  Widget build(BuildContext context) {
    return switch (role) {
      SessionMemberRole.creator => _StatusPill(
          label: 'Créateur',
          icon: Icons.star_rounded,
          background: AppColors.primaryTint,
          foreground: AppColors.primaryDark,
          onTap: onOpenChat,
        ),
      SessionMemberRole.member => _StatusPill(
          label: 'Membre',
          icon: Icons.check_circle_rounded,
          background: AppColors.successTint,
          foreground: const Color(0xFF047857),
          onTap: onOpenChat,
        ),
      SessionMemberRole.none => SizedBox(
          height: 36,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(96, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Rejoindre'),
            ),
          ),
        ),
    };
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: child,
        ),
      );
    }
    return child;
  }
}

/// En-tête dégradé réutilisable sur les onglets principaux.
class ScreenHeroHeader extends StatelessWidget {
  const ScreenHeroHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.icon = Icons.auto_awesome,
    this.trailing,
    this.margin = const EdgeInsets.fromLTRB(16, 12, 16, 10),
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing ??
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
        ],
      ),
    );
  }
}

/// Carte surface standard (listes, sections).
class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.accentColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final EdgeInsets padding;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (accentColor != null)
                Container(width: 4, color: accentColor),
              Expanded(
                child: Padding(padding: padding, child: child),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.text2,
                height: 1.5,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class ChatSessionTile extends StatelessWidget {
  const ChatSessionTile({
    super.key,
    required this.initials,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.onRate,
    this.onReport,
  });

  final String initials;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onRate;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      onTap: onTap,
      accentColor: AppColors.accent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          UserAvatar(initials: initials, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3),
                ),
              ],
            ),
          ),
          if (onReport != null || onRate != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: AppColors.text3),
              onSelected: (value) {
                if (value == 'report') onReport?.call();
                if (value == 'rate') onRate?.call();
              },
              itemBuilder: (_) => [
                if (onRate != null)
                  const PopupMenuItem(
                    value: 'rate',
                    child: Text('Évaluer les participants'),
                  ),
                if (onReport != null)
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Signaler la session'),
                  ),
              ],
            )
          else
            const Icon(Icons.chevron_right, color: AppColors.text3, size: 22),
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
      (Icons.explore_outlined, Icons.explore_rounded, 'Découvrir'),
      (Icons.map_outlined, Icons.map_rounded, 'Carte'),
      (Icons.chat_bubble_outline, Icons.chat_bubble_rounded, 'Chat'),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Stats'),
      (Icons.person_outline, Icons.person_rounded, 'Profil'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primaryTint
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: active ? AppColors.primary : AppColors.text3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.accentIndex = 0,
  });

  final String value;
  final String label;
  final IconData? icon;
  final int accentIndex;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.statAccents[accentIndex % AppColors.statAccents.length];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: accent),
                ),
              if (icon != null) const Spacer(),
              Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}
