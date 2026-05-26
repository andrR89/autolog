import 'package:autolog/platform/image_source.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' as picker;

/// Implementação mobile de [ImageSource] usando `image_picker`.
///
/// - Cancelamento (usuário fecha o picker) → devolve `null`.
/// - Erro real (permissão negada, hardware indisponível) → lança [ImageSourceException].
///
/// Nota sobre colisão de nomes: `image_picker` também exporta um enum chamado
/// `ImageSource`. Importamos o pacote com o prefixo `picker` para evitar
/// conflito com a nossa classe `ImageSource`.
class MobileImageSource implements ImageSource {
  const MobileImageSource({this.maxWidth = 1280, this.imageQuality = 80});
  final double maxWidth;
  final int imageQuality;

  @override
  Future<Uint8List?> obtainReceiptImage({
    ImageOrigin origin = ImageOrigin.camera,
  }) async {
    final pickerSource = origin == ImageOrigin.camera
        ? picker.ImageSource.camera
        : picker.ImageSource.gallery;

    try {
      final xfile = await picker.ImagePicker().pickImage(
        source: pickerSource,
        maxWidth: maxWidth,
        imageQuality: imageQuality,
      );

      if (xfile == null) {
        // Usuário cancelou — não é um erro.
        return null;
      }

      return await xfile.readAsBytes();
    } on PlatformException catch (e) {
      throw ImageSourceException('Não foi possível obter a imagem', cause: e);
    }
  }
}
