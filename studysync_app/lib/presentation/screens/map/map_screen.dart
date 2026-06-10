import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/session_member_role.dart';
import '../../../domain/entities/study_session.dart';
import '../../providers/home_provider.dart';
import '../sessions/session_detail_screen.dart';
import '../../widgets/report_sheet.dart';
import '../../widgets/studysync_widgets.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapSessionsProvider.notifier).load();
    });
  }

  Future<void> _joinSession(StudySession session) async {
    final ok = await ref.read(homeFeedProvider.notifier).joinSession(session.id);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Vous avez rejoint « ${session.subject} »'
              : ref.read(homeFeedProvider).errorMessage ?? 'Impossible de rejoindre',
        ),
      ),
    );
    if (ok) {
      ref.read(mapSessionsProvider.notifier).load();
    }
  }

  void _centerOnUser(LatLng center) {
    _mapController.move(center, 14);
    ref.read(mapSessionsProvider.notifier).load();
  }

  void _showSessionSheet(StudySession session) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                UserAvatar(initials: session.creatorInitials, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.subject,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text1,
                        ),
                      ),
                      if (session.locationName != null)
                        Text(
                          session.locationName!,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (session.distanceKm != null)
                  SessionChip(
                    label: '${session.distanceKm!.toStringAsFixed(1)} km',
                    variant: ChipVariant.gray,
                  ),
                if (session.isActiveNow)
                  const SessionChip(label: 'En cours', variant: ChipVariant.green),
                if (session.isParticipant)
                  const SessionChip(label: 'Ma session', variant: ChipVariant.primary),
              ],
            ),
            const SizedBox(height: 20),
            _MapSessionActions(
              session: session,
              onViewDetails: () {
                Navigator.pop(ctx);
                openSessionDetail(context, session);
              },
              onJoin: () => _joinSession(session),
              onOpenChat: () {
                Navigator.pop(ctx);
                context.push(
                  '${AppRoutes.chatRoom}/${session.id}',
                  extra: session.subject,
                );
              },
              onReport: () async {
                Navigator.pop(ctx);
                final sent = await ReportSheet.show(
                  context,
                  targetType: ReportTargetType.session,
                  targetLabel: session.subject,
                  reportedSessionId: session.id,
                  reportedUserId: session.creatorId,
                );
                if (sent == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signalement envoyé. Merci.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _pinColor(StudySession session) {
    if (session.isCreator) return AppColors.mapPinJoined;
    if (session.memberRole == SessionMemberRole.member) return AppColors.mapPinMine;
    return AppColors.mapPinOther;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapSessionsProvider);

    if (state.isLoading && state.userLat == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 14),
              Text(
                'Chargement de la carte…',
                style: GoogleFonts.inter(color: AppColors.text2),
              ),
            ],
          ),
        ),
      );
    }

    final sessionsWithLoc = state.sessions.where((s) => s.hasLocation).toList();
    final userPoint = LatLng(
      state.userLat ?? 33.9716,
      state.userLng ?? -6.8498,
    );

    LatLng center = userPoint;
    if (sessionsWithLoc.isNotEmpty) {
      final first = sessionsWithLoc.first;
      center = LatLng(first.latitude!, first.longitude!);
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.studysync.studysync_app',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: userPoint,
                    radius: 120,
                    useRadiusInMeter: true,
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderColor: AppColors.accent.withValues(alpha: 0.35),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: userPoint,
                    width: 52,
                    height: 52,
                    child: _UserLocationMarker(),
                  ),
                  ...sessionsWithLoc.map(
                    (s) => Marker(
                      point: LatLng(s.latitude!, s.longitude!),
                      width: 48,
                      height: 56,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _showSessionSheet(s),
                        child: _SessionMapPin(
                          label: s.subject,
                          color: _pinColor(s),
                          isActive: s.isActiveNow,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  ScreenHeroHeader(
                    compact: true,
                    eyebrow: 'Géolocalisation',
                    title: 'Sessions autour de vous',
                    subtitle: '${sessionsWithLoc.length} lieu(x) sur la carte',
                    icon: Icons.map_rounded,
                    trailing: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _centerOnUser(userPoint),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _MapLegendBar(sessionCount: sessionsWithLoc.length),
                  ),
                ],
              ),
            ),
          ),
          if (state.errorMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 88,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.45),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionMapPin extends StatelessWidget {
  const _SessionMapPin({
    required this.label,
    required this.color,
    required this.isActive,
  });

  final String label;
  final Color color;
  final bool isActive;

  String get _abbr {
    final parts = label.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, Color.lerp(color, Colors.black, 0.15)!],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            _abbr,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(14, 8),
          painter: _PinTailPainter(color: color),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  _PinTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapLegendBar extends StatelessWidget {
  const _MapLegendBar({required this.sessionCount});

  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _LegendDot(color: AppColors.mapPinOther, label: 'Disponible'),
          const SizedBox(width: 12),
          _LegendDot(color: AppColors.mapPinMine, label: 'Membre'),
          const SizedBox(width: 12),
          _LegendDot(color: AppColors.mapPinJoined, label: 'Créateur'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$sessionCount',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.text2),
        ),
      ],
    );
  }
}

class _MapSessionActions extends StatelessWidget {
  const _MapSessionActions({
    required this.session,
    required this.onViewDetails,
    required this.onJoin,
    required this.onOpenChat,
    required this.onReport,
  });

  final StudySession session;
  final VoidCallback onViewDetails;
  final VoidCallback onJoin;
  final VoidCallback onOpenChat;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onViewDetails,
          icon: const Icon(Icons.info_outline_rounded, size: 18),
          label: const Text('Voir les détails'),
        ),
        const SizedBox(height: 10),
        switch (session.memberRole) {
      SessionMemberRole.creator => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetStatusRow(
              icon: Icons.star_rounded,
              label: 'Vous êtes le créateur',
              color: AppColors.coral,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onOpenChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Ouvrir le chat'),
            ),
          ],
        ),
      SessionMemberRole.member => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetStatusRow(
              icon: Icons.check_circle_rounded,
              label: 'Vous êtes membre',
              color: AppColors.success,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    label: const Text('Signaler'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onOpenChat,
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      SessionMemberRole.none => ElevatedButton.icon(
          onPressed: onJoin,
          icon: const Icon(Icons.group_add_rounded, size: 18),
          label: const Text('Rejoindre la session'),
        ),
    },
      ],
    );
  }
}

class _SheetStatusRow extends StatelessWidget {
  const _SheetStatusRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
