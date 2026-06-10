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
    _mapController.move(center, 14.5);
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: session.isParticipant
                        ? const LinearGradient(
                            colors: [AppColors.accent, AppColors.primary],
                          )
                        : AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    session.subject.isNotEmpty
                        ? session.subject[0].toUpperCase()
                        : 'S',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
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
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.text3,
                          ),
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
                SessionChip(
                  label: '${session.participantCount ?? 1} participant(s)',
                  variant: ChipVariant.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _MapSessionActions(
              session: session,
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
              const SizedBox(height: 16),
              Text(
                'Chargement de la carte…',
                style: GoogleFonts.inter(color: AppColors.text2),
              ),
            ],
          ),
        ),
      );
    }

    final sessionsWithLoc =
        state.sessions.where((s) => s.hasLocation).toList();
    final joinedCount =
        sessionsWithLoc.where((s) => s.isParticipant).length;

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
              minZoom: 10,
              maxZoom: 18,
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
                    radius: 800,
                    useRadiusInMeter: true,
                    color: AppColors.mapUserDot.withValues(alpha: 0.08),
                    borderColor: AppColors.mapUserDot.withValues(alpha: 0.2),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: userPoint,
                    width: 56,
                    height: 56,
                    child: const _UserLocationMarker(),
                  ),
                  ...sessionsWithLoc.map(
                    (s) => Marker(
                      point: LatLng(s.latitude!, s.longitude!),
                      width: 52,
                      height: 62,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _showSessionSheet(s),
                        child: _SessionMapPin(session: s),
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mapOverlay,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: AppColors.heroGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.map_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Carte des sessions',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text1,
                                  ),
                                ),
                                Text(
                                  '${sessionsWithLoc.length} session(s) à proximité',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.text3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _MapLegendDot(
                            color: AppColors.mapMarkerOpen,
                            label: 'Ouverte',
                          ),
                          const SizedBox(width: 8),
                          _MapLegendDot(
                            color: AppColors.mapMarkerJoined,
                            label: 'Membre',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (sessionsWithLoc.isNotEmpty)
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: sessionsWithLoc.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final s = sessionsWithLoc[i];
                            return ActionChip(
                              avatar: CircleAvatar(
                                radius: 10,
                                backgroundColor: s.isParticipant
                                    ? AppColors.mapMarkerJoined
                                    : AppColors.mapMarkerOpen,
                                child: Text(
                                  s.subject.isNotEmpty
                                      ? s.subject[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              label: Text(
                                s.subject,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: AppColors.mapOverlay,
                              side: const BorderSide(color: AppColors.border),
                              onPressed: () {
                                _mapController.move(
                                  LatLng(s.latitude!, s.longitude!),
                                  15,
                                );
                                _showSessionSheet(s);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _MapFab(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Ma position',
                  onPressed: () => _centerOnUser(userPoint),
                ),
                const SizedBox(height: 10),
                _MapFab(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Actualiser',
                  onPressed: () =>
                      ref.read(mapSessionsProvider.notifier).load(),
                ),
              ],
            ),
          ),
          if (joinedCount > 0)
            Positioned(
              left: 16,
              bottom: 100,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$joinedCount rejointe(s)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.mapUserDot.withValues(alpha: 0.15),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.mapUserDot,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.mapUserDot.withValues(alpha: 0.4),
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
  const _SessionMapPin({required this.session});

  final StudySession session;

  @override
  Widget build(BuildContext context) {
    final joined = session.isParticipant;
    final color =
        joined ? AppColors.mapMarkerJoined : AppColors.mapMarkerOpen;
    final letter = session.subject.isNotEmpty
        ? session.subject[0].toUpperCase()
        : 'S';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: joined
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accent, AppColors.primary],
                  )
                : null,
            color: joined ? null : color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(14, 8),
          painter: _PinTailPainter(color: joined ? AppColors.primary : color),
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
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MapFab extends StatelessWidget {
  const _MapFab({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mapOverlay,
      elevation: 4,
      shadowColor: AppColors.cardShadow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}

class _MapLegendDot extends StatelessWidget {
  const _MapLegendDot({required this.color, required this.label});

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
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.text3),
        ),
      ],
    );
  }
}

class _MapSessionActions extends StatelessWidget {
  const _MapSessionActions({
    required this.session,
    required this.onJoin,
    required this.onOpenChat,
    required this.onReport,
  });

  final StudySession session;
  final VoidCallback onJoin;
  final VoidCallback onOpenChat;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return switch (session.memberRole) {
      SessionMemberRole.creator => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetStatusRow(
              icon: Icons.star_rounded,
              label: 'Vous êtes le créateur',
              color: AppColors.primary,
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
      SessionMemberRole.none => SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton.icon(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              icon: const Icon(Icons.group_add_rounded, size: 18),
              label: const Text('Rejoindre la session'),
            ),
          ),
        ),
    };
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
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
