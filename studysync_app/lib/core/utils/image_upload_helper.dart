import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class ImageUploadHelper {
  static Future<String?> pickAndEncodeImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return null;
    final Uint8List bytes = await picked.readAsBytes();
    final base64Str = base64Encode(bytes);
    final mimeType = picked.mimeType ?? 'image/jpeg';
    return 'data:$mimeType;base64,$base64Str';
  }
}
