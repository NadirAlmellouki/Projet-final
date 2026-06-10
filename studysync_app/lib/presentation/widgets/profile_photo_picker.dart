import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/profile_image_helper.dart';
import 'studysync_widgets.dart';

class ProfilePhotoPicker extends StatelessWidget {
  const ProfilePhotoPicker({
    super.key,
    required this.initials,
    this.photoUrl,
    required this.onPhotoSelected,
    this.size = 96,
    this.isLoading = false,
  });

  final String initials;
  final String? photoUrl;
  final ValueChanged<String?> onPhotoSelected;
  final double size;
  final bool isLoading;

  Future<void> _pick(BuildContext context) async {
    try {
      final dataUrl = await ProfileImageHelper.showSourceSheet(context);
      if (dataUrl != null) onPhotoSelected(dataUrl);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatar(
              initials: initials,
              size: size,
              photoUrl: photoUrl,
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: isLoading ? null : () => _pick(context),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: isLoading ? null : () => _pick(context),
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: Text(
            photoUrl != null && photoUrl!.isNotEmpty
                ? 'Modifier la photo'
                : 'Ajouter une photo',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        if (photoUrl != null && photoUrl!.isNotEmpty)
          TextButton(
            onPressed: isLoading ? null : () => onPhotoSelected(null),
            child: Text(
              'Supprimer la photo',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
