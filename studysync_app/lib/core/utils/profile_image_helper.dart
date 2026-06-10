import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageHelper {
  ProfileImageHelper._();

  static final _picker = ImagePicker();

  static ImageProvider? imageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        final b64 = url.contains(',') ? url.split(',').last : url;
        return MemoryImage(base64Decode(b64));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  static Future<String?> pickAndEncode({ImageSource source = ImageSource.gallery}) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.length > 900000) {
      throw Exception('Image trop volumineuse. Choisissez une photo plus petite.');
    }

    final mime = _mimeFromPath(file.path);
    final b64 = base64Encode(bytes);
    return 'data:$mime;base64,$b64';
  }

  static String _mimeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static Future<String?> showSourceSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return null;
    return pickAndEncode(source: source);
  }
}
