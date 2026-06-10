import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/profile_photo_picker.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _universityCtrl;
  late final TextEditingController _majorCtrl;
  late final TextEditingController _bioCtrl;
  String? _photoUrl;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user!;
    _firstNameCtrl = TextEditingController(text: user.firstName);
    _lastNameCtrl = TextEditingController(text: user.lastName);
    _universityCtrl = TextEditingController(text: user.university ?? '');
    _majorCtrl = TextEditingController(text: user.major ?? '');
    _bioCtrl = TextEditingController(text: user.bio ?? '');
    _photoUrl = user.profilePhoto;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _universityCtrl.dispose();
    _majorCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  String get _initials {
    final f = _firstNameCtrl.text.trim();
    final l = _lastNameCtrl.text.trim();
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
    return 'U';
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final payload = <String, dynamic>{
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'university': _universityCtrl.text.trim(),
        'major': _majorCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
      };
      if (_photoUrl != null) {
        payload['profile_photo'] = _photoUrl;
      } else {
        payload['profile_photo'] = '';
      }

      final updated = await ref.read(userRepositoryProvider).updateProfile(payload);
      ref.read(authProvider.notifier).setUser(updated);
      if (mounted) context.pop();
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('Annuler', style: TextStyle(color: Colors.white)),
        ),
        leadingWidth: 90,
        title: const Text('Modifier'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Sauvegarder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null) ErrorBanner(message: _error!),
            ProfilePhotoPicker(
              initials: _initials,
              photoUrl: _photoUrl,
              isLoading: _isSaving,
              onPhotoSelected: (url) => setState(() => _photoUrl = url),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const InputLabel('Prénom'),
                      TextField(controller: _firstNameCtrl, onChanged: (_) => setState(() {})),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const InputLabel('Nom'),
                      TextField(controller: _lastNameCtrl, onChanged: (_) => setState(() {})),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: InputLabel('Université'),
            ),
            TextField(controller: _universityCtrl),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: InputLabel('Filière'),
            ),
            TextField(controller: _majorCtrl),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: InputLabel('Bio'),
            ),
            TextField(controller: _bioCtrl, maxLines: 3),
          ],
        ),
      ),
    );
  }
}
