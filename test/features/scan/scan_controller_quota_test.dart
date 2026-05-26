import 'dart:typed_data';

import 'package:autolog/features/scan/image_preprocessor.dart';
import 'package:autolog/features/scan/scan_controller.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/scan/scanned_receipt.dart';
import 'package:autolog/platform/image_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 3.5 — Controller mapeia QuotaExhaustedException pra state dedicado.
/// Spec: docs/specs/sprint-3.5-quota-exhausted.md

class _QuotaThrowingScanService implements ScanService {
  @override
  Future<ScannedReceipt> scan(Uint8List imageBytes) async {
    throw QuotaExhaustedException();
  }
}

class _GenericThrowingScanService implements ScanService {
  @override
  Future<ScannedReceipt> scan(Uint8List imageBytes) async {
    throw ScanException('erro genérico');
  }
}

void main() {
  late FakeImageSource imageSource;
  late ImagePreprocessor preprocessor;

  setUp(() {
    imageSource = FakeImageSource(
      bytes: Uint8List.fromList(List.filled(100, 0x01)),
    );
    preprocessor = const ImagePreprocessor(maxBytes: 10000);
  });

  test(
    'QuotaExhaustedException → state vira ScanQuotaExhausted (não ScanError)',
    () async {
      final container = ProviderContainer(
        overrides: [
          imageSourceProvider.overrideWithValue(imageSource),
          imagePreprocessorProvider.overrideWithValue(preprocessor),
          scanServiceProvider.overrideWithValue(_QuotaThrowingScanService()),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(scanControllerProvider.notifier)
          .scan();

      expect(result, isNull);
      final state = container.read(scanControllerProvider);
      expect(state, isA<ScanQuotaExhausted>());
      expect(state, isNot(isA<ScanError>()));
    },
  );

  test(
    'ScanException genérico → state continua sendo ScanError (regressão)',
    () async {
      final container = ProviderContainer(
        overrides: [
          imageSourceProvider.overrideWithValue(imageSource),
          imagePreprocessorProvider.overrideWithValue(preprocessor),
          scanServiceProvider.overrideWithValue(_GenericThrowingScanService()),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(scanControllerProvider.notifier)
          .scan();

      expect(result, isNull);
      final state = container.read(scanControllerProvider);
      expect(state, isA<ScanError>());
      expect(state, isNot(isA<ScanQuotaExhausted>()));
    },
  );
}
