import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _universityCtrl = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String? _profilePhotoBase64;
  int _year = 3;
  bool _isSaving = false;
  String? _error;

  static const _yearOptions = {
    1: 'L1',
    2: 'L2',
    3: 'L3',
    4: 'M1',
    5: 'M2',
  };

  @override
  void dispose() {
    _universityCtrl.dispose();
    _majorCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final encoded = await ImageUploadHelper.pickAndEncodeImage();
    if (encoded != null) setState(() => _profilePhotoBase64 = encoded);
  }

  Future<void> _save() async {
    if (_universityCtrl.text.trim().isEmpty || _majorCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Université et filière sont requises');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final updated = await userRepo.updateProfile({
        'university': _universityCtrl.text.trim(),
        'major': _majorCtrl.text.trim(),
        'year': _year,
        if (_bioCtrl.text.trim().isNotEmpty) 'bio': _bioCtrl.text.trim(),
        if (_profilePhotoBase64 != null) 'profile_photo': _profilePhotoBase64,
      });
      ref.read(authProvider.notifier).setUser(updated);
      if (mounted) context.go(AppRoutes.home);
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuration du profil'),
            Text(
              'Étape 1 / 4',
              style: TextStyle(fontSize: 11, color: AppColors.text3),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: 0.25,
                minHeight: 4,
                backgroundColor: AppColors.surface,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_error != null) ErrorBanner(message: _error!),
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC7D2FE), width: 3),
                      ),
                      child: _profilePhotoBase64 != null
                          ? ClipOval(
                              child: Image.memory(
                                base64Decode(
                                    _profilePhotoBase64!.split(',').last),
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                              ),
                            )
                          : const Icon(Icons.add_a_photo,
                              color: AppColors.primary, size: 28),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ajouter une photo de profil',
                    style: TextStyle(fontSize: 12, color: AppColors.text3),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: InputLabel('Université'),
                  ),
                  TextField(
                    controller: _universityCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Université Mohammed V',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: InputLabel('Filière / Programme'),
                  ),
                  TextField(
                    controller: _majorCtrl,
                    decoration: const InputDecoration(hintText: 'Informatique'),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: InputLabel('Année d\'études'),
                  ),
                  DropdownButtonFormField<int>(
                    value: _year,
                    decoration: const InputDecoration(),
                    items: _yearOptions.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _year = v ?? 3),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: InputLabel('Bio'),
                  ),
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Passionné par les maths...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Continuer →',
                    isLoading: _isSaving,
                    onPressed: () => _save(),
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
