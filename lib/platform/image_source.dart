import 'package:autolog/platform/image_source_mobile.dart';
import 'package:autolog/platform/image_source_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Origem da captura — câmera ou galeria.
enum ImageOrigin { camera, gallery }

/// Fonte de imagem agnóstica de plataforma.
/// Retorna `null` se o usuário cancelar.
/// Lança [ImageSourceException] em erro real (permissão negada, hardware indisponível).
abstract class ImageSource {
  Future<Uint8List?> obtainReceiptImage({
    ImageOrigin origin = ImageOrigin.camera,
  });
}

/// Exceção lançada quando a captura falha por um erro real (não cancelamento).
class ImageSourceException implements Exception {
  ImageSourceException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'ImageSourceException: $message';
}

/// Implementação fake de [ImageSource] para uso em testes.
///
/// Pertence a `lib/` (não a `test/`) para que features downstream possam
/// fazer override do provider sem duplicar o fake.
class FakeImageSource implements ImageSource {
  FakeImageSource({
    this.bytes,
    this.throwOnCall = false,
    this.returnNullOnCall = false,
  });

  final Uint8List? bytes;
  final bool throwOnCall;
  final bool returnNullOnCall;

  /// O último [ImageOrigin] passado em [obtainReceiptImage].
  ImageOrigin? lastOrigin;

  /// Número de vezes que [obtainReceiptImage] foi chamado.
  int callCount = 0;

  @override
  Future<Uint8List?> obtainReceiptImage({
    ImageOrigin origin = ImageOrigin.camera,
  }) async {
    callCount++;
    lastOrigin = origin;

    if (throwOnCall) {
      throw ImageSourceException('fake error');
    }

    if (returnNullOnCall) {
      return null;
    }

    return bytes;
  }
}

/// Provider Riverpod que injeta a implementação correta de [ImageSource]
/// conforme a plataforma em execução.
///
/// - Mobile (Android/iOS): [MobileImageSource].
/// - Web: [WebImageSource] (placeholder até Sprint 8).
final imageSourceProvider = Provider<ImageSource>((ref) {
  return kIsWeb ? WebImageSource() : const MobileImageSource();
});
