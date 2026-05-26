import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Verifica se a imagem está pronta para upload.
/// Não modifica os bytes — a compressão real acontece on-device via image_picker.
class ImagePreprocessor {
  const ImagePreprocessor({
    this.maxBytes = 5000000,
  }); // 5 MB — Claude Haiku 4.5 aguenta
  final int maxBytes;

  /// Retorna os bytes se estiverem dentro do limite.
  /// Lança [ImageTooLargeException] se exceder.
  Uint8List prepareForUpload(Uint8List input) {
    if (input.length <= maxBytes) {
      return input;
    }
    throw ImageTooLargeException(actualBytes: input.length, maxBytes: maxBytes);
  }
}

class ImageTooLargeException implements Exception {
  ImageTooLargeException({required this.actualBytes, required this.maxBytes});
  final int actualBytes;
  final int maxBytes;

  @override
  String toString() =>
      'ImageTooLargeException: imagem com $actualBytes bytes excede o limite '
      'de $maxBytes bytes';
}

final imagePreprocessorProvider = Provider<ImagePreprocessor>(
  (_) => const ImagePreprocessor(),
);
