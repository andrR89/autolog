import 'dart:typed_data';

import 'package:autolog/features/scan/image_preprocessor.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/scan/scanned_receipt.dart';
import 'package:autolog/platform/image_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Estados do fluxo de scan
// ---------------------------------------------------------------------------

sealed class ScanState {
  const ScanState();
}

class ScanIdle extends ScanState {
  const ScanIdle();
}

class ScanInProgress extends ScanState {
  const ScanInProgress();
}

class ScanSuccess extends ScanState {
  const ScanSuccess(this.receipt);
  final ScannedReceipt receipt;
}

class ScanError extends ScanState {
  const ScanError(this.message);
  final String message;
}

class ScanQuotaExhausted extends ScanState {
  const ScanQuotaExhausted();
}

// ---------------------------------------------------------------------------
// Controlador
// ---------------------------------------------------------------------------

/// Orquestra o fluxo de scan: captura → validação de tamanho → extração por IA.
///
/// NUNCA propaga exceções ao caller — todo erro vira [ScanError].
class ScanController extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanIdle();

  /// Executa o fluxo completo:
  ///   1. Captura via [ImageSource] usando [origin] (câmera por padrão).
  ///   2. Valida tamanho via [ImagePreprocessor].
  ///   3. Extrai dados via [ScanService].
  ///
  /// Retorna o [ScannedReceipt] em sucesso, `null` em cancelamento ou erro.
  /// Em erro, publica [ScanError] com mensagem PT-BR amigável.
  /// NUNCA lança — o caller observa o state ou o retorno.
  Future<ScannedReceipt?> scan({
    ImageOrigin origin = ImageOrigin.camera,
  }) async {
    try {
      state = const ScanInProgress();

      final imageSource = ref.read(imageSourceProvider);
      final preprocessor = ref.read(imagePreprocessorProvider);
      final scanService = ref.read(scanServiceProvider);

      final bytes = await imageSource.obtainReceiptImage(origin: origin);

      if (bytes == null) {
        state = const ScanIdle();
        return null;
      }

      final Uint8List prepared;
      try {
        prepared = preprocessor.prepareForUpload(bytes);
      } on ImageTooLargeException {
        state = const ScanError(
          'A imagem ficou grande demais. Tente novamente com menos zoom.',
        );
        return null;
      }

      final ScannedReceipt receipt;
      try {
        receipt = await scanService.scan(prepared);
      } on QuotaExhaustedException {
        state = const ScanQuotaExhausted();
        return null;
      } on ScanException catch (_) {
        state = const ScanError(
          'Não foi possível ler o cupom. Tente de novo ou preencha manualmente.',
        );
        return null;
      }

      state = ScanSuccess(receipt);
      return receipt;
    } catch (_) {
      state = const ScanError(
        'Não foi possível ler o cupom. Tente de novo ou preencha manualmente.',
      );
      return null;
    }
  }
}

/// Provider do [ScanController].
final scanControllerProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);
