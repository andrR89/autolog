import 'dart:typed_data';

import 'package:autolog/platform/image_source.dart';

/// Placeholder de [ImageSource] para web.
///
/// A implementação real (file picker / drag-and-drop) chegará na Sprint 8.
/// Por ora, lança [UnimplementedError] para sinalizar que o pipeline já está
/// abstraído e pronto para receber a impl web sem retrabalho.
class WebImageSource implements ImageSource {
  @override
  Future<Uint8List?> obtainReceiptImage({
    ImageOrigin origin = ImageOrigin.camera,
  }) async => throw UnimplementedError('Web image source vem na Sprint 8');
}
