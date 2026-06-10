import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/profile_image_helper.dart';
import '../../domain/entities/session_member_role.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.size = 36,
    this.backgroundColor,
    this.foregroundColor,
    this.photoUrl,
  });

  final String initials;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final provider = ProfileImageHelper.imageProvider(photoUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryTint,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: provider != null ? 0.9 : 0),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: provider != null
          ? Image(
              image: provider,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(),
            )
          : _initials(),
    );
  }

  Widget _initials() {
    return Center(
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
    this.onTap,
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
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onOpenChat;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final isParticipant = memberRole.isParticipant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                                  subject,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text1,
                                  ),
                                ),
                                Text(
                                  subtitle.isNotEmpty
                                      ? subtitle
                                      : 'Par $creatorName',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.text2,
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
                          SessionChip(
                            label: creatorName,
                            variant: ChipVariant.primary,
                          ),
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

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
            boxShadow: const [
              BoxShadow(
                color: AppColors.navShadow,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: active ? 10 : 0,
                            vertical: active ? 4 : 0,
                          ),
                          decoration: active
                              ? BoxDecoration(
                                  color: AppColors.primaryTint,
                                  borderRadius: BorderRadius.circular(12),
                                )
                              : null,
                          child: Icon(
                            active ? items[i].$2 : items[i].$1,
                            size: 22,
                            color: active ? AppColors.primary : AppColors.text3,
                          ),
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

class ScreenHeroHeader extends StatelessWidget {
  const ScreenHeroHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    required this.icon,
    this.trailing,
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, 10),
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (trailing == null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
        ],
      ),
    );
  }
}

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.accentColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
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
              Expanded(child: Padding(padding: padding, child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
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
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.text2,
                height: 1.5,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
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
    required this.subject,
    required this.subtitle,
    required this.onTap,
    this.onReport,
  });

  final String initials;
  final String subject;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      accentColor: AppColors.accent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            UserAvatar(initials: initials, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
            if (onReport != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.text3),
                onSelected: (v) {
                  if (v == 'report') onReport!();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'report',
                    child: Text('Signaler la session'),
                  ),
                ],
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.text3),
          ],
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
          if (icon != null) const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
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
