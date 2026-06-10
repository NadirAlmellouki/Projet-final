import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

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
  String? _newPhotoBase64;
  int? _selectedYear;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user!;
    _selectedYear = user.year;
    _firstNameCtrl = TextEditingController(text: user.firstName);
    _lastNameCtrl = TextEditingController(text: user.lastName);
    _universityCtrl = TextEditingController(text: user.university ?? '');
    _majorCtrl = TextEditingController(text: user.major ?? '');
    _bioCtrl = TextEditingController(text: user.bio ?? '');
  }

  Future<void> _pickPhoto() async {
    final encoded = await ImageUploadHelper.pickAndEncodeImage();
    if (encoded != null) setState(() => _newPhotoBase64 = encoded);
  }

  Widget _avatarChild() {
    if (_newPhotoBase64 != null) {
      return ClipOval(
        child: Image.memory(
          base64Decode(_newPhotoBase64!.split(',').last),
          fit: BoxFit.cover,
          width: 80,
          height: 80,
        ),
      );
    }
    final user = ref.read(authProvider).user;
    if (user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty) {
      final imageProvider = user.profilePhoto!.startsWith('data:')
          ? MemoryImage(base64Decode(user.profilePhoto!.split(',').last))
              as ImageProvider
          : NetworkImage(user.profilePhoto!);
      return CircleAvatar(radius: 40, backgroundImage: imageProvider);
    }
    return const Icon(Icons.person, color: AppColors.primary, size: 28);
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

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final updated = await ref.read(userRepositoryProvider).updateProfile({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'university': _universityCtrl.text.trim(),
        'major': _majorCtrl.text.trim(),
        if (_selectedYear != null) 'year': _selectedYear,
        'bio': _bioCtrl.text.trim(),
        if (_newPhotoBase64 != null) 'profile_photo': _newPhotoBase64,
      });
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
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('Annuler'),
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sauvegarder'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null) ErrorBanner(message: _error!),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFC7D2FE), width: 3),
                      ),
                      child: _avatarChild(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _pickPhoto,
                    child: const Text('Changer la photo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const InputLabel('Prénom'),
                      TextField(controller: _firstNameCtrl),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const InputLabel('Nom'),
                      TextField(controller: _lastNameCtrl),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: InputLabel('Année'),
            ),
            DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('L1')),
                DropdownMenuItem(value: 2, child: Text('L2')),
                DropdownMenuItem(value: 3, child: Text('L3')),
                DropdownMenuItem(value: 4, child: Text('M1')),
                DropdownMenuItem(value: 5, child: Text('M2')),
              ],
              onChanged: (v) => setState(() => _selectedYear = v),
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
