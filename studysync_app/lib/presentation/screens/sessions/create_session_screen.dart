import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geocoding_service.dart';
import '../../../core/utils/location_helper.dart';
import '../../../domain/entities/create_session_request.dart';
import '../../providers/app_providers.dart';
import '../../providers/home_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/studysync_widgets.dart';

class CreateSessionScreen extends ConsumerStatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  ConsumerState<CreateSessionScreen> createState() =>
      _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  int _duration = 60;
  int _maxParticipants = 4;
  double? _lat;
  double? _lng;
  String? _geocodedLabel;
  double? _distanceKm;
  bool _isSaving = false;
  bool _isGeocoding = false;
  String? _error;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _topicCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );
    if (time == null) return;
    setState(() {
      _startTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<bool> _resolveLocationFromAddress() async {
    final address = _locationCtrl.text.trim();
    if (address.isEmpty) {
      setState(() => _error = 'Le lieu est obligatoire pour placer la session sur la carte.');
      return false;
    }

    setState(() {
      _isGeocoding = true;
      _error = null;
      _lat = null;
      _lng = null;
      _geocodedLabel = null;
      _distanceKm = null;
    });

    try {
      final pos = await LocationHelper.getCurrentOrDefault();
      final results = await GeocodingService.searchNearMe(
        address,
        nearLat: pos.lat,
        nearLng: pos.lng,
      );

      GeocodingResult chosen;
      if (results.length == 1 || !mounted) {
        chosen = results.first;
      } else {
        final picked = await showModalBottomSheet<GeocodingResult>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Lieux proches trouvés',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Synonymes et lieux similaires près de vous — choisissez le bon.',
                    style: TextStyle(fontSize: 12, color: AppColors.text2),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length.clamp(0, 6),
                    itemBuilder: (_, i) {
                      final r = results[i];
                      return ListTile(
                        leading: const Icon(Icons.place, color: AppColors.primary),
                        title: Text(
                          r.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          'À ${r.distanceKm.toStringAsFixed(1)} km',
                        ),
                        onTap: () => Navigator.pop(ctx, r),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
        if (picked == null) return false;
        chosen = picked;
      }

      setState(() {
        _lat = chosen.lat;
        _lng = chosen.lng;
        _geocodedLabel = chosen.displayName;
        _distanceKm = chosen.distanceKm;
      });
      return true;
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_lat == null || _lng == null) {
      final ok = await _resolveLocationFromAddress();
      if (!ok) return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(sessionRepositoryProvider).createSession(
            CreateSessionRequest(
              subject: _subjectCtrl.text.trim(),
              topic: _topicCtrl.text.trim().isEmpty ? null : _topicCtrl.text.trim(),
              locationName: _locationCtrl.text.trim(),
              startTime: _startTime,
              durationMinutes: _duration,
              maxParticipants: _maxParticipants,
              latitude: _lat!,
              longitude: _lng!,
              description: _descriptionCtrl.text.trim().isEmpty
                  ? null
                  : _descriptionCtrl.text.trim(),
            ),
          );
      await ref.read(homeFeedProvider.notifier).loadSessions();
      await ref.read(chatListProvider.notifier).load();
      if (mounted) context.pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Créer une session'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ErrorBanner(message: _error!),
              AppSurfaceCard(
                margin: const EdgeInsets.only(bottom: 16),
                accentColor: AppColors.primary,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Publie une session pour trouver des partenaires près de toi.',
                        style: TextStyle(fontSize: 13, color: AppColors.text2, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const InputLabel('Matière *'),
              TextFormField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(hintText: 'Calculus II'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              const InputLabel('Sujet / chapitre'),
              TextField(
                controller: _topicCtrl,
                decoration: const InputDecoration(hintText: 'Chapitre 5'),
              ),
              const SizedBox(height: 12),
              const InputLabel('Lieu de la session *'),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  hintText: 'Bibliothèque, Faculté des sciences, Café…',
                  helperText:
                      'Recherche près de vous (synonymes : biblio, fac, univ…)',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Indiquez le lieu' : null,
                onChanged: (_) {
                  if (_lat != null) {
                    setState(() {
                      _lat = null;
                      _lng = null;
                      _geocodedLabel = null;
                      _distanceKm = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isGeocoding ? null : _resolveLocationFromAddress,
                icon: _isGeocoding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.place_outlined),
                label: Text(
                  _isGeocoding
                      ? 'Recherche près de vous…'
                      : 'Chercher un lieu proche de moi',
                ),
              ),
              if (_geocodedLabel != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lieu trouvé près de vous',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _geocodedLabel!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (_distanceKm != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'À ${_distanceKm!.toStringAsFixed(1)} km de votre position',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date et heure'),
                subtitle: Text(_startTime.toString().substring(0, 16)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateTime,
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const InputLabel('Durée (min)'),
                        DropdownButtonFormField<int>(
                          key: ValueKey(_duration),
                          initialValue: _duration,
                          items: const [30, 60, 90, 120]
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v min'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _duration = v ?? 60),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const InputLabel('Max participants'),
                        DropdownButtonFormField<int>(
                          key: ValueKey(_maxParticipants),
                          initialValue: _maxParticipants,
                          items: const [2, 4, 6, 8]
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _maxParticipants = v ?? 4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const InputLabel('Description'),
              TextField(
                controller: _descriptionCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Objectifs de la session…',
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Publier la session',
                isLoading: _isSaving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
